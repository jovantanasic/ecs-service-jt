#-------------------------------------------#
# Logs
#-------------------------------------------#
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
}

#-------------------------------------------#
# IAM roles
#-------------------------------------------#
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#-------------------------------------------#

data "aws_iam_policy_document" "read_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.secret_arn]
  }
}

resource "aws_iam_role_policy" "execution_read_secret" {
  name   = "${var.name}-read-secret"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secret.json
}

#-------------------------------------------#

resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

#-------------------------------------------#
# Task definition
# busybox sidecar nc-probes Redis as the reachability proof;
# non-essential so it never takes the task down.
#-------------------------------------------#
resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "REDIS_HOST", value = var.redis_endpoint },
        { name = "REDIS_PORT", value = tostring(var.redis_port) },
      ]
      secrets = [
        { name = var.secret_env_name, valueFrom = var.secret_arn },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    },
    {
      name      = "redis-connectivity-check"
      image     = "busybox:1.36"
      essential = false
      environment = [
        { name = "REDIS_HOST", value = var.redis_endpoint },
        { name = "REDIS_PORT", value = tostring(var.redis_port) },
      ]
      command = [
        "sh", "-c",
        "echo probing $REDIS_HOST:$REDIS_PORT; nc -w 3 $REDIS_HOST $REDIS_PORT </dev/null; echo exit=$?; sleep 3600",
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "redis-check"
        }
      }
    },
  ])
}

#-------------------------------------------#
# Cluster + service
#-------------------------------------------#
resource "aws_ecs_cluster" "main" {
  name = var.name
  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  depends_on = [aws_lb_listener.http]
}

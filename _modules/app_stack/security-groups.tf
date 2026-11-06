#-------------------------------------------#
# Security groups
# Chain: internet --> alb (80) --> tasks (app port). Redis lives in another VPC; its SG is referenced, not created.
#-------------------------------------------#
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB ingress from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_security_group" "tasks" {
  name        = "${var.name}-tasks-sg"
  description = "ECS tasks: ingress from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from the ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress stays open: Fargate needs it for ECR, CloudWatch and
  # Secrets Manager over NAT. This also covers reaching Redis.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-tasks-sg"
  }
}

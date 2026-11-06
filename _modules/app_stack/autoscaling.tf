#-------------------------------------------#
# Each policy is a separate target-tracking signal, toggled per env.
#-------------------------------------------#
resource "aws_appautoscaling_target" "app" {
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_cpu_scaling ? 1 : 0
  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count              = var.enable_memory_scaling ? 1 : 0
  name               = "${var.name}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.memory_target
  }
}

#-------------------------------------------#
# Requests-based scaling splits by env: dev stays on target tracking
# (AWS owns the alarms); prod uses step scaling so scale-out fires on a
# 1-minute alarm and scale-in only after 15 minutes.
#-------------------------------------------#
resource "aws_appautoscaling_policy" "requests" {
  count              = var.enable_request_count_scaling && var.environment != "prod" ? 1 : 0
  name               = "${var.name}-requests"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.app.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value = var.request_count_target
  }
}

resource "aws_appautoscaling_policy" "requests_out" {
  count              = var.enable_request_count_scaling && var.environment == "prod" ? 1 : 0
  name               = "${var.name}-requests-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 150
      scaling_adjustment          = 1
    }
    step_adjustment {
      metric_interval_lower_bound = 150
      scaling_adjustment          = 2
    }
  }
}

resource "aws_appautoscaling_policy" "requests_in" {
  count              = var.enable_request_count_scaling && var.environment == "prod" ? 1 : 0
  name               = "${var.name}-requests-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.app.resource_id
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  service_namespace  = aws_appautoscaling_target.app.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 600
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "requests_high" {
  count               = var.enable_request_count_scaling && var.environment == "prod" ? 1 : 0
  alarm_name          = "${var.name}-requests-high"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RequestCountPerTarget"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.request_count_target
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
  alarm_actions = [aws_appautoscaling_policy.requests_out[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "requests_low" {
  count               = var.enable_request_count_scaling && var.environment == "prod" ? 1 : 0
  alarm_name          = "${var.name}-requests-low"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RequestCountPerTarget"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 15
  comparison_operator = "LessThanThreshold"
  threshold           = var.request_count_target * 0.5
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
  alarm_actions = [aws_appautoscaling_policy.requests_in[0].arn]
}

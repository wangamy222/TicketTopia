resource "aws_appautoscaling_target" "TicketTopia_ecs_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.TicketTopia_cluster.name}/${aws_ecs_service.TicketTopia_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "TicketTopia_scale_up" {
  name               = "TicketTopia-scale-up-at-15-10"
  service_namespace  = aws_appautoscaling_target.TicketTopia_ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.TicketTopia_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.TicketTopia_ecs_target.scalable_dimension
  schedule           = "cron(40 7 * * ? *)"  # UTC 06:10 (KST 15:10)

  scalable_target_action {
    min_capacity = 6
    max_capacity = 10
  }
}

resource "aws_appautoscaling_scheduled_action" "TicketTopia_scale_down" {
  name               = "TicketTopia-scale-down-at-15-30"
  service_namespace  = aws_appautoscaling_target.TicketTopia_ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.TicketTopia_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.TicketTopia_ecs_target.scalable_dimension
  schedule           = "cron(45 7 * * ? *)"  # UTC 06:30 (KST 15:30)

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}

resource "aws_appautoscaling_policy" "TicketTopia_ecs_policy_cpu" {
  name               = "TicketTopia-cpu-auto-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.TicketTopia_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.TicketTopia_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.TicketTopia_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "TicketTopia_ecs_policy_memory" {
  name               = "TicketTopia-memory-auto-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.TicketTopia_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.TicketTopia_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.TicketTopia_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 70.0
  }
}
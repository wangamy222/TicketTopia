resource "aws_appautoscaling_target" "TicketTopia_ecs_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.TicketTopia_cluster.name}/${aws_ecs_service.TicketTopia_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_appautoscaling_policy" "TicketTopia_scale_up" {
  name               = "TicketTopia_scale_up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.TicketTopia_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.TicketTopia_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.TicketTopia_ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 10
      scaling_adjustment          = 1
    }
    step_adjustment {
      metric_interval_lower_bound = 10
      metric_interval_upper_bound = 20
      scaling_adjustment          = 2
    }
    step_adjustment {
      metric_interval_lower_bound = 20
      scaling_adjustment          = 3
    }
  }
}

# 오토스케일링 정책 (스케일 다운)
resource "aws_appautoscaling_policy" "scale_down" {
  name               = "TicketTopia_scale_down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.TicketTopia_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.TicketTopia_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.TicketTopia_ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 10
      scaling_adjustment          = -2
    }
    step_adjustment {
      metric_interval_lower_bound = 10
      metric_interval_upper_bound = 20
      scaling_adjustment          = -3
    }
    step_adjustment {
      metric_interval_lower_bound = 20
      scaling_adjustment          = -4
    }
  }
}
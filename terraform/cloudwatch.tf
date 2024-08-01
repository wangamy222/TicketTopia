resource "aws_cloudwatch_log_group" "TicketTopia_nginx_logs" {
  name              = "/ecs/TicketTopia-nginx"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "TicketTopia_django_logs" {
  name              = "/ecs/TicketTopia-django-app"
  retention_in_days = 30
}

# CloudWatch 경보 설정
resource "aws_cloudwatch_metric_alarm" "TicketTopia_cpu_high" {
  alarm_name          = "TicketTopia_cpu_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 30
  statistic           = "Average"
  threshold           = 60
  alarm_actions       = [aws_appautoscaling_policy.TicketTopia_scale_up.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.TicketTopia_cluster.name
    ServiceName = aws_ecs_service.TicketTopia_service.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "TicketTopia_cpu_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 30
  statistic           = "Average"
  threshold           = 50
  alarm_actions       = [aws_appautoscaling_policy.TicketTopia_scale_down.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.TicketTopia_cluster.name
    ServiceName = aws_ecs_service.TicketTopia_service.name
  }
}
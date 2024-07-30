resource "aws_cloudwatch_log_group" "TicketTopia_nginx_logs" {
  name              = "/ecs/TicketTopia-nginx"
  retention_in_days = 30

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "TicketTopia_django_logs" {
  name              = "/ecs/TicketTopia-django-app"
  retention_in_days = 30

  lifecycle {
    ignore_changes = [name]
  }
}
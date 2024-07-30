resource "aws_ecs_cluster" "TicketTopia_cluster" {
  name = "TicketTopia-cluster"
}

resource "aws_ecr_repository" "tickettopia_django_app" {
  name = "tickettopia-django-app"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_repository" "tickettopia_nginx" {
  name = "tickettopia-nginx"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecs_task_definition" "TicketTopia_task" {
  family                   = "TicketTopia-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.TicketTopia_ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "${aws_ecr_repository.tickettopia_nginx.repository_url}:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/TicketTopia-nginx"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "nginx"
        }
      }
    },
    {
      name  = "django-app"
      image = "${aws_ecr_repository.tickettopia_django_app.repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      environment = [
        {
          name  = "DJANGO_ALLOWED_HOSTS"
          value = "*"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/TicketTopia-django-app"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "django"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "TicketTopia_service" {
  name                   = "TicketTopia-service"
  cluster                = aws_ecs_cluster.TicketTopia_cluster.id
  task_definition        = aws_ecs_task_definition.TicketTopia_task.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  force_new_deployment   = true

  network_configuration {
    subnets          = [aws_subnet.TicketTopia_public1.id, aws_subnet.TicketTopia_public2.id]
    security_groups  = [aws_security_group.TicketTopia_ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.TicketTopia_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_cloudwatch_log_group.TicketTopia_nginx_logs, aws_cloudwatch_log_group.TicketTopia_django_logs]
}
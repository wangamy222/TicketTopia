# Specify the required provider and its version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "main-vpc"
  }
}

# 퍼블릭 서브넷 생성
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"  # 가용 영역 지정
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet"
  }
}
# 두 번째 퍼블릭 서브넷 생성
resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"  # 다른 가용 영역 사용
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-2"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

# 두 번째 서브넷에 대한 라우팅 테이블 연결
resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ALB 보안 그룹
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
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
}


# 보안 그룹 생성
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-security-group"
  description = "Security group for ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
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
}


# Application Load Balancer
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]

  enable_deletion_protection = false
}

# ALB 리스너
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  depends_on = [aws_lb_target_group.main]
}

# ALB 타겟 그룹
resource "aws_lb_target_group" "main" {
  name        = "main-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}


# IAM 역할 생성
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_autoscaling_policy" {
  name        = "ecs_autoscaling_policy"
  path        = "/"
  description = "IAM policy for ECS Auto Scaling"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:*",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_autoscaling_policy.arn
}

# ECS 실행 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS 클러스터 생성
resource "aws_ecs_cluster" "main" {
  name = "main-cluster"
}

# ECR 리포지토리 생성 (django)
resource "aws_ecr_repository" "django_app" {
  name = "django-app-repo"
}

# ECR 리포지토리 생성 (Nginx)
resource "aws_ecr_repository" "nginx" {
  name = "nginx-repo"
}


# ECS 태스크 정의
resource "aws_ecs_task_definition" "app" {
  family                   = "app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "${aws_ecr_repository.nginx.repository_url}:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/nginx"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "nginx"
        }
      }
    },
    {
      name  = "django-app"
      image = "${aws_ecr_repository.django_app.repository_url}:latest"
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
          awslogs-group         = "/ecs/django-app"
          awslogs-region        = "ap-northeast-2"
          awslogs-stream-prefix = "django"
        }
      }
    }
  ])
}

# ECS 서비스 생성
resource "aws_ecs_service" "app" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  force_new_deployment = true # 이미지가 바뀌었을때 강제로 배포(yes or no)

  network_configuration {
    subnets          = [aws_subnet.public.id, aws_subnet.public2.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = 80
  }

  # 로그 설정 추가
  depends_on = [aws_cloudwatch_log_group.nginx_logs, aws_cloudwatch_log_group.django_logs]
}

# CloudWatch 로그 그룹 생성 (Nginx용)
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/ecs/nginx"
  retention_in_days = 30
}

# CloudWatch 로그 그룹 생성 (Django용)
resource "aws_cloudwatch_log_group" "django_logs" {
  name              = "/ecs/django-app"
  retention_in_days = 30
}


# Auto Scaling 대상 설정
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
# 오토스케일링 정책 (스케일 업)
resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale_up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

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
  name               = "scale_down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

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


# CloudWatch 경보 설정
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 30
  statistic           = "Average"
  threshold           = 60
  alarm_actions       = [aws_appautoscaling_policy.scale_up.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 30
  statistic           = "Average"
  threshold           = 50
  alarm_actions       = [aws_appautoscaling_policy.scale_down.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
}

# 출력 추가
output "alb_dns_name" {
  value = aws_lb.main.dns_name
  description = "The DNS name of the load balancer"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "ecs-app-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.app.name, "ClusterName", aws_ecs_cluster.main.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-northeast-2"
          title   = "ECS Service CPU and Memory Utilization"
        }
      },
      # 필요에 따라 추가 위젯을 구성할 수 있습니다.
    ]
  })
}
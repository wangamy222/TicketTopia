provider "aws" {
  region = "ap-northeast-2"
}

# VPC 데이터 소스
data "aws_vpc" "default" {
  default = true
}

# 지원되는 가용영역
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# 지원되는 가용영역의 서브넷 데이터 소스
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[2]]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/terra-key.pub")
}

# Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# Launch Template (대신 Launch Configuration 사용)
resource "aws_launch_template" "app" {
  name_prefix   = "app-launch-template"
  image_id      = "ami-056a29f2eddc40520"  # 우분투 22.04 ap-northeast-2
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_web.id]
  }

  key_name = aws_key_pair.deployer.key_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx curl stress-ng -y
              # IMDSv2를 사용하여 인스턴스 ID 가져오기
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)
              # 호스트 이름 가져오기
              HOSTNAME=$(hostname)
              # nginx 기본 페이지 수정
              echo "<h1>Instance ID: $INSTANCE_ID</h1><h2>Hostname: $HOSTNAME</h2>" > /var/www/html/index.html
              # nginx 재시작
              systemctl restart nginx
              EOF
  )
}

# ALB
resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }

}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {

  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  target_group_arns    = [aws_lb_target_group.app.arn]
  vpc_zone_identifier  = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }
}



# Auto Scaling Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.app.name
}

resource "aws_autoscaling_policy" "target_tracking_policy" {
  name                   = "target-tracking-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 5.0
  }
}

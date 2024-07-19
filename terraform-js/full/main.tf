provider "aws" {
  region = "ap-northeast-2"
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 서브넷 생성 (첫 번째 AZ)
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet-1"
  }
}

# 서브넷 생성 (두 번째 AZ)
resource "aws_subnet" "secondary" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet-2"
  }
}

# 서브넷 라우트 테이블 생성 및 인터넷 게이트웨이 추가
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# 서브넷에 라우트 테이블 연결
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "secondary" {
  subnet_id      = aws_subnet.secondary.id
  route_table_id = aws_route_table.main.id
}

# 키 페어 생성
resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = file("/root/.ssh/exam.pub")
}

# 보안 그룹 생성
resource "aws_security_group" "allow_ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 모든 IP로부터 SSH 접근을 허용 (보안상 CIDR 블록을 제한하는 것이 좋습니다)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# HTTP/HTTPS 트래픽을 위한 보안 그룹 생성
resource "aws_security_group" "allow_http_https" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_http_https"
  description = "Allow HTTP and HTTPS inbound traffic"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch template 생성
resource "aws_launch_template" "example" {
  name_prefix   = "example-"
  image_id      = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name

  network_interfaces {
    security_groups = [aws_security_group.allow_ssh.id, aws_security_group.allow_http_https.id]
    associate_public_ip_address = true
  }
}

# Auto Scaling group 생성
resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.main.id, aws_subnet.secondary.id]
  target_group_arns    = [aws_lb_target_group.example.arn]

  tag {
    key                 = "Name"
    value               = "example-instance"
    propagate_at_launch = true
  }
}

# Auto Scaling 정책 (수동 조정)
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

# ELB (Application Load Balancer) 생성
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_https.id]
  subnets            = [aws_subnet.main.id, aws_subnet.secondary.id]

  tags = {
    Name = "example-lb"
  }
}

# Target Group 생성
resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

# Listener 생성
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# Route 53 레코드 생성
resource "aws_route53_zone" "main" {
  name = "tickettopit-1.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www"
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

# S3 버킷 생성
resource "aws_s3_bucket" "example_bucket" {
  bucket = "yang4-test-s3"

  tags = {
    Name        = "example-bucket"
    Environment = "Dev"
  }
}

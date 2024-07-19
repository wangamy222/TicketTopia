provider "aws" {
  region = "ap-northeast-2"
}

# VPC 데이터 소스
data "aws_vpc" "default" {
  default = true
}

# 특정 가용영역의 서브넷 데이터 소스
data "aws_subnet" "az_a" {
  availability_zone = "ap-northeast-2a"
  vpc_id            = data.aws_vpc.default.id
}

data "aws_subnet" "az_c" {
  availability_zone = "ap-northeast-2c"
  vpc_id            = data.aws_vpc.default.id
  
  filter {
    name   = "tag:Tier"
    values = ["Private"]
  }
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
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP 주소에서의 접근을 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance
resource "aws_instance" "example" {
  count         = 2
  ami           = "ami-056a29f2eddc40520"  # 우분투 22.04 ap-northeast-2
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.az_c.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  associate_public_ip_address = true
  tags = {
    Name = "example-instance-${count.index}"
  }
}

# S3 bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "0718-bichan-test"
  
  tags = {
    Name        = "My example bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "example_bucket_ownership" {
  bucket = aws_s3_bucket.example_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.example_bucket_ownership]
  bucket = aws_s3_bucket.example_bucket.id
  acl    = "private"
}

# Launch Template
resource "aws_launch_template" "example" {
  name_prefix   = "example-template"
  image_id      = "ami-056a29f2eddc40520"  # 우분투 22.04 ap-northeast-2
  instance_type = "t2.micro"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.allow_web.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "example-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "example" {
  desired_capacity   = 2
  max_size           = 5
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.example.arn]
  vpc_zone_identifier = [data.aws_subnet.az_a.id, data.aws_subnet.az_c.id]
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

# Load Balancer
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = [data.aws_subnet.az_a.id, data.aws_subnet.az_c.id]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# SQS Queue
resource "aws_sqs_queue" "example" {
  name                      = "example-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  
  tags = {
    Environment = "Dev"
  }
}

# SQS Queue Policy
resource "aws_sqs_queue_policy" "example" {
  queue_url = aws_sqs_queue.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "sqspolicy"
    Statement = [
      {
        Sid       = "First"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.example.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sqs_queue.example.arn
          }
        }
      }
    ]
  })
}
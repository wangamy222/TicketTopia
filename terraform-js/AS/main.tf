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

# 서브넷 생성
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet"
  }
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

# Launch template 생성
resource "aws_launch_template" "example" {
  name_prefix   = "example-"
  image_id      = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name

  network_interfaces {
    security_groups = [aws_security_group.allow_ssh.id]
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
  vpc_zone_identifier  = [aws_subnet.main.id]

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

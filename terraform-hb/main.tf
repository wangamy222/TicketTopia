provider "aws" {
  region = "ap-northeast-2"
}


# Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow web inbound traffic"

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

# EC2 instance
resource "aws_instance" "example" {
  count         = 2
  ami           = "ami-056a29f2eddc40520"  # 우분투 22.04 ap-northeast-2
  instance_type = "t2.micro"
  subnet_id     = "subnet-04e1ebc8f083b974b"
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
  vpc_zone_identifier = ["subnet-04e8b486d69d738fb","subnet-04e1ebc8f083b974b"]

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
  subnets            = ["subnet-04e8b486d69d738fb","subnet-04e1ebc8f083b974b"]

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
  vpc_id   = "vpc-0061233d1a215be71"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}
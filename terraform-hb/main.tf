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

# RDS Aurora MySQL Cluster
resource "aws_rds_cluster" "aurora_mysql_cluster" {
  cluster_identifier      = "aurora-mysql-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.11.2"
  availability_zones      = ["ap-northeast-2a", "ap-northeast-2c"]
  database_name           = "mydb"
  master_username         = "admin"
  master_password         = "password"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true

  vpc_security_group_ids = [aws_security_group.allow_mysql.id]
}

# RDS Aurora MySQL Instance
resource "aws_rds_cluster_instance" "aurora_mysql_instance" {
  count               = 2
  identifier          = "aurora-mysql-instance-${count.index}"
  cluster_identifier  = aws_rds_cluster.aurora_mysql_cluster.id
  instance_class      = "db.t3.medium"
  engine              = aws_rds_cluster.aurora_mysql_cluster.engine
  engine_version      = aws_rds_cluster.aurora_mysql_cluster.engine_version
  publicly_accessible = false
}

# Security Group for MySQL
resource "aws_security_group" "allow_mysql" {
  name        = "allow_mysql"
  description = "Allow MySQL inbound traffic"
  vpc_id      = "vpc-0061233d1a215be71"

  ingress {
    description     = "MySQL from VPC"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["172.31.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mysql"
  }
}
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

data "aws_instances" "asg_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.example.name
  }

  depends_on = [aws_autoscaling_group.example]
}

# 인스턴스 ID 출력
output "instance_ids" {
  value = data.aws_instances.asg_instances.ids
}

# 인스턴스 공개 IP 주소 출력
output "instance_public_ips" {
  value = data.aws_instances.asg_instances.public_ips
}

# RDS Aurora 보안 그룹
resource "aws_security_group" "aurora_sg" {
  name        = "aurora-security-group"
  description = "Security group for Aurora RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id] # EC2 인스턴스의 보안 그룹에서 접근 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aurora-sg"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.main.id, aws_subnet.secondary.id]

  tags = {
    Name = "Aurora DB subnet group"
  }
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "tickettopia-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.11.2"
  availability_zones      = ["ap-northeast-2a", "ap-northeast-2c"]
  database_name           = "tickettopia"
  master_username         = "admin"
  master_password         = "1q2w3e4r"
  backup_retention_period = 1
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  skip_final_snapshot     = true

  tags = {
    Name = "tickettopia-aurora-cluster"
  }
}

# RDS Aurora Instance
resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = 1
  identifier         = "tickettopia-instance"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version

  tags = {
    Name = "tickettopia-aurora-instance"
  }
}

# Output for Aurora Cluster Endpoint
output "aurora_cluster_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}

# Output for Aurora Cluster Reader Endpoint
output "aurora_cluster_reader_endpoint" {
  value = aws_rds_cluster.aurora_cluster.reader_endpoint
}

# 기존의 output들은 그대로 두고, 다음 output들을 추가합니다.

output "db_name" {
  value = aws_rds_cluster.aurora_cluster.database_name
}

output "db_user" {
  value = aws_rds_cluster.aurora_cluster.master_username
}

output "db_password" {
  value     = aws_rds_cluster.aurora_cluster.master_password
  sensitive = true
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = [aws_subnet.main.id, aws_subnet.secondary.id]
}

output "security_group_id" {
  value = aws_security_group.allow_http_https.id
}

output "load_balancer_dns" {
  value = aws_lb.example.dns_name
}
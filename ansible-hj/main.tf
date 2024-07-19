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
  subnet_id     = data.aws_subnet.az_a.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  tags = {
    Name = "example-instance-${count.index}"
  }
}

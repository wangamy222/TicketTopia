provider "aws" {
  region = "ap-northeast-2"
}

# 키 페어 생성
resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = file("/root/.ssh/exam.pub")
}

# 보안 그룹 생성
resource "aws_security_group" "allow_ssh" {
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

# EC2 인스턴스 생성
resource "aws_instance" "example" {
  count         = 2
  ami           = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name # 키 페어 설정
  security_groups = [aws_security_group.allow_ssh.name] # 보안 그룹 설정

  tags = {
    Name = "example-instance-${count.index + 1}"
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

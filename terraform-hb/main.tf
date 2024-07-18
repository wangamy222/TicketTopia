provider "aws" {
  region = "ap-northeast-2"
}

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

resource "aws_s3_bucket" "example_bucket" {
  bucket = "0718-bichan-test"  # 고유한 버킷 이름으로 변경하세요
  
  tags = {
    Name        = "My example bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.example_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "example_bucket_versioning" {
  bucket = aws_s3_bucket.example_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
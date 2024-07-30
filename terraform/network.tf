resource "aws_vpc" "TicketTopia_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name = "TicketTopia-vpc"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_subnet" "TicketTopia_public1" {
  vpc_id                  = aws_vpc.TicketTopia_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "TicketTopia-public-subnet-1"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [cidr_block]
  }
}

resource "aws_subnet" "TicketTopia_public2" {
  vpc_id                  = aws_vpc.TicketTopia_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "TicketTopia-public-subnet-2"
  }
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [cidr_block]
  }
}

resource "aws_internet_gateway" "TicketTopia_igw" {
  vpc_id = aws_vpc.TicketTopia_vpc.id

  tags = {
    Name = "TicketTopia-igw"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route_table" "TicketTopia_public_rt" {
  vpc_id = aws_vpc.TicketTopia_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TicketTopia_igw.id
  }

  tags = {
    Name = "TicketTopia-public-rt"
  }
}

resource "aws_route_table_association" "TicketTopia_rta_public1" {
  subnet_id      = aws_subnet.TicketTopia_public1.id
  route_table_id = aws_route_table.TicketTopia_public_rt.id
}

resource "aws_route_table_association" "TicketTopia_rta_public2" {
  subnet_id      = aws_subnet.TicketTopia_public2.id
  route_table_id = aws_route_table.TicketTopia_public_rt.id
}
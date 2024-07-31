resource "aws_security_group" "TicketTopia_alb_sg" {
  name        = "TicketTopia-alb-sg"
  description = "Security group for TicketTopia ALB"
  vpc_id      = aws_vpc.TicketTopia_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "TicketTopia_ecs_sg" {
  name        = "TicketTopia-ecs-sg"
  description = "Security group for TicketTopia ECS"
  vpc_id      = aws_vpc.TicketTopia_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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
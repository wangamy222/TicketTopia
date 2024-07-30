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

  lifecycle {
    prevent_destroy = true
    ignore_changes = [name]
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

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.TicketTopia_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
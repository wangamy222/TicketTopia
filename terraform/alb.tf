resource "aws_lb" "TicketTopia_alb" {
  name               = "TicketTopia-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.TicketTopia_alb_sg.id]
  subnets            = [aws_subnet.TicketTopia_public1.id, aws_subnet.TicketTopia_public2.id]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "TicketTopia_listener" {
  load_balancer_arn = aws_lb.TicketTopia_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TicketTopia_tg.arn
  }
}

resource "aws_lb_target_group" "TicketTopia_tg" {
  name        = "TicketTopia-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.TicketTopia_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    matcher             = "200"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [name]
  }
}
output "TicketTopia_alb_dns_name" {
  value       = aws_lb.TicketTopia_alb.dns_name
  description = "The DNS name of the TicketTopia load balancer"
}


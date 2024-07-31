resource "aws_iam_role" "TicketTopia_ecs_execution_role" {
  name = "TicketTopia_ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "TicketTopia_ecs_autoscaling_policy" {
  name        = "TicketTopia_ecs_autoscaling_policy"
  path        = "/"
  description = "IAM policy for ECS Auto Scaling"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:*",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling_policy_attachment" {
  role       = aws_iam_role.TicketTopia_ecs_execution_role.name
  policy_arn = aws_iam_policy.TicketTopia_ecs_autoscaling_policy.arn
}

resource "aws_iam_role_policy_attachment" "TicketTopia_ecs_execution_role_policy" {
  role       = aws_iam_role.TicketTopia_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

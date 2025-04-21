output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}
# modules/alb/outputs.tf
output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.alb.arn
}


output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = aws_lb.alb.name
}
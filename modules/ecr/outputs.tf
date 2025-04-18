output "primary_repository_url" {
  description = "URL of the primary ECR repository"
  value       = aws_ecr_repository.lamp_app.repository_url
}
output "secondary_repository_url" {
  description = "URL of the replicated ECR repository in the secondary region"
  value       = "${var.account_id}.dkr.ecr.${var.secondary_region}.amazonaws.com/${var.repository_name}"
}



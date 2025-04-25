output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = module.s3.primary_bucket_name
}

output "secondary_bucket_name" {
  description = "Name of the secondary S3 bucket"
  value       = module.s3.secondary_bucket_name
}

output "global_accelerator_ips" {
  value = module.global_accelerator.global_accelerator_ips
}


output "primary_target_group_arn" {
  description = "ARN of the primary target group"
  value       = module.alb.target_group_arn
}

output "secondary_target_group_arn" {
  description = "ARN of the secondary target group"
  value       = module.alb_secondary.target_group_arn
  
}

output "primary_asg_name" {
  description = "Name of the primary ASG"
  value       = var.primary_asg_name
  
}

output "primary_region" {
  description = "Primary region"
  value       = var.primary_region
  
}
output "secondary_region" {
  description = "Secondary region"
  value       = var.secondary_region
}  


output "global_accelerator_dns_name" {
  value = module.global_accelerator.global_accelerator_dns_name
}
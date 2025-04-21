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


# output "s3_replication_role_arn" {
#   description = "ARN of the IAM role for S3 replication"
#   value       = module.iam.s3_replication_role_arn
# }

# output "laravel_app_role_arn" {
#   description = "ARN of the IAM role for Laravel application"
#   value       = module.iam.laravel_app_role_arn
# }




// root outputs.tf

# output "AWS_BUCKET" {
#   description = "Name of the S3 bucket"
#   value       = module.s3.primary_bucket_name
# }

# output "AWS_URL" {
#   description = "S3 URL to use (s3://…)"
#   value       = module.s3.primary_bucket_url
# }

# output "AWS_ENDPOINT" {
#   description = "HTTP endpoint for the bucket"
#   value       = module.s3.primary_bucket_endpoint
# }

# output "AWS_SECONDARY_BUCKET" {
#   description = "Secondary bucket name"
#   value       = module.s3.secondary_bucket_name
# }

# output "AWS_SECONDARY_ENDPOINT" {
#   description = "Secondary bucket HTTP endpoint"
#   value       = module.s3.secondary_bucket_endpoint
# }

# output "AWS_SECONDARY_URL" {
#   description = "Secondary bucket HTTP URL"
#   value       = module.s3.secondary_bucket_url
# }

# #####


# output "alb_dns_name" {
#   description = "DNS name of the ALB"
#   value       = module.alb.alb_dns_name
# }

# output "ec2_private_ip" {
#   description = "Private IP of the EC2 instance"
#   value       = module.ec2.ec2_private_ip
# }

# output "db_endpoint" {
#   description = "RDS endpoint"
#   value       = module.rds.db_endpoint
# }
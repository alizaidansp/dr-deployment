# S3 OUTPUTS
output "s3_replication_role_arn" {
  description = "ARN of the IAM role for S3 replication"
  value       = aws_iam_role.s3_replication.arn
}


# EC2 OUTPUTS
output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_instance_profile.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_role.arn
}


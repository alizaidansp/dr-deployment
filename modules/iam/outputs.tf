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


output "cross_region_eventbridge_role_arn" {
  description = "ARN of the IAM role for EventBridge cross-region event forwarding"
  value       = aws_iam_role.eventbridge_cross_region.arn
}
 

output "failover_lambda_role_arn" {
  description = "ARN of the IAM role for the failover Lambda function"
  value       = aws_iam_role.failover_lambda_role.arn
}

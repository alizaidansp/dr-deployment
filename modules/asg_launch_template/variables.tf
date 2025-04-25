variable "image_id" {
  description = "AMI ID to use for the instances"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}



variable "iam_instance_profile" {
  description = "IAM instance profile name for EC2 instances"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "db_host" {
  description = "RDS database host endpoint"
  type        = string
}


variable "db_username" {
  description = "Database username"
  type        = string
  
}
variable "db_name" {
  description = "Database username"
  type        = string
  
}

variable "region" {
  description = "AWS region for resource ARNs"
  type        = string
}
variable "aws_bucket" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "aws_url" {
  description = "URL of the S3 bucket"
  type        = string
}

variable "aws_endpoint" {
  description = "Endpoint of the S3 bucket"
  type        = string
}

variable "ecr_repo_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
variable "desired_capacity" {
  type = number
}



variable "primary_asg_name" {
  type = string
}

variable "secondary_asg_name" {
  type = string
}

variable "min_size" {
  type = number
  
}

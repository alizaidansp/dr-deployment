# S3 VARIABLES
variable "replication_role_name" {
  description = "Name of the IAM role for S3 replication"
  type        = string
  default     = "s3-replication-role"
}

variable "laravel_role_name" {
  description = "Name of the IAM role for Laravel application"
  type        = string
  default     = "laravel-app-role"
}

variable "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  type        = string
}

variable "secondary_bucket_arn" {
  description = "ARN of the secondary S3 bucket"
  type        = string
}

variable "primary_bucket_id" {
  description = "ID of the primary S3 bucket"
  type        = string
}

variable "secondary_bucket_id" {
  description = "ID of the secondary S3 bucket"
  type        = string
}

# EC2 VARIABLES
variable "role_name" {
  description = "Name prefix for the IAM role and instance profile"
  type        = string
  default     = "lamp-ec2"
}

variable "region" {
  description = "AWS region for resource ARNs"
  type        = string
 
}
variable "db_password_ssm_param" {
  description = "SSM parameter path where DB password is stored"
  type        = string
}

variable "secondary_region" {
  description = "Secondary AWS region for resources"
  type        = string
  
}

variable "account_id" {
   description = "AWS account ID"
    type        = string  
}
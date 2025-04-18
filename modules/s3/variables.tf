variable "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  type        = string
}

variable "secondary_bucket_name" {
  description = "Name of the secondary S3 bucket"
  type        = string
}

variable "replication_role_arn" {
  description = "ARN of the IAM role for S3 replication"
  type        = string
}
variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "ali-amalitech-state-bucket"
}

variable "state_bucket_region" {
  description = "AWS region for the Terraform state bucket"
  type        = string
  default     = "eu-west-1"
}


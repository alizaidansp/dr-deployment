variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "lamp-app"
}

variable "secondary_region" {
  description = "AWS region for the secondary resources (replication destination)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
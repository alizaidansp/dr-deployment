variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "waf-lamp-repo"
}

variable "secondary_region" {
  description = "AWS region for the secondary resources (replication destination)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
variable "primary_region" {
  type        = string
  description = "AWS region for the primary resources (replication source)"
  
}

variable "dockerfile_path" {
  type        = string
  description = "Path to the Dockerfile"
  
}
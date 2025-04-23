variable "primary_region" {
  type = string
}


variable "primary_security_group_id" {
  type = string
  description = "Security group ID for the primary region"
}

variable "primary_subnet_id" {
  type = string
  description = "Subnet ID for the primary region"
}

variable "iam_instance_profile" {
  type = string
}

variable "ami_name" {
  type        = string
  description = "Name for the AMI"
  default     = "lamp-app-ami"
}
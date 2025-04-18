variable "vpc_id" {
  description = "VPC ID for the ALB"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "target_group_port" {
  description = "Port for the ALB target group"
  type        = number
}

variable "health_check_path" {
  description = "Path for HealthCheck"
  type        = string

}
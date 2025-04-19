variable "primary_region" {
  type        = string
  description = "Primary AWS region"
}

variable "primary_alb_arn" {
  type        = string
  description = "ARN of the primary Application Load Balancer"
}

variable "primary_target_group_arn" {
  type        = string
  description = "ARN of the primary ALB Target Group"
}

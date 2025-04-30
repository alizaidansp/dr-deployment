variable "primary_region" {
  type        = string
  description = "Primary AWS region"
}



variable "primary_target_group_arn_suffix" {
  type        = string
  description = "ARN suffix of the primary ALB Target Group"
}


variable "primary_alb_arn_suffix" {
  type        = string
  description = "ARN suffix of the Primary Application Load Balancer"
  
}
variable "secondary_region" {
  type        = string
  description = "Secondary AWS region"
}
variable "account_id" {
  type        = string
  description = "AWS Account ID"
  
}



variable "failover_lambda_arn" {
 
  type        = string
  description = "ARN of the Lambda function in the secondary region"
}
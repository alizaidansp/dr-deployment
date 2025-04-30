variable "secondary_region" {
  type        = string
  description = "Secondary AWS region for failover"
}



variable "lambda_role_arn" {
  type        = string
  description = "ARN of the IAM role for the Lambda function"
}

variable "lambda_environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for failover notifications"
}
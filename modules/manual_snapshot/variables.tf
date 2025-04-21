variable "rds_instance_identifier" {
  type        = string
  description = "Identifier of the RDS instance to snapshot"
}

variable "region" {
  type        = string
  description = "AWS region where the RDS instance is located"
}

variable "schedule_expression" {
  type        = string
  description = "Cron or rate expression for scheduling snapshot creation (e.g., 'cron(5 15 * * ? *)' for 15:05 UTC)"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN of the IAM role for the Lambda function"
}
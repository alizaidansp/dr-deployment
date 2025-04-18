variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "failover-function"
}

variable "runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.8"
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "switch_to_secondary.lambda_handler"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
}
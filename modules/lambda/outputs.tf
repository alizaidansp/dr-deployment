output "lambda_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.failover.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.failover.function_name
}
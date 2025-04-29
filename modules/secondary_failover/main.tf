terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Zip the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "failover" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "failover-handler"
  role          = var.lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = var.lambda_environment_variables
  }
}


# EventBridge Rule to Schedule Lambda Every Minute
resource "aws_cloudwatch_event_rule" "health_check_schedule" {
  name                = "health_check_schedule"
  description         = "Run health check every minute"
  # schedule_expression = "rate(1 minute)" #system can be down for 10 minutes
  schedule_expression = "rate(5 hours)" #system can be down for 10 minutes
# 
}

resource "aws_cloudwatch_event_target" "failover_lambda" {
  rule      = aws_cloudwatch_event_rule.health_check_schedule.name
  target_id = "failover_lambda"
  arn       = aws_lambda_function.failover.arn
}

# Permission for EventBridge to Invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check_schedule.arn
}

# Outputs
output "failover_lambda_name" {
  value = aws_lambda_function.failover.function_name
}
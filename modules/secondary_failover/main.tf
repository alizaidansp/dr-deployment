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

# EventBridge Rule to listen for SNS notifications
resource "aws_cloudwatch_event_rule" "failover_trigger" {
  name        = "failover-trigger"
  description = "Trigger failover Lambda on SNS Publish events"
  event_pattern = jsonencode({
    "source"      = ["aws.sns"]
    "detail-type" = ["SNS Topic Notification"]
    "resources"   = [var.sns_topic_arn]
  })
}

# EventBridge Target to invoke Lambda
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.failover_trigger.name
  target_id = "failoverLambda"
  arn       = aws_lambda_function.failover.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.failover_trigger.arn
}
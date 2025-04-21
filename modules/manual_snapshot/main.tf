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

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "rds-snapshot-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}



# Lambda Function
resource "aws_lambda_function" "snapshot_lambda" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "rds-snapshot-creator"
  role          = var.lambda_role_arn

  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      REGION                = var.region
      RDS_INSTANCE_IDENTIFIER = var.rds_instance_identifier
    }
  }
}

# EventBridge Rule to Schedule Lambda
resource "aws_cloudwatch_event_rule" "snapshot_schedule" {
  name                = "rds-snapshot-schedule"
  description         = "Schedule for RDS snapshot creation"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "snapshot_lambda" {
  rule      = aws_cloudwatch_event_rule.snapshot_schedule.name
  target_id = "snapshot_lambda"
  arn       = aws_lambda_function.snapshot_lambda.arn
}

# Permission for EventBridge to Invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snapshot_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.snapshot_schedule.arn
}

# Outputs
output "lambda_function_name" {
  value = aws_lambda_function.snapshot_lambda.function_name
}

output "event_rule_name" {
  value = aws_cloudwatch_event_rule.snapshot_schedule.name
}
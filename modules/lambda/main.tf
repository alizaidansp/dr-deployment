resource "aws_lambda_function" "failover" {
  provider      = aws.secondary
  function_name = var.function_name
  runtime       = var.runtime
  role          = var.lambda_role_arn
  handler       = var.handler
  filename      = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
}
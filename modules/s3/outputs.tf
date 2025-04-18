data "aws_region" "primary_region" {}

// grab the region for the secondary provider
data "aws_region" "secondary_region" {
  provider = aws.secondary
}

output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.bucket
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "primary_bucket_id" {
  description = "ID of the primary S3 bucket"
  value       = aws_s3_bucket.primary.id
}

output "secondary_bucket_name" {
  description = "Name of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary.bucket
}

output "secondary_bucket_arn" {
  description = "ARN of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary.arn
}

output "secondary_bucket_id" {
  description = "ID of the secondary S3 bucket"
  value       = aws_s3_bucket.secondary.id
}

output "primary_public_access" {
  description = "Primary bucket public access block"
  value       = aws_s3_bucket_public_access_block.primary_public_access
}

output "secondary_public_access" {
  description = "Secondary bucket public access block"
  value       = aws_s3_bucket_public_access_block.secondary_public_access
}

output "primary_bucket_url" {
  description = "S3 URL for the primary bucket"
  # value       = "s3://${aws_s3_bucket.primary.bucket}"
    value       = "https://s3.${data.aws_region.primary_region.name}.amazonaws.com/${aws_s3_bucket.primary.bucket}"
}

// new: the region‑specific HTTP endpoint
output "primary_bucket_endpoint" {
  description = "Regional endpoint for the primary bucket"
  # value       = aws_s3_bucket.primary.bucket_regional_domain_name
  value       = "https://s3.${data.aws_region.primary_region.name}.amazonaws.com"
}

output "secondary_bucket_url" {
  description = "S3 URL for the secondary bucket"
  # value       = "s3://${aws_s3_bucket.secondary.bucket}"
    value       = "https://s3.${data.aws_region.secondary_region.name}.amazonaws.com/${aws_s3_bucket.secondary.bucket}"

}

// new: the region‑specific HTTP endpoint
output "secondary_bucket_endpoint" {
  description = "Regional endpoint for the secondary bucket"
  # value       = aws_s3_bucket.secondary.bucket_regional_domain_name
    value       = "https://s3.${data.aws_region.secondary_region.name}.amazonaws.com"
}
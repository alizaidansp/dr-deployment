# aws s3api get-public-access-block --bucket my-laravel-secondary-bucket-2025  --region us-west-2
# aws s3 rm s3://my-laravel-secondary-bucket-202fdfd5 --recursive --region us-west-2  

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws, aws.secondary]
    }
  }
}
# Primary S3 Bucket Configuration
resource "aws_s3_bucket" "primary" {
  provider = aws
  bucket = var.primary_bucket_name

  tags = {
    Name        = "PrimaryS3Bucket"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
    Region      = var.primary_region
  }
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "primary_lifecycle" {
  bucket = aws_s3_bucket.primary.id
  rule {
    id     = "archive-and-delete"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "primary_public_access" {
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true  # Changed from false
  block_public_policy     = true  # Changed from false
  ignore_public_acls      = true  # Changed from false
  restrict_public_buckets = true  # Changed from false
}

# Secondary S3 Bucket Configuration
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = var.secondary_bucket_name

  tags = {
    Name        = "SecondaryS3Bucket"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
    Region      = var.secondary_region
  }
}

resource "aws_s3_bucket_versioning" "secondary_versioning" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "secondary_lifecycle" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  rule {
    id     = "archive-and-delete"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secondary_public_access" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.secondary.id
   block_public_acls       = true  # Changed from false
  block_public_policy     = true  # Changed from false
  ignore_public_acls      = true  # Changed from false
  restrict_public_buckets = true  # Changed from false
}




resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.primary.id
  role   = var.replication_role_arn  # Must be exact ARN from module.iam.s3_replication_role_arn

  rule {
    id     = "full-crr-rule"
    status = "Enabled"
    
    filter {}  # Replicate all objects
    
    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary_versioning,
    aws_s3_bucket_versioning.secondary_versioning
  ]
}
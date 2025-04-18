#!/bin/bash

set -e

BUCKET_NAME="ali-amalitech-state-bucket"
REGION="eu-west-1"

# Check if bucket exists
echo "Checking if bucket '$BUCKET_NAME' exists..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ Bucket '$BUCKET_NAME' already exists."
else
    echo "❌ Bucket does not exist. Creating bucket..."

    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"

    echo "✅ Bucket created."

    echo "🔄 Enabling versioning..."
    aws s3api put-bucket-versioning \
      --bucket "$BUCKET_NAME" \
      --versioning-configuration Status=Enabled

    echo "🔐 Applying server-side encryption..."
    aws s3api put-bucket-encryption \
      --bucket "$BUCKET_NAME" \
      --server-side-encryption-configuration '{
        "Rules": [{
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }]
      }'

    echo "✅ S3 bucket '$BUCKET_NAME' is now ready for Terraform remote state."
fi

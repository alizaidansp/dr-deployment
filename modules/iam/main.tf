
# modules/iam/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws, aws.secondary]
    }
  }
}
data "aws_caller_identity" "current" {}

# S3 Replication Role (Separate service role)
resource "aws_iam_role" "s3_replication" {
  provider = aws
  name = var.replication_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name        = "S3ReplicationRole"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
  }
}

# Consolidated EC2 Role with S3 Access
resource "aws_iam_role" "ec2_role" {
  name = "${var.role_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = {
    Name        = "EC2-Laravel-Role"
    Environment = "DisasterRecovery"
  }
}

# Combined Policy Attachment
# Attach static (predefined) IAM policies
resource "aws_iam_role_policy_attachment" "ec2_static_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  role       = aws_iam_role.ec2_role.name
  policy_arn = each.value
}

# Attach custom (dynamic) IAM policies
resource "aws_iam_role_policy_attachment" "ec2_custom_policies" {
  for_each = {
    "s3_access"            = aws_iam_policy.s3_access.arn
    "ecr_custom"           = aws_iam_policy.ecr_custom.arn
    "ssm_db_password_access" = aws_iam_policy.ssm_db_password_access.arn
  }

  role       = aws_iam_role.ec2_role.name
  policy_arn = each.value
}

# Custom S3 Access Policy
resource "aws_iam_policy" "s3_access" {
  name        = "${var.role_name}-s3-access"
  description = "Combined S3 access policy for Laravel app"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:PutObjectAcl"
        ]
        Effect   = "Allow"
        Resource = [
          var.primary_bucket_arn,
          "${var.primary_bucket_arn}/*",
          var.secondary_bucket_arn,
          "${var.secondary_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Custom ECR Policy
resource "aws_iam_policy" "ecr_custom" {
  name        = "${var.role_name}-ecr-access"
  description = "Custom ECR access policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = [
          "arn:aws:ecr:${var.region}:${var.account_id}:repository/lamp-app",
          "arn:aws:ecr:${var.secondary_region}:${var.account_id}:repository/lamp-app-secondary"
        ]
      }
    ]
  })
}
resource "aws_iam_policy" "ssm_db_password_access" {
  name        = "${var.role_name}-ssm-db-access"
  description = "Allow EC2 to read DB password from SSM Parameter Store"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameter"
        ],
        Resource =[
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_password_ssm_param}",
        "arn:aws:ssm:${var.secondary_region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_password_ssm_param}"
        
        ]

          
      }
    ]
  })
}

# Single Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# S3 Replication Policy (Remains Separate)
resource "aws_iam_role_policy" "s3_replication_policy" {
  role = aws_iam_role.s3_replication.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionAcl"
        ]
        Effect   = "Allow"
        Resource = ["${var.primary_bucket_arn}", "${var.primary_bucket_arn}/*"]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Effect   = "Allow"
        Resource = ["${var.secondary_bucket_arn}/*"]
      },
      {
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Effect   = "Allow"
        Resource = [var.primary_bucket_arn, var.secondary_bucket_arn]
      }
    ]
  })
}


resource "aws_iam_role" "failover_lambda_role" {
  provider = aws.secondary
  name     = "failover-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "failover_lambda_policy" {
  provider = aws.secondary
  role     = aws_iam_role.failover_lambda_role.id
  policy   = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [ "rds:ModifyDBInstance","rds:PromoteReadReplica", "rds:DescribeDBInstances"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["autoscaling:UpdateAutoScalingGroup", "autoscaling:DescribeAutoScalingGroups",  "autoscaling:SetDesiredCapacity",]
        Effect   = "Allow"
        Resource = "*"
      },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  
    ]
  })
}



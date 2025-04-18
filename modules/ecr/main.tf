# Create the ECR repository in the primary region
resource "aws_ecr_repository" "lamp_app" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name        = "lamp-app"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
  }
}

# Configure replication to the secondary region
resource "aws_ecr_replication_configuration" "replication" {
  replication_configuration {
    rule {
      destination {
        region      = var.secondary_region
        registry_id = var.account_id
      }
      repository_filter {
        filter      = var.repository_name
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}
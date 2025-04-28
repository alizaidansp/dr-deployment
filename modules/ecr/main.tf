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

# Build and push Docker image
resource "null_resource" "docker_build_push" {
  triggers = {
    # Trigger rebuild if Dockerfile or source code changes
    dockerfile_hash = filemd5("${var.dockerfile_path}/Dockerfile")
    # Add more files or directories to track changes if needed
  }

  provisioner "local-exec" {
    command = <<EOT
      set -e  # Exit on error
      echo "Navigating to ${var.dockerfile_path}"
      cd ${var.dockerfile_path}
      echo "Building Docker image"
       docker build -t lamp-app:latest .
      echo "Authenticating with ECR"
      aws ecr get-login-password --region ${var.primary_region} |  docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.primary_region}.amazonaws.com
      echo "Tagging image"
       docker tag lamp-app:latest ${aws_ecr_repository.lamp_app.repository_url}:latest
      echo "Pushing image"
       docker push ${aws_ecr_repository.lamp_app.repository_url}:latest
    EOT
  }

  depends_on = [aws_ecr_repository.lamp_app]
}


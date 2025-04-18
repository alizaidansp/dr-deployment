terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "ali-amalitech-state-bucket"
    key            = "terraform/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile = true #s3 versioning already enabled for s3 

  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.primary_region
  
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
}



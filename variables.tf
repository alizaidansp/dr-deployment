variable "primary_region" {
  description = "AWS region for the primary resources"
  type        = string
}

variable "secondary_region" {
  description = "AWS region for the secondary resources"
  type        = string
}

variable "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  type        = string
}

variable "secondary_bucket_name" {
  description = "Name of the secondary S3 bucket"
  type        = string
}

variable "replication_role_name" {
  description = "Name of the IAM role for S3 replication"
  type        = string
  default     = "s3-replication-role"
}

variable "laravel_role_name" {
  description = "Name of the IAM role for Laravel application"
  type        = string
  default     = "laravel-app-role"
}


# PRIMARY REGION VPC CONFIGURATION VARIABLES

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# SECONDARY REGION VPC CONFIGURATION VARIABLES

variable "vpc_secondary_cidr" {
  description = "Secondary VPC CIDR block"
  type        = string
}

variable "public_secondary_subnet_cidrs" {
  description = "List of public subnet CIDR blocks for secondary VPC"
  type        = list(string)
}

variable "private_secondary_subnet_cidrs" {
  description = "List of private subnet CIDR blocks for secondary VPC"
  type        = list(string)
}

variable "availability_zones_secondary" {
  description = "List of availability zones for secondary region"
  type        = list(string)
}



# DB CONFIGURATION VARIABLES
variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string

}

variable "db_password_ssm_param" {
  type = string
}

variable "desired_capacity" {
  type = number

}


variable "secondary_desired_capacity" {
  type = number
  
}

# others
variable "account_id" {
   description = "AWS account ID"
    type        = string  
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string

}


variable "health_check_path" {
  description = "Path for HealthCheck"
  type        = string

}

variable "primary_asg_name" {
  type = string
}
variable "secondary_asg_name" {
  type = string
}

variable "replica_db_identifier" {
  type = string
  
}

variable "main_db_identifier" {
  type = string
  
}


variable "expected_status_codes" {
  type    = list(number)
  default = [200]
}
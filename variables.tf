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


# VPC CONFIGURATION VARIABLES(PRIMARY REGION)

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a"]
}

# VPC CONFIGURATION VARIABLES(SECONDARY REGION)

variable "vpc_secondary_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_secondary_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "private_secondary_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.3.0/24"]
}

variable "availability_zones_secondary" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a"]
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

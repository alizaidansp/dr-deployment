# ( : > output.txt && for file in *.tf; do
#   echo "===== $file =====" >> output.txt
#   cat "$file" >> output.txt
#   echo "" >> output.txt
# done )


# AMImodule
module "ami" {
   providers = {
    aws.secondary = aws.secondary
  }
  source                   = "./modules/ami"
  primary_region           = var.primary_region
  primary_security_group_id = module.security_group.ec2_sg_id
  primary_subnet_id        = module.vpc.private_subnet_ids[0]
  iam_instance_profile     = module.iam.instance_profile_name
}


# ECR Configuration

module "ecr" {
  source           = "./modules/ecr"
  repository_name  = var.repository_name
  secondary_region = var.secondary_region  # us-east-1
  account_id       = var.account_id
  primary_region   = var.primary_region
  dockerfile_path  = "${path.module}/../../ask-kstu-backend-v3"  # Correct path to directory
 
}


# Global Accelerator Configuration
module "global_accelerator" {
  source              = "./modules/global_accelerator"
  secondary_region =var.secondary_region
  primary_region = var.primary_region
  health_check_path = var.health_check_path
  primary_alb_arn     = module.alb.alb_arn
  secondary_alb_arn   = module.alb_secondary.alb_arn

}



# # VPC Module
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}


module "vpc_secondary" {
  source              = "./modules/vpc"
  providers = {
    aws = aws.secondary
  }
  vpc_cidr            = var.vpc_secondary_cidr
  public_subnet_cidrs = var.public_secondary_subnet_cidrs
  private_subnet_cidrs = var.private_secondary_subnet_cidrs
  availability_zones  = var.availability_zones_secondary
}

# Security Group Module
module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.vpc.vpc_id
}

module "security_group_secondary" {
  source    = "./modules/security_group"
  providers = {
    aws = aws.secondary
  }
  vpc_id    = module.vpc_secondary.vpc_id
}

# RDS Module (Primary Region)
module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_group.rds_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  multi_az          = false
  db_password_ssm_param = var.db_password_ssm_param
  main_db_identifier = var.main_db_identifier
}


# Replicate the Password to Secondary Region's SSM
resource "aws_ssm_parameter" "db_master_password_secondary" {
  provider    = aws.secondary
  name        = var.db_password_ssm_param
  description = "Master password for Lamp RDS DB (secondary)"
  type        = "SecureString"
  value       = data.aws_ssm_parameter.db_master.value # Use primary password
  tags = {
    Name        = "lamp-rds-password"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
  }
}

data "aws_ssm_parameter" "db_master" {
  name            = module.rds.db_master_ssm_name
  with_decryption = true
  depends_on      = [module.rds] # Ensure RDS module is applied first
}

# RDS Read Replica Subnet Group (Secondary Region)
resource "aws_db_subnet_group" "replica" {
  provider   = aws.secondary
  name       = "lamp-db-subnet-group-replica"
  subnet_ids = module.vpc_secondary.private_subnet_ids
  tags = {
    Name = "lamp-db-subnet-group-replica"
  }
}

# RDS Read Replica (Secondary Region)
resource "aws_db_instance" "replica" {
  provider             = aws.secondary
  identifier           = var.replica_db_identifier
  replicate_source_db  = module.rds.main_db_arn
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.replica.name
  vpc_security_group_ids = [module.security_group_secondary.rds_sg_id]
  skip_final_snapshot  = true
  backup_retention_period = 1 # Enable automated backups (1 day retention)
  tags = {
    Name = "lamp-db-replica"
  }
}



# S3 Module
module "s3" {
   providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
  source = "./modules/s3"
  primary_bucket_name   = var.primary_bucket_name
  secondary_bucket_name = var.secondary_bucket_name
  replication_role_arn  = module.iam.s3_replication_role_arn
}

# # IAM Module
module "iam" {
 
  source    = "./modules/iam"
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
  replication_role_name = var.replication_role_name
  primary_bucket_arn  = module.s3.primary_bucket_arn
  secondary_bucket_arn = module.s3.secondary_bucket_arn
  primary_bucket_id   = module.s3.primary_bucket_id
  secondary_bucket_id   = module.s3.secondary_bucket_id
  laravel_role_name   = var.laravel_role_name
  region = var.primary_region
  db_password_ssm_param = module.rds.db_master_ssm_name
  secondary_region = var.secondary_region
  account_id = var.account_id
}





# # # ALB Module
module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_group.alb_sg_id
  target_group_port = 80
  health_check_path= var.health_check_path
}

# ALB in Secondary Region
module "alb_secondary" {
  source            = "./modules/alb"
  providers = {
    aws = aws.secondary
  }
  vpc_id            = module.vpc_secondary.vpc_id
  subnet_ids        = module.vpc_secondary.public_subnet_ids
  security_group_id = module.security_group_secondary.alb_sg_id
  target_group_port = 80
  health_check_path=var.health_check_path
}
# # # # EC2 Module
module "ec2" {
  image_id             = module.ami.primary_ami_id  # Use primary AMI ID
  source               = "./modules/ec2"
  region = var.primary_region
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_id    = module.security_group.ec2_sg_id
  iam_instance_profile = module.iam.instance_profile_name  # Updated to use IAM module output
  alb_target_group_arn = module.alb.target_group_arn
  db_host              = module.rds.db_endpoint
  db_name           = var.db_name
  db_username         = var.db_username
  aws_bucket   = module.s3.primary_bucket_name
  aws_url      = module.s3.primary_bucket_url
  aws_endpoint = module.s3.primary_bucket_endpoint
  account_id = var.account_id
  ecr_repo_url = module.ecr.primary_repository_url
  primary_asg_name = var.primary_asg_name
  secondary_asg_name = var.secondary_asg_name
  desired_capacity=var.desired_capacity
  min_size = 1
  depends_on           = [module.ecr]

}


# # EC2 Auto Scaling Group
module "ec2_secondary" {
  image_id             = module.ami.secondary_ami_id  # Use secondary AMI ID
  source               = "./modules/ec2"
  providers = {
    aws = aws.secondary
  }
  min_size = 0
  desired_capacity    = var.secondary_desired_capacity

  region              = var.secondary_region
  subnet_ids          = module.vpc_secondary.private_subnet_ids
  security_group_id   = module.security_group_secondary.ec2_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  alb_target_group_arn = module.alb_secondary.target_group_arn
  db_host             = split(":", aws_db_instance.replica.endpoint)[0]
  db_name             = var.db_name
  db_username         = var.db_username
  aws_bucket          = module.s3.secondary_bucket_name
  aws_url             = module.s3.secondary_bucket_url
  aws_endpoint        = module.s3.secondary_bucket_endpoint
  account_id = var.account_id
  ecr_repo_url = module.ecr.secondary_repository_url
  primary_asg_name = var.primary_asg_name
  secondary_asg_name = var.secondary_asg_name
  depends_on           = [module.ecr]
}






# Primary Monitoring Module
module "primary_monitoring" {
  source                  = "./modules/primary_monitoring"
  
  primary_region          = var.primary_region
  primary_alb_arn         = module.alb.alb_arn
  primary_target_group_arn = module.alb.target_group_arn
  alb_arn         = module.alb.alb_arn
  secondary_region         = var.secondary_region
  account_id               = var.account_id

}



# Secondary Failover Module
module "secondary_failover" {
  source = "./modules/secondary_failover"
  providers = {
    aws = aws.secondary
  }
  secondary_region = var.secondary_region
  lambda_role_arn = module.iam.failover_lambda_role_arn
lambda_environment_variables = {
    SECONDARY_ASG_NAME = var.secondary_asg_name
    SECONDARY_RDS_ID   = var.replica_db_identifier
    PRIMARY_RDS_ID     = var.main_db_identifier
    PRIMARY_ALB_DNS_NAME   = module.alb.alb_dns_name
    HEALTH_CHECK_PATH      = var.health_check_path
    EXPECTED_STATUS_CODES  = jsonencode(var.expected_status_codes)
    SECONDARY_REGION             = var.secondary_region
    PRIMARY_REGION         = var.primary_region
  }
}

# Lambda Function for Snapshot Creation
module "manual_snapshot" {
  source = "./modules/manual_snapshot"
  providers = {
    aws = aws.secondary
  }
  region = var.secondary_region
  rds_instance_identifier = var.replica_db_identifier
  schedule_expression = "cron(0 2 * * ? *)" #run every day at 2am
  # schedule_expression = "cron(15 19 * * ? *)" # Was used for testing
  lambda_role_arn = module.iam.failover_lambda_role_arn
}
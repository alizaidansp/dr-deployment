# ( : > output.txt && for file in *.tf; do
#   echo "===== $file =====" >> output.txt
#   cat "$file" >> output.txt
#   echo "" >> output.txt
# done )

# secondary_region.tf

# Global Accelerator COnfiguration
module "global_accelerator" {
  source              = "./modules/global_accelerator"
  secondary_region =var.secondary_region
  primary_region = var.primary_region
  health_check_path = var.health_check_path
  primary_alb_arn     = module.alb.alb_arn
  secondary_alb_arn   = module.alb_secondary.alb_arn

}


# ECR Configuration
module "ecr" {
  source           = "./modules/ecr"
  repository_name  = var.repository_name
  secondary_region = var.secondary_region  # us-east-1
  account_id       = var.account_id
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

# RDS Module
module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_group.rds_sg_id
  db_name           = var.db_name
  db_username       = var.db_username
  multi_az          = false
  db_password_ssm_param = var.db_password_ssm_param
  
}

# RDS Read Replica [subnet-group]

resource "aws_db_subnet_group" "replica" {
  provider   = aws.secondary
  name       = "lamp-db-subnet-group-replica"
  subnet_ids = module.vpc_secondary.private_subnet_ids
  tags = {
    Name = "lamp-db-subnet-group-replica"
  }
}

# RDS Read Replica [instance]
resource "aws_db_instance" "replica" {
  provider             = aws.secondary
  identifier           = "lamp-db-replica"
  replicate_source_db  = module.rds.main_db_arn  # Primary DB ARN from eu-west-1
  instance_class       = "db.t3.micro"
  db_subnet_group_name = aws_db_subnet_group.replica.name
  vpc_security_group_ids = [module.security_group_secondary.rds_sg_id]
  skip_final_snapshot  = true
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
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
  source    = "./modules/iam"
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
# # # EC2 Module
module "ec2" {
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
  desired_capacity=var.desired_capacity
}


# EC2 Auto Scaling Group
module "ec2_secondary" {
  source               = "./modules/ec2"
  providers = {
    aws = aws.secondary
  }
  region              = var.secondary_region
  subnet_ids          = module.vpc_secondary.private_subnet_ids
  security_group_id   = module.security_group_secondary.ec2_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  alb_target_group_arn = module.alb_secondary.target_group_arn
  db_host             = aws_db_instance.replica.endpoint
  db_name             = var.db_name
  db_username         = var.db_username
  aws_bucket          = module.s3.secondary_bucket_name
  aws_url             = module.s3.secondary_bucket_url
  aws_endpoint        = module.s3.secondary_bucket_endpoint
  desired_capacity    = var.secondary_desired_capacity
  account_id = var.account_id
  ecr_repo_url = module.ecr.secondary_repository_url
}



module "lambda" {
  source           = "./modules/lambda"
  providers = {
    aws.secondary = aws.secondary
  }
  function_name    = "failover-function"
  runtime          = "python3.8"
  lambda_role_arn  = module.iam.failover_lambda_role.arn
  handler          = "switch_to_secondary.lambda_handler"
  lambda_zip_path  = "failover_lambda/lambda_function.zip"
}
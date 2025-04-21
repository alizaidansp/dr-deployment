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
}

# Replicate the Password to Secondary Region's SSM
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

# Output for Replica Endpoint
output "replica_endpoint" {
  value = split(":", aws_db_instance.replica.endpoint)[0]
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
  primary_asg_name = var.primary_asg_name
  secondary_asg_name = var.secondary_asg_name
  desired_capacity=var.desired_capacity
  min_size = 1

}


# EC2 Auto Scaling Group
module "ec2_secondary" {
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
  db_host             = aws_db_instance.replica.endpoint
  db_name             = var.db_name
  db_username         = var.db_username
  aws_bucket          = module.s3.secondary_bucket_name
  aws_url             = module.s3.secondary_bucket_url
  aws_endpoint        = module.s3.secondary_bucket_endpoint
  account_id = var.account_id
  ecr_repo_url = module.ecr.secondary_repository_url
  primary_asg_name = var.primary_asg_name
  secondary_asg_name = var.secondary_asg_name
}



# failover implementation #START

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

# Forward SNS events to secondary region
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_event_rule" "forward_sns_to_secondary" {

  name        = "forward-sns-to-secondary"
  description = "Forward SNS Publish events to secondary region"
  event_pattern = jsonencode({
    "source"      = ["aws.sns"],
    "detail-type" = ["SNS Topic Notification"],
    "resources"   = [module.primary_monitoring.sns_topic_arn]
  })
}

resource "aws_cloudwatch_event_target" "secondary_bus" {
  
  rule      = aws_cloudwatch_event_rule.forward_sns_to_secondary.name
  target_id = "secondaryEventBus"
  arn       = "arn:aws:events:${var.secondary_region}:${data.aws_caller_identity.current.account_id}:event-bus/default"
  role_arn       = module.iam.cross_region_eventbridge_role_arn
}

# Secondary Failover Module
module "secondary_failover" {
  source = "./modules/secondary_failover"
  providers = {
    aws = aws.secondary
  }
  secondary_region = var.secondary_region
  sns_topic_arn   = module.primary_monitoring.sns_topic_arn
  lambda_role_arn = module.iam.failover_lambda_role_arn
lambda_environment_variables = {
    SECONDARY_ASG_NAME = var.secondary_asg_name
    SECONDARY_RDS_ID   = var.replica_db_identifier

  }
}
# failover implementation #END

# 1. **Primary Monitoring Module**  
#    - **Alarms & EventBridge**  
#      - Creates an SNS topic (`failover-topic`).  
#      - Raises a CloudWatch Alarm if the primary ALB has 0 healthy hosts.  
#      - Captures any RDS “failure” event via an EventBridge rule.  
#      - Both conditions publish to the SNS topic.  
#    - **Output**  
#      - Exposes `sns_topic_arn` so other modules can subscribe to it.

# 2. **Root Configuration (main.tf)**  
#    - **Calls `primary_monitoring`** to stand up those alarms and topic in **`primary_region`**.  
#    - **Forwarding Rule**  
#      - An EventBridge rule listens for **SNS Publish** events on that topic.  
#      - Its target is the **default event bus** in the **secondary region**, so every SNS notification is forwarded cross‑region.

# 3. **Secondary Failover Module**  
#    - **Provider Alias**  
#      - Uses the `aws.secondary` provider pointing at `secondary_region`.  
#    - **Lambda Setup**  
#      - Packages and deploys `lambda_function.py` which, on invocation,  
#        1. Scales up the secondary ASG  
#        2. Promotes the secondary RDS replica  
#    - **Trigger**  
#      - An EventBridge rule in the secondary region watches for SNS Publish events (forwarded by the root).  
#      - When it sees one, it invokes the Lambda.

# ---

# ### 📈 Failure Flow

# 1. **Primary ALB or RDS fails** → publishes to SNS in primary.  
# 2. SNS → EventBridge rule in **primary** publishes to **secondary** event bus.  
# 3. **Secondary** EventBridge sees the forwarded event → invokes failover Lambda.  
# 4. Lambda brings up EC2 capacity **and** promotes the read‑replica, synchronously.

# This guarantees that **any** primary‑side failure (ALB or RDS) always triggers **both** EC2 scaling and RDS promotion in the secondary region.
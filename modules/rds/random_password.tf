resource "random_password" "master" {
  length           = 16
  override_special = "!@#_"
}

resource "aws_ssm_parameter" "db_master_password" {
  name        =var.db_password_ssm_param  #"/lamp/rds/master_password"
  description = "Master password for Lamp RDS DB(primary)"
  type        = "SecureString"
  value       = random_password.master.result

  tags = {
    Name        = "lamp-rds-password"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
  }
}

resource "aws_ssm_parameter" "db_master_password_secondary" {
  provider    = aws.secondary
  name        = var.db_password_ssm_param  # Same name, e.g., "/lamp/rds/master_password"
  description = "Master password for Lamp RDS DB (secondary)"
  type        = "SecureString"
  value       = random_password.master.result
  tags = {
    Name        = "lamp-rds-password"
    Environment = "DisasterRecovery"
    Project     = "LaravelApp"
  }
}
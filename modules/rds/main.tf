terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "lamp-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "lamp-db-subnet-group"
  }
}

resource "aws_db_instance" "db" {
  identifier             = var.main_db_identifier
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 10
  db_name                = var.db_name
  username               = var.db_username
  password               = data.aws_ssm_parameter.db_master.value
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.db.name
  multi_az               = var.multi_az
  skip_final_snapshot    = true #keep snapshot when deleting db(must be false)

  backup_retention_period = 1 # Enable automated backups (1 day retention)
  tags = {
    Name = var.main_db_identifier
  }
}
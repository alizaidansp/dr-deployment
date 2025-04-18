output "db_endpoint" {
  # value = aws_db_instance.db.endpoint
  value = split(":", aws_db_instance.db.endpoint)[0]  # Takes the part before ":"

}

output "main_db_arn" {
  description = "ARN of the main DB instance"
  value       = aws_db_instance.db.arn
  
}

output "replica_endpoint" {
  value = split(":", aws_db_instance.replica.endpoint)[0]
}

output "db_master_ssm_name" {
  description = "SSM Parameter name for the DB master password"
  value       = aws_ssm_parameter.db_master_password.name
  sensitive   = true
}



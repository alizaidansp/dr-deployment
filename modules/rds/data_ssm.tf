data "aws_ssm_parameter" "db_master" {
  name             = aws_ssm_parameter.db_master_password.name
  with_decryption  = true
}
data "aws_ssm_parameter" "db_master_secondary" {
  name             = aws_ssm_parameter.db_master_password_secondary.name
  with_decryption  = true
}

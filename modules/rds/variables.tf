variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}



variable "multi_az" {
  type    = bool
}

variable "db_password_ssm_param" {  
type = string

}
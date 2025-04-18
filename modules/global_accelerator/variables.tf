

variable "accelerator_name" {
  type        = string
  default     = "lamp-accelerator"
  description = "Name of the Global Accelerator"
}

variable "ip_address_type" {
  type    = string
  default = "IPV4"
}

variable "enabled" {
  type    = bool
  default = true
}

variable "listener_protocol" {
  type    = string
  default = "TCP"
}

variable "port" {
  type    = number
  default = 80
}

variable "primary_region" {
  type    = string
}

variable "secondary_region" {
  type    = string
}

variable "health_check_port" {
  type    = number
  default = 80
}

variable "health_check_protocol" {
  type    = string
  default = "HTTP"
}

variable "health_check_path" {
  type    = string
}

variable "primary_alb_arn" {
  type = string
}

variable "secondary_alb_arn" {
  type = string
}

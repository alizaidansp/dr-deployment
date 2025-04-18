resource "aws_globalaccelerator_accelerator" "main" {
  name            = var.accelerator_name
  ip_address_type = var.ip_address_type
  enabled         = var.enabled
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol        = var.listener_protocol

  port_range {
    from_port = var.port
    to_port   = var.port
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn            = aws_globalaccelerator_listener.main.id
  endpoint_group_region   = var.primary_region
  traffic_dial_percentage = 100
  health_check_port       = var.health_check_port
  health_check_protocol   = var.health_check_protocol
  health_check_path       = var.health_check_path

  endpoint_configuration {
    endpoint_id = var.primary_alb_arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn            = aws_globalaccelerator_listener.main.id
  endpoint_group_region   = var.secondary_region
  traffic_dial_percentage = 0
  health_check_port       = var.health_check_port
  health_check_protocol   = var.health_check_protocol
  health_check_path       = var.health_check_path

  endpoint_configuration {
    endpoint_id = var.secondary_alb_arn
    weight      = 100
  }
}
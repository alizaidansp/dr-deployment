output "primary_ami_id" {
  value = aws_ami_from_instance.lamp_ami.id
}

output "secondary_ami_id" {
  value = aws_ami_copy.lamp_ami_secondary.id
}
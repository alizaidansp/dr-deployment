output "ec2_private_ip" {
  description = "Private IPs of the EC2 instances in the Auto Scaling Group"
  value       = data.aws_instances.asg_instances.private_ips
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# Base AMI (Amazon Linux 2)
data "aws_ami" "amazon_linux" {
  
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Temporary EC2 instance (primary region only)
resource "aws_instance" "ami_builder" {
 
  ami                    = data.aws_ami.amazon_linux.id
  # ami                    = "ami-0e03e80affb5b6b06"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [var.primary_security_group_id]
  subnet_id              = var.primary_subnet_id
  iam_instance_profile   = var.iam_instance_profile

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
  EOF

  tags = {
    Name = "lamp-ami-builder"
  }
}

# Create AMI from instance
resource "aws_ami_from_instance" "lamp_ami" {

  name               = var.ami_name
  source_instance_id = aws_instance.ami_builder.id
  depends_on         = [aws_instance.ami_builder]

  tags = {
    Name = "lamp-app-ami"
  }
}

# Copy AMI to secondary region
resource "aws_ami_copy" "lamp_ami_secondary" {
  provider            = aws.secondary
  name = "${var.ami_name}-secondary"

  source_ami_id       = aws_ami_from_instance.lamp_ami.id
  source_ami_region   = var.primary_region
  depends_on          = [aws_ami_from_instance.lamp_ami]

  tags = {
    Name = "lamp-app-ami"
  }
}

# Clean up the temporary instance
resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 terminate-instances --instance-ids ${aws_instance.ami_builder.id} --region ${var.primary_region}
    EOT
  }
  depends_on = [aws_ami_from_instance.lamp_ami, aws_ami_copy.lamp_ami_secondary]
}



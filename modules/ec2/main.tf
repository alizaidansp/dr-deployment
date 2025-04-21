terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "lamp-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  # key_name      = var.ssh_key_name
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash

  # Set variables
  IMAGE=${var.ecr_repo_url}:latest
  # IMAGE="183631301567.dkr.ecr.eu-west-1.amazonaws.com/lamp-app:latest"
  DB_PASSWORD=$(aws ssm get-parameter --name "/lamp/rds/master_password" --with-decryption --region ${var.region} --query 'Parameter.Value' --output text)

  # Install and start Docker
  yum update -y
  amazon-linux-extras install docker -y
  service docker start
  usermod -a -G docker ec2-user

  # Login to ECR and pull image
  aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_repo_url}
  docker pull $IMAGE || echo "Pull failed" >> /var/log/user-data.log

  # Run container
  docker run -p 80:80 \
    -e APP_ENV=production \
    -e DB_HOST=${var.db_host} \
    -e DB_CONNECTION=mysql \
    -e DB_PORT=3306 \
    -e DB_DATABASE=${var.db_name} \
    -e DB_USERNAME=${var.db_username} \
    -e DB_PASSWORD="$DB_PASSWORD" \
    -e AWS_DEFAULT_REGION=${var.region} \
    -e AWS_BUCKET=${var.aws_bucket} \
    -e AWS_URL=${var.aws_url} \
    -e AWS_ENDPOINT=${var.aws_endpoint} \
    $IMAGE || echo "Run failed" >> /var/log/user-data.log

  # Wait and then run migrations
  sleep 10
  CONTAINER_ID=$(docker ps -q -f "ancestor=$IMAGE")
  if [ -n "$CONTAINER_ID" ]; then
    docker exec $CONTAINER_ID php artisan session:table || echo "Session table failed" >> /var/log/user-data.log
    docker exec $CONTAINER_ID php artisan migrate --force || echo "Migration failed" >> /var/log/user-data.log
    docker exec $CONTAINER_ID php artisan db:seed || echo "Seeding failed" >> /var/log/user-data.log
  else
    echo "No container running" >> /var/log/user-data.log
  fi
EOF
)

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "lamp-ec2"
  }
}

resource "aws_autoscaling_group" "app" {
  name                = var.region == "us-east-1" ? var.secondary_asg_name : var.primary_asg_name
  desired_capacity    = var.desired_capacity
  max_size            = 2
  min_size            = var.min_size
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.alb_target_group_arn]
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.region == "us-east-1" ? "lamp-ec2-asg" : "lamp-ec2-asg-primary"
    propagate_at_launch = true
  }
}

# Data source to fetch instances managed by the ASG
data "aws_instances" "asg_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.app.name
  }

  depends_on = [aws_autoscaling_group.app]
}
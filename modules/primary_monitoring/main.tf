terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_sns_topic" "failover" {
  
  name     = "failover-topic"
}

resource "aws_sns_topic_subscription" "test_subscription" {
  topic_arn = aws_sns_topic.failover.arn
  protocol  = "email"
  endpoint  = "zaidanali028@gmail.com" # Replace with your email
}




resource "aws_cloudwatch_metric_alarm" "primary_alb_unhealthy" {
  
  alarm_name          = "primary-alb-unhealthy"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
   dimensions = {
    LoadBalancer = var.alb_arn
  }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions = [aws_sns_topic.failover.arn]

}


#  RDS availability alarm 
resource "aws_cloudwatch_metric_alarm" "rds_not_available" {
  alarm_name          = "RDSNotAvailable"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"   # alarm if min connections < 1
  alarm_actions       = [aws_sns_topic.failover.arn]
}




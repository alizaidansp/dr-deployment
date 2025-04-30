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




resource "aws_sns_topic_subscription" "alert_alarm_subscription" {
  topic_arn = aws_sns_topic.failover.arn
  protocol  = "email"
  endpoint  = "zaidanali028@gmail.com" 
}

#  Lambda in secondary region subscription to Primary SNS topic
resource "aws_sns_topic_subscription" "sns_to_lambda" {
  topic_arn = aws_sns_topic.failover.arn
  protocol  = "lambda"
  endpoint  = var.failover_lambda_arn
}




resource "aws_cloudwatch_metric_alarm" "primary_alb_unhealthy" {
  
  alarm_name          = "primary-alb-unhealthy"
  namespace          = "AWS/ApplicationELB"
  metric_name        = "UnHealthyHostCount"
   dimensions = {
      TargetGroup = var.primary_target_group_arn_suffix
    LoadBalancer = var.primary_alb_arn_suffix
  }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
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



# allow SNS to receive publish events from cloudwatch
resource "aws_sns_topic_policy" "cloudwatch_publish_policy" {
  arn    = aws_sns_topic.failover.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowCloudWatch",
      Effect    = "Allow",
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      },
      Action    = "SNS:Publish",
      Resource  = aws_sns_topic.failover.arn
    }]
  })
}
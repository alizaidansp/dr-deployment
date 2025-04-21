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
  comparison_operator = "LessThanOrEqualToThreshold"

  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  treat_missing_data = "breaching"  # Treat missing data as "unhealthy"
  threshold           = 0
  alarm_description   = "Alarm when no healthy hosts are available in primary ALB"
   dimensions = {
    TargetGroup  = split(":", var.primary_target_group_arn)[5]  # Gets everything after the 5th colon
    LoadBalancer = split(":", var.alb_arn)[5]  
  }
  alarm_actions = [aws_sns_topic.failover.arn]
}

resource "aws_cloudwatch_event_rule" "rds_failure" {
  
  name        = "rds-failure"
  description = "Capture RDS failure events"
  event_pattern = jsonencode({
    "source"      : ["aws.rds"],
    "detail-type" : ["RDS DB Instance Event"],
    "detail"      : {
        EventCategories = [ "failure", "availability", ]
    }
  })
}

resource "aws_cloudwatch_event_target" "rds_to_sns" {
  
  rule      = aws_cloudwatch_event_rule.rds_failure.name
  target_id = "sendToSNS"
  arn       = aws_sns_topic.failover.arn
}




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

resource "aws_sns_topic_policy" "allow_eventbridge" {
  
  arn      = aws_sns_topic.failover.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.failover.arn
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "primary_alb_unhealthy" {
  
  alarm_name          = "primary-alb-unhealthy"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Minimum"
  threshold           = 0
  alarm_description   = "Alarm when no healthy hosts are available in primary ALB"
  dimensions = {
    TargetGroup  = var.primary_target_group_arn
    LoadBalancer = var.primary_alb_arn
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
      "EventCategories" : ["failure"]
    }
  })
}

resource "aws_cloudwatch_event_target" "rds_to_sns" {
  
  rule      = aws_cloudwatch_event_rule.rds_failure.name
  target_id = "sendToSNS"
  arn       = aws_sns_topic.failover.arn
}

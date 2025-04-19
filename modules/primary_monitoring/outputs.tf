output "sns_topic_arn" {
  description = "ARN of the SNS failover topic"
  value       = aws_sns_topic.failover.arn
}

output "alarm_name" {
  description = "Name of the ALB health alarm"
  value       = aws_cloudwatch_metric_alarm.primary_alb_unhealthy.alarm_name
}

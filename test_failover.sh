#!/bin/bash

# Test script to verify the failover mechanism

echo "Testing failover mechanism..."

# 1. Get the SNS topic ARN
SNS_TOPIC_ARN=$(aws sns list-topics --query 'Topics[?contains(TopicArn, `failover-topic`)].TopicArn' --output text)
echo "SNS Topic ARN: $SNS_TOPIC_ARN"

if [ -z "$SNS_TOPIC_ARN" ]; then
  echo "Error: SNS topic not found. Make sure the infrastructure is deployed."
  exit 1
fi

# 2. Publish a test message to the SNS topic
echo "Publishing test message to SNS topic..."
aws sns publish \
  --topic-arn "$SNS_TOPIC_ARN" \
  --message '{"AlarmName":"primary-alb-unhealthy","AlarmDescription":"Alarm when no healthy hosts are available in primary ALB","NewStateValue":"ALARM","NewStateReason":"Threshold Crossed"}' \
  --subject "Test Failover"

echo "Test message published. Check CloudWatch Logs for the Lambda function to verify it was triggered."
echo "You can use the following command to check the logs:"
echo "aws logs filter-log-events --log-group-name /aws/lambda/failover-handler --query 'events[].message' --output text"

# 3. Wait a few seconds for the Lambda to execute
echo "Waiting for Lambda execution..."
sleep 5

# 4. Check if the Lambda was invoked
echo "Checking Lambda invocation logs..."
LOGS=$(aws logs filter-log-events --log-group-name /aws/lambda/failover-handler --start-time $(($(date +%s) - 60))000 --query 'events[].message' --output text)

if echo "$LOGS" | grep -q "Triggering EC2 failover"; then
  echo "Success: Lambda was triggered and executed the failover logic."
else
  echo "Warning: Could not confirm Lambda execution. Check the logs manually."
fi

echo "Test completed."
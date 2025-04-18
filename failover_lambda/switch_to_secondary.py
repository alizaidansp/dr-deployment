import boto3
import time

def lambda_handler(event, context):
    # By default, Boto3 clients use the region of the Lambda function’s execution environmen
    rds = boto3.client('rds')
    asg = boto3.client('autoscaling')

    # Promote RDS replica
    rds.promote_read_replica(DBInstanceIdentifier='lamp-db-replica')

    # Wait for promotion
    while True:
        response = rds.describe_db_instances(DBInstanceIdentifier='lamp-db-replica')
        status = response['DBInstances'][0]['DBInstanceStatus']
        if status == 'available':
            break
        time.sleep(30)

    # Update ASG
    asg.update_auto_scaling_group(
        AutoScalingGroupName='lamp-ec2-asg',
        DesiredCapacity=1
    )

    return {
        'statusCode': 200,
        'body': 'Failover initiated'
    }
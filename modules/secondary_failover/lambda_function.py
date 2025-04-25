import os
import urllib.request
import boto3
import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
# Autoscaling and RDS clients for secondary region (for failover actions)
autoscaling = boto3.client('autoscaling', region_name=os.environ['SECONDARY_REGION'])
rds_secondary = boto3.client('rds', region_name=os.environ['SECONDARY_REGION'])

# RDS client for primary region (for health check)
rds_primary = boto3.client('rds', region_name=os.environ['PRIMARY_REGION'])

def lambda_handler(event, context):
    # Environment variables
    try:
        primary_alb_dns = os.environ['PRIMARY_ALB_DNS_NAME']
        health_check_path = os.environ['HEALTH_CHECK_PATH']
        secondary_asg_name = os.environ['SECONDARY_ASG_NAME']
        secondary_rds_id = os.environ['SECONDARY_RDS_ID']
        primary_rds_id = os.environ['PRIMARY_RDS_ID']
        primary_region = os.environ['PRIMARY_REGION']
        expected_status_codes = json.loads(os.environ.get('EXPECTED_STATUS_CODES', '[200]'))  # Default to [200]
    except KeyError as e:
        logger.error(f"Missing environment variable: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: Missing environment variable {e}')
        }

    # Log environment variables
    # logger.info(f"Environment variables: primary_alb_dns={primary_alb_dns}, "
    #             f"health_check_path={health_check_path}, secondary_asg_name={secondary_asg_name}, "
    #             f"secondary_rds_id={secondary_rds_id}, primary_rds_id={primary_rds_id}, "
    #             f"primary_region={primary_region}, expected_status_codes={expected_status_codes}")

    # 1. Check ALB health
    alb_healthy = True
    url = f"http://{primary_alb_dns}{health_check_path}"
    logger.info(f"ALB health check URL: {url}")
    status_code = None
    try:
        with urllib.request.urlopen(url) as response:
            status_code = response.status
            logger.info(f"ALB health check response: status_code={status_code}")
    except Exception as e:
        logger.error(f"ALB health check failed: {str(e)}")
        alb_healthy = False

    if status_code not in expected_status_codes:
        alb_healthy = False
        logger.warning("ALB unhealthy: Unexpected status code or connection failure")

    # 2. Check RDS health
    rds_healthy = True
    try:
        response = rds_primary.describe_db_instances(DBInstanceIdentifier=primary_rds_id)
        rds_status = response['DBInstances'][0]['DBInstanceStatus']
        logger.info(f"RDS health check: primary_rds_id={primary_rds_id}, status={rds_status}")
        if rds_status != 'available':
            rds_healthy = False
            logger.warning(f"RDS unhealthy: status={rds_status}")
    except Exception as e:
        logger.error(f"RDS health check failed: {str(e)}")
        rds_healthy = False

    # Trigger failover if either ALB or RDS is unhealthy
    if not alb_healthy or not rds_healthy:
        logger.warning("Failover triggered due to unhealthy ALB or RDS")
        # 1. Scale up the secondary ASG
        try:
            autoscaling.update_auto_scaling_group(
                AutoScalingGroupName=secondary_asg_name,
                MinSize=1,
                DesiredCapacity=1
            )
            logger.info(f"Scaled up ASG: {secondary_asg_name} ")
        except Exception as e:
            logger.error(f"Failed to scale ASG {secondary_asg_name}: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Error scaling ASG: {str(e)}')
            }

        # 2. Promote the RDS read replica
        try:
            rds_secondary.promote_read_replica(
                DBInstanceIdentifier=secondary_rds_id,
                BackupRetentionPeriod=1
            )
            logger.info(f"Promoted RDS replica: {secondary_rds_id} ")
        except Exception as e:
            logger.error(f"Failed to promote RDS {secondary_rds_id}: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Error promoting RDS: {str(e)}')
            }

        return {
            'statusCode': 200,
            'body': json.dumps('Failover initiated due to unhealthy ALB or RDS')
        }
    else:
        logger.info("Both ALB and RDS are healthy")
        return {
            'statusCode': 200,
            'body': json.dumps('Both ALB and RDS are healthy')
        }
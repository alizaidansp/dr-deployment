import os
import boto3
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    rds_client = boto3.client('rds', region_name=os.environ['REGION'])
    instance_id = os.environ['RDS_INSTANCE_IDENTIFIER']
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    snapshot_id = f"{instance_id}-snapshot-{timestamp}"
    
    try:
        response = rds_client.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=instance_id
        )
        logger.info(f"Snapshot {snapshot_id} creation initiated.")
        return {
            'statusCode': 200,
            'body': f"Snapshot {snapshot_id} creation initiated."
        }
    except Exception as e:
        logger.error(f"Error creating snapshot: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error: {str(e)}"
        }
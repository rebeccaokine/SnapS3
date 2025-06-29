import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DDB_TABLE_NAME'])

def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        size = record['s3']['object']['size']
        timestamp = datetime.utcnow().isoformat()

        table.put_item(Item={
            'photo_name': key,
            'upload_time': timestamp,
            'file_size': size
        })

    return {
        'statusCode': 200,
        'body': json.dumps('Metadata saved successfully!')
    }

import boto3
import json
from django.conf import settings
import time

class SQSManager:
    def __init__(self):
        self.sqs = boto3.client('sqs',
                                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                                region_name=settings.AWS_REGION)
        self.queue_url = self.get_queue_url()
        self.wait_time_per_user = 5

    def get_queue_url(self):
        return self.sqs.get_queue_url(QueueName=settings.SQS_QUEUE_NAME)['QueueUrl']

    def send_message(self, user_id):
        response = self.sqs.send_message(
            QueueUrl=self.queue_url,
            MessageBody=json.dumps({'user_id': user_id, 'timestamp': int(time.time())}),
            MessageGroupId='reservation_group',
            MessageDeduplicationId=f"{user_id}-{int(time.time())}"
        )
        return response['MessageId']

    def get_queue_position(self, user_id):
        messages = self.sqs.receive_message(
            QueueUrl=self.queue_url,
            MaxNumberOfMessages=10,
            VisibilityTimeout=0,
            WaitTimeSeconds=0
        ).get('Messages', [])
        
        current_time = int(time.time())
        for i, message in enumerate(messages):
            message_body = json.loads(message['Body'])
            if message_body['user_id'] == user_id:
                time_in_queue = current_time - message_body['timestamp']
                if time_in_queue >= i * self.wait_time_per_user:
                    return max(1, i + 1 - (time_in_queue // self.wait_time_per_user))
                else:
                    return i + 1
        return -1  # User not found in the first 10 messages

    def is_user_turn(self, user_id):
        return self.get_queue_position(user_id) == 1
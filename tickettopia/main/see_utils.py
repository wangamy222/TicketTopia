import boto3
from django.conf import settings

def send_email(recipient, subject, body):
    client = boto3.client('ses',
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_SES_REGION_NAME
    )

    response = client.send_email(
        Destination={
            'ToAddresses': [recipient],
        },
        Message={
            'Body': {
                'Text': {
                    'Charset': 'UTF-8',
                    'Data': body,
                },
            },
            'Subject': {
                'Charset': 'UTF-8',
                'Data': subject,
            },
        },
        Source='tickettopiaofficials@gmail.com', 
    )

    return response
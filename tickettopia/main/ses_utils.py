import boto3
from django.conf import settings

def send_email(recipient, subject, body, is_html=False):
    client = boto3.client('ses',
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_SES_REGION_NAME
    )

    message = {
        'Subject': {
            'Charset': 'UTF-8',
            'Data': subject,
        },
        'Body': {
            'Text': {
                'Charset': 'UTF-8',
                'Data': body,
            }
        }
    }

    if is_html:
        message['Body']['Html'] = {
            'Charset': 'UTF-8',
            'Data': body,
        }

    response = client.send_email(
        Destination={
            'ToAddresses': [recipient],
        },
        Message=message,
        Source='tickettopiaofficials@gmail.com',  # Your verified sender email
    )

    return response
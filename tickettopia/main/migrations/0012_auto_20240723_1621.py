# Generated by Django 3.2.25 on 2024-07-23 07:21

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('main', '0011_payment_uname'),
    ]

    operations = [
        migrations.DeleteModel(
            name='Counter',
        ),
        migrations.AlterModelOptions(
            name='payment',
            options={'managed': False},
        ),
    ]

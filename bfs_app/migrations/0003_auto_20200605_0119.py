# Generated by Django 3.0.6 on 2020-06-04 22:19

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bfs_app', '0002_auto_20200604_2321'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='banker_contract_address',
            field=models.CharField(default=None, max_length=50, null=True, unique=True),
        ),
        migrations.AddField(
            model_name='user',
            name='user_contract_address',
            field=models.CharField(default=None, max_length=50, null=True, unique=True),
        ),
    ]

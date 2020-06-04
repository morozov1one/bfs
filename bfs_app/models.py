from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    username = models.CharField(max_length=32, unique=True)
    email = models.EmailField(unique=True)
    keystore = models.CharField(max_length=1000, unique=True)
    main_contract_address = models.CharField(max_length=50, unique=True)
    user_contract_address = models.CharField(max_length=50, unique=True, default=None, null=True)
    banker_contract_address = models.CharField(max_length=50, unique=True, default=None, null=True)
    account_type = models.IntegerField(default=None, null=True)

    USERNAME_FIELD = 'username'

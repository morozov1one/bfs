from django.db import models
from django.contrib.auth.models import AbstractBaseUser


class User(AbstractBaseUser):
    username = models.CharField(max_length=32, unique=True)
    email = models.EmailField(unique=True)
    wallet = models.CharField(max_length=50, unique=True)

    USERNAME_FIELD = 'wallet'

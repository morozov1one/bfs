from django.contrib.auth import get_user_model
from django.contrib.auth.models import User


class AuthenticationEmailBackend(object):
    def authenticate(self, email=None, password=None, **kwargs):
        userModel = get_user_model()
        try:
            user = userModel.objects.get(email=email)
        except userModel.DoesNotExist:
            return None
        else:
            if getattr(user, 'is_active', False) and user.check_password(password):
                return user
        return None

    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None

from django import forms
from django.contrib.auth.forms import AuthenticationForm


PORTAL_GROUP = 'internal_portal'


def has_portal_access(user):
    return bool(
        user.is_authenticated
        and user.is_active
        and (
            user.is_superuser
            or user.groups.filter(name=PORTAL_GROUP).exists()
        )
    )


class PortalAuthenticationForm(AuthenticationForm):
    error_messages = {
        **AuthenticationForm.error_messages,
        'invalid_login': '账号、密码或访问权限不正确。',
    }

    def confirm_login_allowed(self, user):
        super().confirm_login_allowed(user)
        if not has_portal_access(user):
            raise forms.ValidationError(
                self.error_messages['invalid_login'],
                code='invalid_login',
            )

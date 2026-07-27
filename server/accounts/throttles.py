from rest_framework.throttling import SimpleRateThrottle


class _BaseRateThrottle(SimpleRateThrottle):
    """Use the account id when available, otherwise the client IP."""

    def get_cache_key(self, request, view):
        if request.user and request.user.is_authenticated:
            ident = f'user-{request.user.pk}'
        else:
            ident = self.get_ident(request)
        return self.cache_format % {'scope': self.scope, 'ident': ident}


class LoginRateThrottle(_BaseRateThrottle):
    scope = 'auth_login'
    rate = '30/min'


class RegisterRateThrottle(_BaseRateThrottle):
    scope = 'auth_register'
    rate = '10/hour'


class TokenRefreshRateThrottle(_BaseRateThrottle):
    scope = 'auth_refresh'
    rate = '60/min'


class AvatarUploadRateThrottle(_BaseRateThrottle):
    scope = 'avatar_upload'
    rate = '20/hour'


class AccountDeletionCancelRateThrottle(_BaseRateThrottle):
    scope = 'account_deletion_cancel'
    rate = '10/hour'


class PdfTokenRateThrottle(_BaseRateThrottle):
    scope = 'pdf_token'
    rate = '30/min'

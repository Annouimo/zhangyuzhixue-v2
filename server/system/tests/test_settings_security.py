import pytest
from django.core.exceptions import ImproperlyConfigured

from math_platform.settings import require_production_value


@pytest.mark.parametrize('value', [
    '',
    'change-me',
    'dev-pdf-key-for-testing',
    'too-short',
])
def test_require_production_value_rejects_weak_values(value):
    with pytest.raises(ImproperlyConfigured):
        require_production_value('TEST_SECRET', value, min_length=32)


def test_require_production_value_accepts_strong_value():
    value = 'a-strong-random-production-value-with-sufficient-length'
    assert require_production_value(
        'TEST_SECRET', value, min_length=32,
    ) == value


def test_development_security_defaults(settings):
    assert settings.ENVIRONMENT == 'development'
    assert settings.SESSION_COOKIE_SECURE is False
    assert settings.CSRF_COOKIE_SECURE is False
    assert settings.SECURE_HSTS_SECONDS == 0
    assert settings.SECURE_SSL_REDIRECT is False

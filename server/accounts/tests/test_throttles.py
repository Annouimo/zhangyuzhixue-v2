import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from accounts.throttles import LoginRateThrottle


@pytest.mark.django_db
def test_login_rate_limit(monkeypatch):
    cache.clear()
    monkeypatch.setattr(LoginRateThrottle, 'rate', '2/min')
    try:
        client = APIClient()
        payload = {'username': 'missing-user', 'password': 'wrong-password'}

        assert client.post('/api/v1/auth/login/', payload, format='json').status_code == 400
        assert client.post('/api/v1/auth/login/', payload, format='json').status_code == 400
        assert client.post('/api/v1/auth/login/', payload, format='json').status_code == 429
    finally:
        cache.clear()

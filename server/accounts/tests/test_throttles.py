import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from accounts.throttles import LoginRateThrottle, RegisterDailyRateThrottle, RegisterRateThrottle


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


@pytest.mark.django_db
def test_register_hourly_rate_limit(monkeypatch):
    cache.clear()
    monkeypatch.setattr(RegisterRateThrottle, 'rate', '2/min')
    monkeypatch.setattr(RegisterDailyRateThrottle, 'rate', '100/day')
    try:
        client = APIClient()
        payload = {
            'username': 'new-student',
            'password': 'test-password-123',
            'real_name': '新学生',
            'accepted_terms': True,
            'accepted_privacy': True,
        }

        assert client.post('/api/v1/auth/register/', payload, format='json').status_code == 400
        assert client.post('/api/v1/auth/register/', payload, format='json').status_code == 400
        assert client.post('/api/v1/auth/register/', payload, format='json').status_code == 429
    finally:
        cache.clear()

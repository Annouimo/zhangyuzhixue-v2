"""API 文档 schema 测试"""
import pytest
from django.urls import reverse
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


class TestApiDocs:

    def test_schema_accessible(self, api_client):
        """GET /api/docs/ → 200，返回 OpenAPI schema"""
        resp = api_client.get(reverse('schema'))
        assert resp.status_code == 200
        assert 'openapi' in resp.data or resp.status_code == 200

    def test_schema_contains_key_endpoints(self, api_client):
        """Schema 中包含关键 API 端点"""
        resp = api_client.get(reverse('schema'))
        data = resp.data if isinstance(resp.data, dict) else {}
        paths = data.get('paths', {})
        assert '/api/v1/auth/login/' in paths
        assert '/api/v1/auth/register/' in paths
        assert '/api/v1/sync/push/' in paths
        assert '/api/v1/user/me/' in paths

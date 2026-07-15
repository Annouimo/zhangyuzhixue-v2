"""认证 API 测试 — 登录/登出/刷新"""
import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework.reverse import reverse

from accounts.models import Student


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def registered_user(db):
    u = User.objects.create_user('teststudent', password='test123456')
    Student.objects.create(user=u)
    return u


# ── 登录测试 ──


class TestLogin:
    def test_login_success(self, api_client, registered_user):
        """正常登录：应返回 JWT + 用户信息"""
        resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'test123456',
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert 'access' in resp.data['data']
        assert 'refresh' in resp.data['data']
        assert resp.data['data']['user']['username'] == 'teststudent'
        assert resp.data['data']['user']['role'] == 'student'

    def test_login_wrong_password(self, api_client, registered_user):
        """错误密码：应返回 40001"""
        resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'wrongpass',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40001

    def test_login_nonexistent_user(self, db, api_client):
        """不存在的用户：应返回 40001"""
        resp = api_client.post(reverse('auth-login'), {
            'username': 'nobody',
            'password': 'test123456',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40001

    def test_login_admin_refused(self, db, api_client):
        """管理员账号：应拒绝"""
        User.objects.create_superuser('adminuser', 'admin@test.com', 'admin123')
        resp = api_client.post(reverse('auth-login'), {
            'username': 'adminuser',
            'password': 'admin123',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40003

    def test_login_missing_fields(self, api_client):
        """缺少字段：应返回 400"""
        resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
        }, format='json')
        assert resp.status_code == 400


# ── Token 刷新测试 ──


class TestRefresh:
    def test_refresh_success(self, api_client, registered_user):
        """用 refresh token 获取新的 access token"""
        login_resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'test123456',
        }, format='json')
        refresh_token = login_resp.data['data']['refresh']
        resp = api_client.post(reverse('auth-refresh'), {
            'refresh': refresh_token,
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert 'access' in resp.data['data']

    def test_refresh_invalid_token(self, api_client):
        """无效 refresh token：应返回错误"""
        resp = api_client.post(reverse('auth-refresh'), {
            'refresh': 'invalid-token-here',
        }, format='json')
        assert resp.status_code == 401
        assert 'code' in resp.data


# ── 登出测试 ──


class TestLogout:
    def test_logout_authenticated(self, api_client, registered_user):
        """已认证用户登出：应返回成功"""
        login_resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'test123456',
        }, format='json')
        token = login_resp.data['data']['access']
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        resp = api_client.post(reverse('auth-logout'), format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert '已登出' in resp.data['message']

    def test_logout_unauthenticated(self, api_client):
        """未认证用户登出：应返回 401"""
        resp = api_client.post(reverse('auth-logout'), format='json')
        assert resp.status_code == 401

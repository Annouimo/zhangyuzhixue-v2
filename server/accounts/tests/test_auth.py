"""认证 API 的注册、登录、登出与刷新测试。"""
import pytest
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework.reverse import reverse

from accounts.models import RegistrationConsent, Student
from accounts.roles import STUDENT_GROUP


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

    def test_login_rejects_user_without_student_role(self, db, api_client):
        User.objects.create_user('plain-user', password='test123456')
        resp = api_client.post(reverse('auth-login'), {
            'username': 'plain-user', 'password': 'test123456',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40003


class TestRegister:
    def test_registration_requires_explicit_consent(self, db, api_client):
        response = api_client.post(reverse('auth-register'), {
            'username': 'newstudent',
            'password': 'test-password-123',
            'real_name': '新学生',
            'phone': '13800138000',
            'accepted_terms': False,
            'accepted_privacy': True,
        }, format='json')
        assert response.status_code == 400
        assert User.objects.filter(username='newstudent').exists() is False

    def test_registration_records_consent(self, db, api_client):
        response = api_client.post(reverse('auth-register'), {
            'username': 'newstudent',
            'password': 'test-password-123',
            'real_name': '新学生',
            'phone': '13800138000',
            'gaokao_year': 2027,
            'accepted_terms': True,
            'accepted_privacy': True,
        }, format='json')
        assert response.status_code == 200
        user = User.objects.get(username='newstudent')
        assert user.groups.filter(name=STUDENT_GROUP).exists()
        consent = RegistrationConsent.objects.get(user=user)
        assert consent.terms_version == '2026-07-27'
        assert consent.privacy_version == '2026-07-27'

    def test_registration_requires_phone(self, db, api_client):
        response = api_client.post(reverse('auth-register'), {
            'username': 'missing-phone',
            'password': 'test-password-123',
            'real_name': '新学生',
            'accepted_terms': True,
            'accepted_privacy': True,
        }, format='json')
        assert response.status_code == 400
        assert User.objects.filter(username='missing-phone').exists() is False

    def test_duplicate_phone_is_rejected(self, db, api_client):
        owner = User.objects.create_user('owner', password='test-password-123')
        Student.objects.create(user=owner, phone='13800138000')
        response = api_client.post(reverse('auth-register'), {
            'username': 'duplicate-phone',
            'password': 'test-password-123',
            'real_name': '新学生',
            'phone': '13800138000',
            'accepted_terms': True,
            'accepted_privacy': True,
        }, format='json')
        assert response.status_code == 400
        assert '手机号已注册' in response.data['message']
        assert User.objects.filter(username='duplicate-phone').exists() is False


class TestLoginErrors:
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

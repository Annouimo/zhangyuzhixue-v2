"""认证 API 测试 — 注册/登录/刷新/登出 4 场景"""

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import InvitationCode

# ── 夹具 ──────────────────────────────────────────────────────


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def valid_invitation_code(db):
    """创建不过期的邀请码"""
    code = InvitationCode.objects.create(
        code='TEST-ABCD-1234',
        is_used=False,
        expires_at=timezone.now() + timezone.timedelta(days=30),
    )
    return code


@pytest.fixture
def fresh_invitation_code(db):
    """创建另一个不过期的邀请码（用于重复用户名测试）"""
    code = InvitationCode.objects.create(
        code='FRESH-CODE-5678',
        is_used=False,
        expires_at=timezone.now() + timezone.timedelta(days=30),
    )
    return code


@pytest.fixture
def expired_invitation_code(db):
    """创建已过期的邀请码"""
    code = InvitationCode.objects.create(
        code='EXPIRED-CODE',
        is_used=False,
        expires_at=timezone.now() - timezone.timedelta(days=1),
    )
    return code


@pytest.fixture
def used_invitation_code(db):
    """创建已使用过的邀请码"""
    code = InvitationCode.objects.create(
        code='USED-CODE-01',
        is_used=True,
        expires_at=timezone.now() + timezone.timedelta(days=30),
    )
    return code


@pytest.fixture
def registered_user(db, valid_invitation_code):
    """调用注册 API 创建一个已注册用户"""
    client = APIClient()
    resp = client.post(reverse('auth-register'), {
        'invitation_code': 'TEST-ABCD-1234',
        'username': 'teststudent',
        'password': 'test123456',
        'real_name': '测试学生',
        'phone': '13800138001',
        'gaokao_year': 2026,
    }, format='json')
    assert resp.status_code == 200
    return User.objects.get(username='teststudent')


# ── 注册测试 ──────────────────────────────────────────────────


class TestRegister:
    """注册 API 测试"""

    def test_register_success(self, api_client, valid_invitation_code):
        """正常注册：应返回成功消息"""
        resp = api_client.post(reverse('auth-register'), {
            'invitation_code': 'TEST-ABCD-1234',
            'username': 'newstudent',
            'password': 'test123456',
            'real_name': '新同学',
            'phone': '13800138002',
            'gaokao_year': 2026,
        }, format='json')

        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert resp.data['message'] == '注册成功，请登录'
        assert resp.data['data'] is None

        # 验证 User + Student 已创建
        user = User.objects.get(username='newstudent')
        assert hasattr(user, 'student')

        # 验证邀请码已标记使用
        valid_invitation_code.refresh_from_db()
        assert valid_invitation_code.is_used is True
        assert valid_invitation_code.used_by == user

    def test_register_invalid_code(self, db, api_client):
        """无效邀请码：应返回错误"""
        resp = api_client.post(reverse('auth-register'), {
            'invitation_code': 'NONEXISTENT',
            'username': 'nosuchuser',
            'password': 'test123456',
            'real_name': '无名',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40101
        assert '无效' in resp.data['message']

    def test_register_expired_code(self, api_client, expired_invitation_code):
        """已过期邀请码：应返回错误"""
        resp = api_client.post(reverse('auth-register'), {
            'invitation_code': 'EXPIRED-CODE',
            'username': 'expireduser',
            'password': 'test123456',
            'real_name': '过期',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40101
        assert '过期' in resp.data['message']

    def test_register_used_code(self, api_client, used_invitation_code):
        """已使用的邀请码：应返回错误"""
        resp = api_client.post(reverse('auth-register'), {
            'invitation_code': 'USED-CODE-01',
            'username': 'usedcodeuser',
            'password': 'test123456',
            'real_name': '已使用',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40101
        # 实际消息：'邀请码已被使用'
        assert '已被使用' in resp.data['message']

    def test_register_duplicate_username(
            self, api_client, registered_user, fresh_invitation_code):
        """重复用户名：应返回错误（用新的邀请码隔离）"""
        resp = api_client.post(reverse('auth-register'), {
            'invitation_code': 'FRESH-CODE-5678',  # 全新邀请码
            'username': 'teststudent',  # 已存在
            'password': 'test123456',
            'real_name': '重复',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40101
        assert '已存在' in resp.data['message']


# ── 登录测试 ──────────────────────────────────────────────────


class TestLogin:
    """登录 API 测试"""

    def test_login_success(self, api_client, registered_user):
        """正常登录：应返回 JWT + 用户信息"""
        resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'test123456',
            'app_type': 'student',
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
            'password': 'wrongpassword',
            'app_type': 'student',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40001
        assert '错误' in resp.data['message']

    def test_login_nonexistent_user(self, db, api_client):
        """不存在的用户：应返回 40001"""
        resp = api_client.post(reverse('auth-login'), {
            'username': 'nobody',
            'password': 'test123456',
            'app_type': 'student',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40001

    def test_login_admin_forbidden(self, db, api_client):
        """管理员禁止登录 App"""
        User.objects.create_superuser('adminuser', 'admin@test.com', 'admin123')
        resp = api_client.post(reverse('auth-login'), {
            'username': 'adminuser',
            'password': 'admin123',
            'app_type': 'student',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40003


# ── Token 刷新测试 ────────────────────────────────────────────


class TestRefresh:
    """Token 刷新 API 测试"""

    def test_refresh_success(self, api_client, registered_user):
        """用 refresh token 获取新的 access token"""
        # 先登录
        login_resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'test123456',
            'app_type': 'student',
        }, format='json')

        refresh_token = login_resp.data['data']['refresh']

        resp = api_client.post(reverse('auth-refresh'), {
            'refresh': refresh_token,
        }, format='json')

        assert resp.status_code == 200
        assert 'access' in resp.data

    def test_refresh_invalid_token(self, api_client):
        """无效 refresh token：应返回错误"""
        resp = api_client.post(reverse('auth-refresh'), {
            'refresh': 'invalid-token-here',
        }, format='json')

        assert resp.status_code == 401
        # DRF 默认校验返回 401，走 custom_exception_handler
        # code = 40100, message 含 "invalid" 或 "Token is invalid"
        assert 'code' in resp.data


# ── 登出测试 ──────────────────────────────────────────────────


class TestLogout:
    """登出 API 测试"""

    def test_logout_authenticated(self, api_client, registered_user):
        """已认证用户登出：应返回成功"""
        # 先登录获取 token
        login_resp = api_client.post(reverse('auth-login'), {
            'username': 'teststudent',
            'password': 'test123456',
            'app_type': 'student',
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

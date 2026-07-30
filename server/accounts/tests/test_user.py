"""用户 API 测试 — 用户信息/头像上传/等级百分位"""
import io
import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Student
from system.models import PointsTransaction


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def student_user(db):
    user = User.objects.create_user('usertest', password='test123')
    Student.objects.create(user=user, gaokao_year=2026, school='北京四中')
    return user


@pytest.fixture
def auth_client(api_client, student_user):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(student_user)
    api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))
    return api_client


class TestUserMe:
    """用户信息 API 测试"""

    def test_get_me(self, auth_client):
        """GET /api/v1/user/me/ → 正确用户信息"""
        resp = auth_client.get(reverse('user-me'))
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert resp.data['data']['username'] == 'usertest'
        assert resp.data['data']['role'] == 'student'
        assert resp.data['data']['school'] == '北京四中'
        assert 'points_summary' in resp.data['data']

    def test_patch_me(self, auth_client):
        """PATCH /api/v1/user/me/ → 修改成功"""
        resp = auth_client.patch(reverse('user-me'), {
            'school': '清华附中',
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['data']['school'] == '清华附中'

    def test_patch_unauthorized_field(self, auth_client, student_user):
        """PATCH 不允许修改 username"""
        resp = auth_client.patch(reverse('user-me'), {
            'username': 'hacker',
        }, format='json')
        assert resp.status_code == 200
        student_user.refresh_from_db()
        assert student_user.username == 'usertest'  # 未改变

    def test_points_summary_includes_admin_adjustment(
            self, auth_client, student_user):
        PointsTransaction.objects.create(
            student=student_user.student,
            amount=12.5,
            transaction_type='EARN',
            source='ADMIN_ADJUST',
            description='管理员奖励',
        )

        resp = auth_client.get(reverse('user-me'))

        assert resp.status_code == 200
        summary = resp.data['data']['points_summary']
        assert summary['bonus'] == 12.5
        assert summary['available'] == 12.5


class TestCheckin:

    def test_checkin_reward_increments_user_data_version(
            self, auth_client, student_user):
        resp = auth_client.post(reverse('user-checkin'), {}, format='json')

        assert resp.status_code == 200
        assert resp.data['data']['points_earned'] > 0
        student_user.student.refresh_from_db()
        assert student_user.student.data_version == 1


class TestAvatarUpload:
    """头像上传 API 测试"""

    def test_upload_success(self, auth_client, student_user):
        """POST /api/v1/user/avatar/ → 上传成功"""
        from PIL import Image
        img = Image.new('RGB', (100, 100), color='red')
        buf = io.BytesIO()
        img.save(buf, 'PNG')
        buf.seek(0)

        resp = auth_client.post(reverse('user-avatar'), {
            'avatar': buf,
        }, format='multipart')

        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert 'avatar' in resp.data['data']
        student_user.student.refresh_from_db()
        assert student_user.student.avatar != ''

    def test_upload_no_file(self, auth_client):
        """无文件：返回错误"""
        resp = auth_client.post(reverse('user-avatar'), {}, format='multipart')
        assert resp.status_code == 400
        assert resp.data['code'] == 40201

    def test_avatar_too_large(self, auth_client):
        """超过 2MB 的图片上传返回 400"""
        large_file = io.BytesIO(b'x' * (2 * 1024 * 1024 + 1))
        large_file.name = 'large.png'
        resp = auth_client.post(reverse('user-avatar'), {
            'avatar': large_file,
        }, format='multipart')
        assert resp.status_code == 400
        assert resp.data['code'] == 40201


class TestLevelPercentile:
    """等级百分位 API 测试"""

    def test_percentile_no_data(self, auth_client, student_user):
        """无积分数据：返回默认值"""
        resp = auth_client.get(reverse('user-level-percentile'))
        assert resp.status_code == 200
        assert resp.data['data']['level_percentile'] == 100
        assert resp.data['data']['total_xp'] == 0
        assert resp.data['data']['level'] >= 1
        assert 'title' in resp.data['data']

    def test_percentile_with_points(self, auth_client, student_user):
        """有积分数据：正确计算百分位"""
        PointsTransaction.objects.create(
            student=student_user.student,
            amount=50.0, transaction_type='EARN', source='PRACTICE_REWARD',
        )
        resp = auth_client.get(reverse('user-level-percentile'))
        assert resp.status_code == 200
        assert resp.data['data']['total_xp'] == 50.0

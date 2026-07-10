"""PDF API 测试 — 请求签名 Token"""

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Student
from interactions.models import CustomPaper


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def student_user(db):
    user = User.objects.create_user('pdfstudent', password='test123')
    Student.objects.create(user=user, gaokao_year=2026)
    return user


@pytest.fixture
def auth_client(api_client, student_user):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(student_user)
    token = str(refresh.access_token)
    api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + token)
    return api_client


@pytest.fixture
def sample_paper(db, student_user):
    return CustomPaper.objects.create(
        student=student_user.student,
        title='测试试卷',
        is_public=True,
    )


class TestPdfRequestToken:
    """PDF 请求签名 Token 测试"""

    def test_request_token_own_paper(self, auth_client, sample_paper):
        """自己的试卷：成功返回 sig"""
        resp = auth_client.post(reverse('pdf-request-token'), {
            'source_id': sample_paper.pk,
            'source_type': 'paper',
        }, format='json')

        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert 'sig' in resp.data['data']
        assert resp.data['data']['expire_in'] == 300
        assert resp.data['data']['url'].startswith('/pdf/view')

    def test_request_token_no_source_id(self, auth_client):
        """缺少 source_id：40001"""
        resp = auth_client.post(reverse('pdf-request-token'), {
            'source_type': 'paper',
        }, format='json')

        assert resp.status_code == 400
        assert resp.data['code'] == 40001

    def test_request_token_unauthenticated(self, api_client):
        """未认证：401"""
        resp = api_client.post(reverse('pdf-request-token'), {
            'source_id': 1,
        }, format='json')

        assert resp.status_code == 401

    def test_sig_different_per_user(self, auth_client, sample_paper, db):
        """不同用户的 sig 不同"""
        resp1 = auth_client.post(reverse('pdf-request-token'), {
            'source_id': sample_paper.pk,
        }, format='json')

        # 创建另一个用户
        user2 = User.objects.create_user('pdfstudent2', password='test123')
        Student.objects.create(user=user2)

        client2 = APIClient()
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(user2)
        client2.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))

        resp2 = client2.post(reverse('pdf-request-token'), {
            'source_id': sample_paper.pk,
        }, format='json')

        assert resp1.data['data']['sig'] != resp2.data['data']['sig']

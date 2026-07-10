"""PDF API 测试 — 请求签名 Token + 视图权限验证"""
import time

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Student
from interactions.models import CustomPaper
from interactions.pdf_views import _make_sig, _check_sig


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


@pytest.fixture
def private_paper(db):
    user2 = User.objects.create_user('otheruser', password='test123')
    s2 = Student.objects.create(user=user2)
    return CustomPaper.objects.create(
        student=s2, title='私密试卷', is_public=False,
    )


class TestPdfRequestToken:
    """PDF 请求签名 Token 测试"""

    def test_request_token_own_paper(self, auth_client, sample_paper):
        resp = auth_client.post(reverse('pdf-request-token'), {
            'source_id': sample_paper.pk, 'source_type': 'paper',
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert 'sid' in resp.data['data']['url']
        assert 'exp' in resp.data['data']['url']

    def test_request_token_no_source_id(self, auth_client):
        resp = auth_client.post(reverse('pdf-request-token'), {
            'source_type': 'paper',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40201

    def test_request_token_unauthenticated(self, api_client):
        resp = api_client.post(reverse('pdf-request-token'), {
            'source_id': 1,
        }, format='json')
        assert resp.status_code == 401

    def test_sig_different_per_user(self, auth_client, sample_paper, db):
        resp1 = auth_client.post(reverse('pdf-request-token'), {
            'source_id': sample_paper.pk,
        }, format='json')
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

    def test_request_token_private_paper_denied(self, auth_client, private_paper):
        resp = auth_client.post(reverse('pdf-request-token'), {
            'source_id': private_paper.pk, 'source_type': 'paper',
        }, format='json')
        assert resp.status_code == 400
        assert resp.data['code'] == 40301

    def test_check_sig_ok(self):
        sig = _make_sig(1, 'paper', 42, 1000)
        assert _check_sig(sig, 1, 'paper', 42, 1000) is True

    def test_check_sig_wrong_key(self):
        sig = _make_sig(1, 'paper', 42, 1000)
        assert _check_sig(sig, 1, 'paper', 43, 1000) is False

    def test_check_sig_wrong_time(self):
        sig = _make_sig(1, 'paper', 42, 1000)
        assert _check_sig(sig, 1, 'paper', 42, 999) is False


class TestPdfView:
    """PDF 视图权限验证测试"""

    def _build_url(self, source_id, source_type, student_id, expire_offset=300):
        expire = int(time.time()) + expire_offset
        sig = _make_sig(source_id, source_type, student_id, expire)
        return '/pdf/view/?pid={0}&type={1}&sid={2}&exp={3}&sig={4}'.format(
            source_id, source_type, student_id, expire, sig)

    def test_view_expired_sig(self, api_client, student_user, settings):
        settings.ALLOWED_HOSTS = ["*"]
        url = self._build_url(1, 'paper', student_user.student.pk, expire_offset=-999)
        resp = api_client.get(url)
        assert resp.status_code == 403

    def test_view_invalid_sig(self, api_client, settings):
        settings.ALLOWED_HOSTS = ["*"]
        url = '/pdf/view/?pid=1&type=paper&sid=1&exp=100&sig=invalid'
        resp = api_client.get(url)
        assert resp.status_code == 403

    def test_view_missing_params(self, api_client, settings):
        settings.ALLOWED_HOSTS = ["*"]
        resp = api_client.get('/pdf/view/?pid=1')
        assert resp.status_code == 403

    def test_view_paper_not_found(self, api_client, student_user, settings):
        settings.ALLOWED_HOSTS = ["*"]
        url = self._build_url(99999, 'paper', student_user.student.pk)
        resp = api_client.get(url)
        assert resp.status_code == 404

"""PDF API 测试 — 请求签名 Token + 视图权限验证"""
import time

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Student
from interactions.models import CustomPaper
from interactions.models import CustomPaperQuestion
from interactions.pdf_views import (
    _check_sig,
    _content_warnings,
    _make_sig,
    _prepare_images,
)
from qbank.models import BaseQuestion, SolutionMethod, SolutionStep, SubQuestion


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
        assert resp.data['data']['expire_in'] == 1800

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

    def test_option_grid_image_is_marked_for_pdf_layout(self):
        images = _prepare_images([
            'mock1_2023_haidian_q08_options.webp',
            'mock1_2023_haidian_q10.webp',
        ])
        assert images == [
            {
                'path': 'mock1_2023_haidian_q08_options.webp',
                'is_option_grid': True,
            },
            {
                'path': 'mock1_2023_haidian_q10.webp',
                'is_option_grid': False,
            },
        ]

    def test_content_warnings_detect_suspicious_source(self):
        warnings = _content_warnings(r'计算 $x+1 并求', 8)
        assert '第 8 题可能存在未闭合的公式定界符' in warnings
        assert '第 8 题内容可能不完整' in warnings


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
        assert '打印链接已过期' in resp.content.decode()

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

    def test_view_renders_print_workspace(
        self, api_client, student_user, sample_paper, settings,
    ):
        settings.ALLOWED_HOSTS = ["*"]
        fill_question = BaseQuestion.objects.create(
            question_type='fill', stem='求 $1+1$ 的值。', default_score=5,
        )
        SubQuestion.objects.create(
            question=fill_question, answer='$2$', sort_order=1,
        )
        CustomPaperQuestion.objects.create(
            paper=sample_paper, question=fill_question, sort_order=1,
        )
        choice_question = BaseQuestion.objects.create(
            question_type='choice', stem='1+1=( )', default_score=5,
        )
        SubQuestion.objects.create(
            question=choice_question, answer='B', sort_order=1,
        )
        CustomPaperQuestion.objects.create(
            paper=sample_paper, question=choice_question, sort_order=2,
        )
        solution_question = BaseQuestion.objects.create(
            question_type='solution', stem='证明。', default_score=10,
        )
        solution_sub = SubQuestion.objects.create(
            question=solution_question,
            answer='$a=b$，结论成立。',
            explanation='由已知条件代入即可验证。',
            sort_order=1,
        )
        method = SolutionMethod.objects.create(
            sub_question=solution_sub,
            method_name='代数证明',
            sort_order=1,
        )
        SolutionStep.objects.create(
            method=method,
            step_number=1,
            title='整理条件',
            content='由已知条件得到 $a=b$。',
        )
        SolutionStep.objects.create(
            method=method,
            step_number=2,
            title='完成证明',
            content='代入原式，两边相等，所以结论成立。',
        )
        CustomPaperQuestion.objects.create(
            paper=sample_paper, question=solution_question, sort_order=3,
        )
        url = self._build_url(
            sample_paper.pk, 'paper', student_user.student.pk,
        )

        resp = api_client.get(url)

        assert resp.status_code == 200
        html = resp.content.decode()
        assert '试题版式' in html
        assert '输出内容' in html
        assert '打印设置' in html
        assert '自定义设置' in html
        assert '> 试题</label>' in html
        assert '> 作答纸</label>' in html
        assert '> 参考答案</label>' in html
        assert '> 详细解析</label>' in html
        assert '日常练习' in html
        assert '模拟考试' in html
        assert '教师参考' in html
        assert '核对答案' in html
        assert '卷内作答' in html
        assert '留出书写空间' in html
        assert '紧凑排版' in html
        assert '适合搭配作答纸' in html
        teacher_preset = (
            "teacher: {title: '教师参考', "
            "sections: ['questions', 'answers', 'details'], "
            "layout: 'standard'}"
        )
        assert teacher_preset in html
        assert "answers: {title: '核对答案', sections: ['answers'], layout: 'standard'}" in html
        assert '未输出试题，无需选择版式' in html
        assert 'settings-panel' in html
        assert 'progress-panel' not in html
        assert '打印 / 保存 PDF' in html
        assert '保存 PDF 指引' in html
        assert '本作答纸仅供练习和模拟使用' in html
        assert 'choice-sheet-table' in html
        assert 'fill-sheet-grid' in html
        assert 'solution-sheet-section' in html
        assert '参考答案' in html
        assert 'choice-answer-table' in html
        assert 'fill-answer-grid' in html
        assert '三、解答题答案' in html
        assert '$a=b$，结论成立。' in html
        assert '解答题详细解析' in html
        assert '整理条件' in html
        assert '由已知条件得到 $a=b$。' in html
        assert '完成证明' in html
        assert '代入原式，两边相等，所以结论成立。' in html
        assert 'body.compact .section-fill' in html
        assert 'body.compact .section-solution .question' in html
        assert 'body.compact { font-size:' not in html

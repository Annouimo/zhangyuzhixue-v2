"""讲义 API 测试 — 课程列表/章节目录/讲义内容"""
import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Teacher
from courses.models import Course, Document


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def teacher_user(db):
    user = User.objects.create_user('lecteacher', password='test123')
    Teacher.objects.create(user=user)
    return user


@pytest.fixture
def auth_client(api_client, teacher_user):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(teacher_user)
    api_client.credentials(HTTP_AUTHORIZATION='Bearer ' + str(refresh.access_token))
    return api_client


@pytest.fixture
def sample_course(db):
    return Course.objects.create(name='高三数学', description='高考冲刺')


@pytest.fixture
def sample_documents(db, sample_course):
    for i in range(3):
        Document.objects.create(
            course=sample_course,
            chapter=f'{i+1:02d}',
            title=f'第{i+1}讲 函数',
            md_content=f'# 第{i+1}讲\n\n这是第{i+1}讲的内容。',
        )


class TestLectureCourses:
    """课程列表 API 测试"""

    def test_teacher_sees_all_courses(self, auth_client, sample_course):
        """教师可见全部课程"""
        resp = auth_client.get(reverse('lecture-courses'))
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert len(resp.data['data']) >= 1
        assert resp.data['data'][0]['name'] == '高三数学'


class TestLectureChapters:
    """章节目录 API 测试"""

    def test_chapter_list(self, auth_client, sample_course, sample_documents):
        """指定课程的章节目录"""
        resp = auth_client.get(
            reverse('lecture-chapters', args=[sample_course.id])
        )
        assert resp.status_code == 200
        assert resp.data['data']['course_name'] == '高三数学'
        assert len(resp.data['data']['items']) == 3

    def test_chapter_list_empty(self, auth_client, sample_course):
        """无讲义的课程"""
        resp = auth_client.get(
            reverse('lecture-chapters', args=[sample_course.id])
        )
        assert resp.status_code == 200
        assert resp.data['data']['items'] == []


class TestLectureContent:
    """讲义内容 API 测试"""

    def test_content_returns_markdown(
            self, auth_client, sample_course, sample_documents):
        """讲义内容原样返回"""
        doc = Document.objects.first()
        resp = auth_client.get(
            reverse('lecture-content', args=[doc.id])
        )
        assert resp.status_code == 200
        assert resp.data['data']['md_content'] == doc.md_content
        assert resp.data['data']['chapter_id'] == doc.id

    def test_content_not_found(self, auth_client):
        """不存在的讲义：404"""
        resp = auth_client.get(
            reverse('lecture-content', args=[99999])
        )
        assert resp.status_code == 404

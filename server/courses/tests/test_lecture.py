"""讲义 API 测试 — 课程列表/章节目录/讲义内容"""
import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework.test import APIClient

from accounts.models import Student
from courses.models import (
    Course, Document, Video, VideoCategory, VideoDocumentLink,
)


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def student_user(db):
    user = User.objects.create_user('lecturestudent', password='test123')
    Student.objects.create(user=user)
    return user


@pytest.fixture
def auth_client(api_client, student_user):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(student_user)
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

    def test_plain_authenticated_user_is_denied(self, db, api_client):
        from rest_framework_simplejwt.tokens import RefreshToken
        user = User.objects.create_user('plainlecture', password='test123')
        token = RefreshToken.for_user(user).access_token
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = api_client.get(reverse('lecture-courses'))
        assert response.status_code == 403

    def test_authenticated_user_sees_all_courses(self, auth_client, sample_course):
        """讲义不再按班级或角色限制。"""
        resp = auth_client.get(reverse('lecture-courses'))
        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert sample_course.id in [item['id'] for item in resp.data['data']]


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

    def test_content_empty(self, auth_client, sample_course):
        """存在的讲义但内容为空：正常返回空字符串"""
        doc = Document.objects.create(
            course=sample_course, chapter='99', title='空内容', md_content='',
        )
        resp = auth_client.get(
            reverse('lecture-content', args=[doc.id])
        )
        assert resp.status_code == 200
        assert resp.data['data']['md_content'] == ''


@pytest.fixture
def sample_video(db, sample_course):
    category, _ = VideoCategory.objects.get_or_create(
        name='专题深度解析', defaults={'sort_order': 20},
    )
    document = Document.objects.create(
        course=sample_course, chapter='01', title='集合', md_content='# 集合',
    )
    video = Video.objects.create(
        category=category,
        title='集合为什么要分类讨论',
        description='用一个例子说清集合分类。',
        platform_name='B站',
        video_url='https://www.bilibili.com/video/BV1test',
        is_published=True,
    )
    VideoDocumentLink.objects.create(
        video=video,
        document=document,
        relation_label='配套讲解',
    )
    return video, document


class TestVideos:
    def test_catalog_only_returns_published_videos(
            self, auth_client, sample_video):
        video, _ = sample_video
        Video.objects.create(
            category=video.category,
            title='草稿',
            video_url='https://example.com/draft',
            is_published=False,
        )

        response = auth_client.get(reverse('video-list'))

        assert response.status_code == 200
        category = next(
            item for item in response.data['data']
            if item['id'] == video.category_id
        )
        items = category['videos']
        titles = [item['title'] for item in items]
        assert video.title in titles
        assert '草稿' not in titles

    def test_video_detail_contains_related_lecture(
            self, auth_client, sample_video):
        video, document = sample_video

        response = auth_client.get(reverse('video-detail', args=[video.id]))

        assert response.status_code == 200
        lecture = response.data['data']['related_lectures'][0]
        assert lecture['chapter_id'] == document.id
        assert lecture['relation_label'] == '配套讲解'

    def test_lecture_content_contains_related_video(
            self, auth_client, sample_video):
        video, document = sample_video

        response = auth_client.get(
            reverse('lecture-content', args=[document.id]),
        )

        related = response.data['data']['related_videos'][0]
        assert related['id'] == video.id
        assert related['relation_label'] == '配套讲解'

    def test_draft_video_detail_is_not_found(
            self, auth_client, sample_video):
        video, _ = sample_video
        video.is_published = False
        video.save(update_fields=['is_published'])

        response = auth_client.get(reverse('video-detail', args=[video.id]))

        assert response.status_code == 404

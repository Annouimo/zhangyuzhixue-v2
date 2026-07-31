from pathlib import Path

import pytest
from django.contrib.admin.sites import site
from django.contrib.auth.models import Group, User
from django.urls import reverse

from courses.models import Course, Document, Video, VideoCategory
from internal_portal.models import (
    BusinessArea,
    HandbookSection,
    HandbookUpdate,
    PortalEntry,
    ProjectProfile,
    TeamMember,
)
from qbank.models import BaseQuestion
from qbank.models import ContentChangeLog
from system.models import DbVersion


pytestmark = pytest.mark.django_db


@pytest.fixture
def portal_user():
    user = User.objects.create_user(username='team-test', password='test-pass-123')
    group, _ = Group.objects.get_or_create(name='internal_portal')
    user.groups.add(group)
    return user


def test_anonymous_user_is_sent_to_portal_login(client):
    response = client.get(reverse('internal_portal:index'))

    assert response.status_code == 302
    assert response.url.startswith(reverse('internal_portal:login'))


def test_regular_user_cannot_log_in_to_portal(client):
    User.objects.create_user(username='student-test', password='test-pass-123')

    response = client.post(reverse('internal_portal:login'), {
        'username': 'student-test',
        'password': 'test-pass-123',
    })

    assert response.status_code == 200
    assert '账号、密码或访问权限不正确' in response.content.decode()
    assert '_auth_user_id' not in client.session


def test_portal_group_user_can_log_in_and_view_pages(client, portal_user):
    response = client.post(reverse('internal_portal:login'), {
        'username': portal_user.username,
        'password': 'test-pass-123',
    })

    assert response.status_code == 302
    assert response.url == reverse('internal_portal:index')

    response = client.get(reverse('internal_portal:index'))
    assert response.status_code == 200
    content = response.content.decode()
    assert '项目工作手册' in content
    assert '章鱼智学软件' in content
    assert '圆明智学自媒体后期' in content
    assert '内部平台' in content
    assert '返回官网' in content
    assert '>工作手册</strong>' in content
    assert '>内容工作台</a>' not in content
    assert '>管理工作台</a>' not in content
    assert reverse('management_portal:home') not in content
    assert '>高级数据管理</a>' not in content
    assert reverse('admin:index') not in content

    response = client.get(
        reverse('internal_portal:page-detail', args=['software']),
    )
    assert response.status_code == 200
    assert '章鱼智学代码仓库' in response.content.decode()
    assert '题库结构' in response.content.decode()


def test_handbook_follows_system_dark_mode_and_busts_css_cache():
    root = Path(__file__).parents[1]
    stylesheet = (
        root / 'static' / 'internal_portal' / 'portal.css'
    ).read_text(encoding='utf-8')
    base = (
        root / 'templates' / 'internal_portal' / 'base.html'
    ).read_text(encoding='utf-8')
    login = (
        root / 'templates' / 'internal_portal' / 'login.html'
    ).read_text(encoding='utf-8')
    assert '@media (prefers-color-scheme: dark)' in stylesheet
    assert 'color-scheme: dark' in stylesheet
    assert "portal.css' %}?v=8" in base
    assert "portal.css' %}?v=8" in login


def test_logout_requires_post_and_ends_session(client, portal_user):
    client.force_login(portal_user)

    get_response = client.get(reverse('internal_portal:logout'))
    assert get_response.status_code == 302
    assert '_auth_user_id' in client.session

    post_response = client.post(reverse('internal_portal:logout'))
    assert post_response.status_code == 302
    assert '_auth_user_id' not in client.session


def test_lecture_library_is_read_only_and_requires_portal_access(
    client, portal_user,
):
    course = Course.objects.create(name='高考数学一轮复习', description='视频配套讲义')
    first = Document.objects.create(
        course=course, chapter='01', title='集合', md_content='# 集合',
    )
    second = Document.objects.create(
        course=course, chapter='02', title='逻辑', md_content='# 逻辑',
    )

    anonymous = client.get(reverse('internal_portal:lecture-library'))
    assert anonymous.status_code == 302
    assert anonymous.url.startswith(reverse('internal_portal:login'))

    client.force_login(portal_user)
    library = client.get(reverse('internal_portal:lecture-library'))
    assert library.status_code == 200
    assert '高考数学一轮复习' in library.content.decode()
    assert '2 讲' in library.content.decode()

    course_page = client.get(reverse(
        'internal_portal:lecture-course', args=[course.pk],
    ))
    content = course_page.content.decode()
    assert content.index('集合') < content.index('逻辑')

    document_page = client.get(reverse(
        'internal_portal:lecture-document', args=[first.pk],
    ))
    content = document_page.content.decode()
    assert document_page.status_code == 200
    assert '下一讲' in content
    assert second.title in content
    assert '编辑讲义' not in content


def test_lecture_reader_renders_markdown_math_and_separator_hints(
    client, portal_user,
):
    course = Course.objects.create(name='测试讲义')
    document = Document.objects.create(
        course=course, chapter='01', title='函数', md_content=(
            '# 函数\n\n已知 $f(x)=x^2$。\n\n'
            '<!-- pagebreak -->\n\n## 例题\n\n'
            '<!-- reveal -->\n\n<script>alert(1)</script>'
        ),
    )
    client.force_login(portal_user)

    response = client.get(reverse(
        'internal_portal:lecture-document', args=[document.pk],
    ))
    content = response.content.decode()
    assert '<h1>函数</h1>' in content
    assert '$f(x)=x^2$' in content
    assert 'katex/contrib/auto-render.min.js' in content
    assert '分页分隔' in content
    assert '此处在学生端开始新的一页' in content
    assert '内容分隔' in content
    assert '<script>alert(1)</script>' not in content
    assert '&lt;script&gt;alert(1)&lt;/script&gt;' in content


def test_video_operations_is_read_only_status_and_guidance(client, portal_user):
    category = VideoCategory.objects.create(name='课程视频')
    Video.objects.create(
        category=category, title='已上架视频',
        video_url='https://example.com/published', is_published=True,
    )
    draft = Video.objects.create(
        category=category, title='草稿视频',
        video_url='https://example.com/draft', is_published=False,
    )
    ContentChangeLog.objects.create(
        actor=portal_user, object_type='video', object_id=draft.pk,
        object_label=draft.title, action='create', note='建立草稿',
    )
    DbVersion.objects.create(
        db_type='courses', schema_version=1, data_version=9,
    )
    client.force_login(portal_user)

    response = client.get(reverse('internal_portal:video-operations'))
    content = response.content.decode()
    assert response.status_code == 200
    assert '视频运营与发布' in content
    assert '已上架' in content and '草稿' in content
    assert 'v9' in content
    assert '链接与封面规范' in content
    assert '建立草稿' in content
    assert reverse('review_workbench:video_list') in content
    assert '保存草稿' not in content
    assert '>上架</button>' not in content


def test_initial_portal_data_excludes_teacher_product():
    names = PortalEntry.objects.values_list('name', flat=True)
    assert names.exists()
    assert not any('教师' in name for name in names)


def test_current_portal_documents_use_current_gitee_paths():
    document_entries = PortalEntry.objects.filter(entry_type='document')

    assert not document_entries.filter(name='系统架构').exists()
    assert not document_entries.filter(name='项目文档索引').exists()
    assert not document_entries.filter(url__contains='/docs/01-').exists()
    assert not document_entries.filter(url__contains='/docs/03-').exists()
    assert not document_entries.filter(url__contains='/docs/07-').exists()


def test_student_downloads_use_current_release():
    release_root = (
        'https://gitee.com/annouimo/zhangyuzhixue-v2/'
        'releases/download/v1.2.0-beta.1/'
    )

    android = PortalEntry.objects.get(name='学生端 Android')
    windows = PortalEntry.objects.get(name='学生端 Windows')

    assert android.url == f'{release_root}app-release.apk'
    assert windows.url == (
        f'{release_root}%E7%AB%A0%E9%B1%BC%E6%99%BA%E5%AD%A6-'
        '1.2.0-beta.1-windows.exe'
    )


def test_portal_models_are_available_in_admin():
    assert ProjectProfile in site._registry
    assert TeamMember in site._registry
    assert BusinessArea in site._registry
    assert HandbookSection in site._registry
    assert HandbookUpdate in site._registry
    assert PortalEntry in site._registry


def test_handbook_pages_follow_the_confirmed_structure(client, portal_user):
    client.force_login(portal_user)

    pages = list(
        BusinessArea.objects.order_by('sort_order').values_list('slug', flat=True)
    )
    assert pages == ['overview', 'software', 'website', 'content', 'post-production']
    assert set(
        HandbookSection.objects.values_list('display_type', flat=True)
    ) >= {
        HandbookSection.DisplayType.TEXT,
        HandbookSection.DisplayType.ENTRIES,
        HandbookSection.DisplayType.PROJECT_MAP,
        HandbookSection.DisplayType.CHANGELOG,
        HandbookSection.DisplayType.TREE,
        HandbookSection.DisplayType.QUESTION_STATS,
    }
    assert not PortalEntry.objects.filter(key='').exists()
    assert PortalEntry.objects.count() == PortalEntry.objects.values(
        'area', 'key',
    ).distinct().count()
    content = BusinessArea.objects.get(slug='content')
    content_types = HandbookSection.objects.get(
        page=content, slug='directions',
    )
    assert list(
        content_types.entries.values_list('name', flat=True)
    ) == [
        '系列系统课程', '专题深度解析', '学习经验分享', '学术交流',
        '章鱼智学数字资产库',
    ]

    post_response = client.get(
        reverse('internal_portal:page-detail', args=['post-production']),
    )
    assert post_response.status_code == 200
    assert '圆明智学自媒体后期' in post_response.content.decode()


def test_question_overview_excludes_test_questions(client, portal_user):
    BaseQuestion.objects.create(question_type='choice', stem='正式题')
    BaseQuestion.objects.create(question_type='fill', stem='测试题', year=2099)
    client.force_login(portal_user)

    response = client.get(
        reverse('internal_portal:page-detail', args=['software']),
    )
    content = response.content.decode()

    assert response.status_code == 200
    assert '题目总数' in content
    assert '选择题' in content


def test_changelog_is_curated_and_entries_are_grouped_by_meaning(
    client, portal_user,
):
    client.force_login(portal_user)

    index_response = client.get(reverse('internal_portal:index'))
    index_content = index_response.content.decode()
    assert '新增只读讲义库并统一内部导航' in index_content
    assert '重构项目工作手册' in index_content
    assert '完善自媒体视频工作分类' in index_content
    assert HandbookUpdate.objects.count() == 3
    assert 'update-list' in index_content
    assert 'changelog-table' not in index_content

    software = BusinessArea.objects.get(slug='software')
    groups = {
        section.title: set(section.entries.values_list('name', flat=True))
        for section in software.sections.all()
        if section.entries.exists()
    }
    assert groups['软件版本与下载'] == {
        '学生端 Android', '学生端 Windows', '学生端 iOS', '章鱼智学代码仓库',
    }

    website = BusinessArea.objects.get(slug='website')
    policies = HandbookSection.objects.get(page=website, title='协议与政策')
    assert set(policies.entries.values_list('name', flat=True)) == {
        '隐私政策', '用户协议',
    }

    response = client.get(
        reverse('internal_portal:page-detail', args=['software']),
    )
    content = response.content.decode()
    assert '章鱼智学代码仓库' in content


def test_media_pages_explain_content_and_post_production(client, portal_user):
    client.force_login(portal_user)

    response = client.get(
        reverse('internal_portal:page-detail', args=['content']),
    )
    content = response.content.decode()
    assert response.status_code == 200
    assert '视频内容类型' in content
    assert '系列系统课程' in content
    assert '专题深度解析' in content
    assert '学习经验分享' in content
    assert '内容制作' not in content
    assert '视频类型与视觉呈现' not in content
    assert '章鱼智学数字资产库' in content
    assert '当前负责人' not in content

    response = client.get(
        reverse('internal_portal:page-detail', args=['post-production']),
    )
    post_content = response.content.decode()
    assert response.status_code == 200
    assert '后期制作' in post_content
    assert '素材统筹' in post_content
    assert '剪辑与包装' in post_content
    assert '音画调整' in post_content
    assert '成片输出' in post_content
    assert '视频运营与发布' in post_content

    update = HandbookUpdate.objects.get(title='完善自媒体视频工作分类')
    assert update.description == (
        '明确四类视频内容，区分内容制作与后期制作，补充各类'
        '视频的视觉呈现方式。'
    )


@pytest.mark.parametrize('old_slug', ['product', 'technology'])
def test_legacy_page_urls_redirect_to_software(client, portal_user, old_slug):
    client.force_login(portal_user)

    response = client.get(
        reverse('internal_portal:page-detail', args=[old_slug]),
    )

    assert response.status_code == 301
    assert response.url == reverse(
        'internal_portal:page-detail', args=['software'],
    )

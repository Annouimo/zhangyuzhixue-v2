from pathlib import Path

import pytest
from django.contrib.admin.sites import site
from django.contrib.auth.models import Group, User
from django.urls import reverse

from internal_portal.models import (
    BusinessArea,
    HandbookSection,
    HandbookUpdate,
    PortalEntry,
    ProjectProfile,
    TeamMember,
)
from qbank.models import BaseQuestion


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
    assert '项目工作手册' in response.content.decode()
    assert '章鱼智学软件' in response.content.decode()
    assert '圆明智学自媒体后期' in response.content.decode()

    response = client.get(
        reverse('internal_portal:page-detail', args=['software']),
    )
    assert response.status_code == 200
    assert 'Gitee 主仓库' in response.content.decode()
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
    assert "portal.css' %}?v=5" in base
    assert "portal.css' %}?v=5" in login


def test_logout_requires_post_and_ends_session(client, portal_user):
    client.force_login(portal_user)

    get_response = client.get(reverse('internal_portal:logout'))
    assert get_response.status_code == 302
    assert '_auth_user_id' in client.session

    post_response = client.post(reverse('internal_portal:logout'))
    assert post_response.status_code == 302
    assert '_auth_user_id' not in client.session


def test_initial_portal_data_excludes_teacher_product():
    names = PortalEntry.objects.values_list('name', flat=True)
    assert names.exists()
    assert not any('教师' in name for name in names)


def test_current_portal_documents_use_current_gitee_paths():
    document_entries = PortalEntry.objects.filter(entry_type='document')

    assert document_entries.filter(name='系统架构').exists()
    assert document_entries.filter(name='项目文档索引').exists()
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
    assert '重构项目工作手册' in index_content
    assert '完善自媒体视频工作分类' in index_content
    assert HandbookUpdate.objects.count() == 2
    assert 'update-list' in index_content
    assert 'changelog-table' not in index_content

    software = BusinessArea.objects.get(slug='software')
    groups = {
        section.title: set(section.entries.values_list('name', flat=True))
        for section in software.sections.all()
        if section.entries.exists()
    }
    assert groups['产品与系统资料'] == {'产品边界', '系统架构', '数据架构'}
    assert groups['开发与运维资料'] == {
        '开发与测试', '发布与运维', '项目文档索引', '仓库地图',
    }
    assert groups['技术与管理入口'] == {
        'Gitee 主仓库', 'API 文档', 'Django 管理后台',
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
    assert content.index('产品与系统资料') < content.index('开发与运维资料')


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
    assert '内容制作' in content
    assert '视觉内容' in content
    assert '可视化是视觉内容的一种实现形式' in content
    assert '视频类型与视觉呈现' in content
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

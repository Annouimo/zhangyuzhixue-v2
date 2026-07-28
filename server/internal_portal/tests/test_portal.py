import pytest
from django.contrib.admin.sites import site
from django.contrib.auth.models import Group, User
from django.urls import reverse

from internal_portal.models import (
    BusinessArea,
    PortalEntry,
    ProjectProfile,
    TeamMember,
)


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
    assert '章鱼智学项目中心' in response.content.decode()

    response = client.get(
        reverse('internal_portal:area-detail', args=['technology']),
    )
    assert response.status_code == 200
    assert 'Gitee 主仓库' in response.content.decode()


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


def test_portal_models_are_available_in_admin():
    assert ProjectProfile in site._registry
    assert TeamMember in site._registry
    assert BusinessArea in site._registry
    assert PortalEntry in site._registry

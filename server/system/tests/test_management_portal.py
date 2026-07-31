from datetime import timedelta

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone

from accounts.models import AccountDeletionRequest, Student
from accounts.roles import (
    ACCESS_LEVEL_HANDBOOK,
    ACCESS_LEVEL_REVIEWER,
    ACCESS_LEVEL_SUPERUSER,
    CONTENT_REVIEWER_GROUP,
    INTERNAL_PORTAL_GROUP,
    get_access_level,
)
from system.models import PointsTransaction


@pytest.fixture
def admin_user(db):
    return User.objects.create_superuser(
        username='portal-admin', password='test-password-123', email='',
    )


@pytest.fixture
def plain_user(db):
    return User.objects.create_user(
        username='plain-user', password='test-password-123',
        first_name='普通用户',
    )


@pytest.fixture
def student_user(db):
    user = User.objects.create_user(
        username='student-user', password='test-password-123',
        first_name='测试学生',
    )
    student = user.student
    student.phone = '13800138000'
    student.school = '测试中学'
    student.gaokao_year = 2027
    student.save(update_fields=['phone', 'school', 'gaokao_year', 'updated_at'])
    return user, student


def test_management_home_requires_staff(client, plain_user):
    response = client.get(reverse('management_portal:home'))
    assert response.status_code == 302
    client.force_login(plain_user)
    response = client.get(reverse('management_portal:home'))
    assert response.status_code == 302
    assert '/admin/login/' in response.url


def test_management_home_and_user_list_render(client, admin_user, student_user):
    client.force_login(admin_user)
    response = client.get(reverse('management_portal:home'))
    assert response.status_code == 200
    content = response.content.decode()
    assert '管理首页' in content
    assert 'aria-label="内部工作台切换"' in content
    assert '>管理工作台</strong>' in content
    assert '>内容工作台</strong>' in content
    assert '>工作手册</strong>' in content
    assert '>高级数据管理</a>' in content
    response = client.get(reverse('management_portal:user_list'), {'q': '测试学生'})
    assert response.status_code == 200
    assert 'student-user' in response.content.decode()


def test_access_level_service_keeps_group_hierarchy(client, admin_user, plain_user):
    client.force_login(admin_user)
    url = reverse('management_portal:user_detail', args=[plain_user.pk])
    response = client.post(url, {'action': 'save_access_level', 'access_level': 'reviewer'})
    assert response.status_code == 302
    plain_user.refresh_from_db()
    assert get_access_level(plain_user) == ACCESS_LEVEL_REVIEWER
    assert plain_user.groups.filter(name=CONTENT_REVIEWER_GROUP).exists()
    assert plain_user.groups.filter(name=INTERNAL_PORTAL_GROUP).exists()
    client.post(url, {'action': 'save_access_level', 'access_level': 'handbook'})
    plain_user.refresh_from_db()
    assert get_access_level(plain_user) == ACCESS_LEVEL_HANDBOOK
    assert plain_user.groups.filter(name=INTERNAL_PORTAL_GROUP).exists()
    assert plain_user.groups.filter(name=CONTENT_REVIEWER_GROUP).exists() is False
    client.post(url, {'action': 'save_access_level', 'access_level': 'regular'})
    plain_user.refresh_from_db()
    assert plain_user.groups.filter(name=INTERNAL_PORTAL_GROUP).exists() is False


def test_superuser_is_shown_as_separate_access_level(client, admin_user):
    client.force_login(admin_user)
    response = client.get(reverse('management_portal:user_detail', args=[admin_user.pk]))
    assert response.status_code == 200
    assert get_access_level(admin_user) == ACCESS_LEVEL_SUPERUSER
    assert '系统超级用户' in response.content.decode()


def test_profile_and_points_adjustment_update_related_state(
    client, admin_user, student_user,
):
    user, student = student_user
    client.force_login(admin_user)
    url = reverse('management_portal:user_detail', args=[user.pk])
    response = client.post(url, {
        'action': 'save_profile', 'real_name': '新姓名',
        'phone': '13900139000', 'school': '新学校', 'gaokao_year': '2028',
    })
    assert response.status_code == 302
    user.refresh_from_db()
    student.refresh_from_db()
    assert user.first_name == '新姓名'
    assert student.phone == '13900139000'
    assert student.school == '新学校'
    assert student.gaokao_year == 2028

    client.post(url, {
        'action': 'adjust_points', 'amount': '-5.0', 'description': '纠正误发',
    })
    student.refresh_from_db()
    entry = PointsTransaction.objects.get(student=student)
    assert entry.amount == -5.0
    assert entry.transaction_type == 'SPEND'
    assert entry.source == 'ADMIN_ADJUST'
    assert student.data_version == 1


def test_superuser_cannot_be_disabled(client, admin_user):
    client.force_login(admin_user)
    response = client.post(
        reverse('management_portal:user_detail', args=[admin_user.pk]),
        {'action': 'toggle_active'}, follow=True,
    )
    admin_user.refresh_from_db()
    assert admin_user.is_active is True
    assert '不能在管理工作台停用系统超级用户' in response.content.decode()


def test_admin_can_cancel_pending_deletion(
    client, admin_user, student_user,
):
    user, student = student_user
    user.is_active = False
    user.save(update_fields=['is_active'])
    student.account_status = Student.AccountStatus.PENDING_DELETION
    student.save(update_fields=['account_status'])
    deletion = AccountDeletionRequest.objects.create(
        user=user, requested_at=timezone.now(),
        scheduled_for=timezone.now() + timedelta(days=3),
    )

    client.force_login(admin_user)
    response = client.post(reverse('management_portal:deletion_list'), {
        'request_id': deletion.pk,
    })
    assert response.status_code == 302
    user.refresh_from_db()
    student.refresh_from_db()
    deletion.refresh_from_db()
    assert user.is_active is True
    assert student.account_status == Student.AccountStatus.ACTIVE
    assert deletion.status == AccountDeletionRequest.Status.CANCELLED


def test_legacy_admin_tool_routes_are_gone(client, admin_user):
    client.force_login(admin_user)
    assert client.get('/admin/system/tools/').status_code == 404
    assert client.get('/admin/system/help/').status_code == 404

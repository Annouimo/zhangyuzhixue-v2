from datetime import timedelta

import pytest
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import Student
from system.models import Announcement, StudentNotification
from system.notification_service import NotificationService


@pytest.fixture
def students(db):
    first_user = User.objects.create_user('notice-first', password='test-pass-123')
    second_user = User.objects.create_user('notice-second', password='test-pass-123')
    return Student.objects.create(user=first_user), Student.objects.create(user=second_user)


@pytest.fixture
def authenticated_client(students):
    client = APIClient()
    client.force_authenticate(students[0].user)
    return client


def create_notification(student, event_key='event:1', **overrides):
    values = {
        'category': StudentNotification.Category.SYSTEM,
        'title': '测试通知',
        'content': '通知正文',
    }
    values.update(overrides)
    return StudentNotification.objects.create(
        student=student, event_key=event_key, **values,
    )


def test_list_requires_authentication(db):
    response = APIClient().get(reverse('student-notification-list'))
    assert response.status_code in (401, 403)


def test_list_only_returns_current_students_unexpired_notifications(
    authenticated_client, students,
):
    own = create_notification(students[0])
    create_notification(students[1], event_key='other:1')
    create_notification(
        students[0], event_key='expired:1',
        expires_at=timezone.now() - timedelta(minutes=1),
    )

    response = authenticated_client.get(reverse('student-notification-list'))

    assert response.status_code == 200
    assert [item['id'] for item in response.data['data']['items']] == [own.id]


def test_unread_filter_count_and_read_operations(authenticated_client, students):
    unread = create_notification(students[0])
    create_notification(
        students[0], event_key='read:1', read_at=timezone.now(),
    )

    count_response = authenticated_client.get(
        reverse('student-notification-unread-count'),
    )
    assert count_response.data['data']['count'] == 1

    list_response = authenticated_client.get(
        reverse('student-notification-list'), {'status': 'unread'},
    )
    assert [item['id'] for item in list_response.data['data']['items']] == [unread.id]

    read_response = authenticated_client.post(
        reverse('student-notification-read', args=[unread.id]),
    )
    assert read_response.status_code == 200
    unread.refresh_from_db()
    assert unread.read_at is not None

    another = create_notification(students[0], event_key='event:2')
    all_response = authenticated_client.post(
        reverse('student-notification-read-all'),
    )
    assert all_response.data['data']['updated'] == 1
    another.refresh_from_db()
    assert another.read_at is not None


def test_cannot_mark_another_students_notification_read(
    authenticated_client, students,
):
    other = create_notification(students[1], event_key='other:1')
    response = authenticated_client.post(
        reverse('student-notification-read', args=[other.id]),
    )
    assert response.status_code == 404
    other.refresh_from_db()
    assert other.read_at is None


def test_cursor_pagination_has_no_duplicates(authenticated_client, students):
    for index in range(3):
        create_notification(students[0], event_key=f'event:{index}')

    first = authenticated_client.get(
        reverse('student-notification-list'), {'page_size': 2},
    ).data['data']
    second = authenticated_client.get(
        reverse('student-notification-list'),
        {'page_size': 2, 'cursor': first['next_cursor']},
    ).data['data']

    first_ids = {item['id'] for item in first['items']}
    second_ids = {item['id'] for item in second['items']}
    assert len(first_ids) == 2
    assert len(second_ids) == 1
    assert first_ids.isdisjoint(second_ids)


def test_notification_service_is_idempotent(students):
    kwargs = {
        'student': students[0],
        'event_key': 'contribution:4:needs_revision:1',
        'category': StudentNotification.Category.CONTRIBUTION,
        'title': '投稿需要修改',
    }
    first, first_created = NotificationService.notify(**kwargs)
    second, second_created = NotificationService.notify(**kwargs)

    assert first_created is True
    assert second_created is False
    assert first.id == second.id
    assert StudentNotification.objects.count() == 1


def test_active_announcement_is_materialized_once(authenticated_client, students):
    announcement = Announcement.objects.create(
        title='维护公告',
        content='今晚系统维护',
        priority='important',
        publish_at=timezone.now() - timedelta(minutes=1),
    )

    first = authenticated_client.get(reverse('student-notification-list'))
    second = authenticated_client.get(reverse('student-notification-list'))

    assert first.data['data']['items'][0]['title'] == '维护公告'
    assert first.data['data']['items'][0]['priority'] == 'important'
    assert second.status_code == 200
    assert StudentNotification.objects.filter(
        student=students[0], announcement=announcement,
    ).count() == 1


def test_inactive_future_and_expired_announcements_are_hidden(
    authenticated_client, students,
):
    now = timezone.now()
    inactive = Announcement.objects.create(
        title='已停用', content='', is_active=False,
    )
    Announcement.objects.create(
        title='尚未发布', content='', publish_at=now + timedelta(hours=1),
    )
    Announcement.objects.create(
        title='已经过期', content='', expires_at=now - timedelta(minutes=1),
    )
    create_notification(
        students[0],
        event_key=f'announcement:{inactive.id}',
        announcement=inactive,
    )

    response = authenticated_client.get(reverse('student-notification-list'))

    assert response.data['data']['items'] == []

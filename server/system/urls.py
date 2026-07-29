from django.urls import path

from interactions.sync_views import pull_user_db
from interactions.views import SyncPushView
from system.notification_views import (
    NotificationListView,
    NotificationReadAllView,
    NotificationReadView,
    NotificationUnreadCountView,
)
from system.views import UserVersionCheckView, VersionCheckView

urlpatterns = [
    path(
        'notifications/',
        NotificationListView.as_view(),
        name='student-notification-list',
    ),
    path(
        'notifications/unread-count/',
        NotificationUnreadCountView.as_view(),
        name='student-notification-unread-count',
    ),
    path(
        'notifications/read-all/',
        NotificationReadAllView.as_view(),
        name='student-notification-read-all',
    ),
    path(
        'notifications/<int:notification_id>/read/',
        NotificationReadView.as_view(),
        name='student-notification-read',
    ),
    path(
        'qbank/version/',
        VersionCheckView.as_view(),
        {'db_type': 'qbank'},
        name='sync-qbank-version',
    ),
    path(
        'courses/version/',
        VersionCheckView.as_view(),
        {'db_type': 'courses'},
        name='sync-courses-version',
    ),
    path('push/', SyncPushView.as_view(), name='sync-push'),
    path('user/pull/', pull_user_db, name='sync-user-pull'),
    path(
        'user/version/',
        UserVersionCheckView.as_view(),
        name='sync-user-version',
    ),
]

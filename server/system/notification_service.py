from django.db.models import Q
from django.utils import timezone

from system.models import Announcement, StudentNotification


class NotificationService:
    """Single entry point for idempotent student notification creation."""

    @staticmethod
    def notify(
        *, student, event_key, category, title, content='',
        priority=StudentNotification.Priority.NORMAL,
        action_type=StudentNotification.ActionType.NONE,
        action_target='', payload=None, expires_at=None, announcement=None,
    ):
        notification, created = StudentNotification.objects.get_or_create(
            student=student,
            event_key=event_key,
            defaults={
                'category': category,
                'title': title,
                'content': content,
                'priority': priority,
                'action_type': action_type,
                'action_target': action_target,
                'payload': payload or {},
                'expires_at': expires_at,
                'announcement': announcement,
            },
        )
        return notification, created

    @staticmethod
    def materialize_active_announcements(student):
        now = timezone.now()
        announcements = Announcement.objects.filter(is_active=True).filter(
            Q(publish_at__isnull=True) | Q(publish_at__lte=now),
        ).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gt=now),
        )
        for announcement in announcements:
            NotificationService.notify(
                student=student,
                event_key=f'announcement:{announcement.pk}',
                category=StudentNotification.Category.SYSTEM,
                title=announcement.title,
                content=announcement.content,
                priority=announcement.priority,
                expires_at=announcement.expires_at,
                announcement=announcement,
            )

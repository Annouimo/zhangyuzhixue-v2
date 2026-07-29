from django.db.models import Q
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from system.models import StudentNotification
from system.notification_service import NotificationService


def _student_for(request):
    return getattr(request.user, 'student', None)


def _visible_notifications(student):
    now = timezone.now()
    return StudentNotification.objects.filter(student=student).filter(
        Q(expires_at__isnull=True) | Q(expires_at__gt=now),
    ).filter(
        Q(announcement__isnull=True) | Q(announcement__is_active=True),
    )


def _serialize(item):
    return {
        'id': item.id,
        'category': item.category,
        'title': item.title,
        'content': item.content,
        'priority': item.priority,
        'action_type': item.action_type,
        'action_target': item.action_target,
        'payload': item.payload,
        'created_at': item.created_at.isoformat(),
        'read_at': item.read_at.isoformat() if item.read_at else None,
    }


class NotificationListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        student = _student_for(request)
        if student is None:
            return Response(
                {'code': 40003, 'message': '仅学生可查询', 'data': None},
                status=status.HTTP_403_FORBIDDEN,
            )
        NotificationService.materialize_active_announcements(student)
        queryset = _visible_notifications(student)
        if request.query_params.get('status') == 'unread':
            queryset = queryset.filter(read_at__isnull=True)
        category = request.query_params.get('category')
        valid_categories = {value for value, _ in StudentNotification.Category.choices}
        if category in valid_categories:
            queryset = queryset.filter(category=category)

        try:
            page_size = min(max(int(request.query_params.get('page_size', 20)), 1), 50)
        except (TypeError, ValueError):
            page_size = 20
        cursor = request.query_params.get('cursor')
        if cursor:
            try:
                queryset = queryset.filter(id__lt=int(cursor))
            except ValueError:
                pass
        items = list(queryset[:page_size + 1])
        has_more = len(items) > page_size
        items = items[:page_size]
        return Response({
            'code': 0,
            'message': 'ok',
            'data': {
                'items': [_serialize(item) for item in items],
                'next_cursor': str(items[-1].id) if has_more and items else None,
            },
        })


class NotificationUnreadCountView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        student = _student_for(request)
        if student is None:
            return Response(
                {'code': 40003, 'message': '仅学生可查询', 'data': None},
                status=status.HTTP_403_FORBIDDEN,
            )
        NotificationService.materialize_active_announcements(student)
        count = _visible_notifications(student).filter(read_at__isnull=True).count()
        return Response({'code': 0, 'message': 'ok', 'data': {'count': count}})


class NotificationReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, notification_id):
        student = _student_for(request)
        if student is None:
            return Response(
                {'code': 40003, 'message': '仅学生可操作', 'data': None},
                status=status.HTTP_403_FORBIDDEN,
            )
        updated = _visible_notifications(student).filter(
            id=notification_id, read_at__isnull=True,
        ).update(read_at=timezone.now())
        if not updated and not _visible_notifications(student).filter(id=notification_id).exists():
            return Response(
                {'code': 40401, 'message': '通知不存在', 'data': None},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response({'code': 0, 'message': 'ok', 'data': None})


class NotificationReadAllView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        student = _student_for(request)
        if student is None:
            return Response(
                {'code': 40003, 'message': '仅学生可操作', 'data': None},
                status=status.HTTP_403_FORBIDDEN,
            )
        updated = _visible_notifications(student).filter(
            read_at__isnull=True,
        ).update(read_at=timezone.now())
        return Response({'code': 0, 'message': 'ok', 'data': {'updated': updated}})

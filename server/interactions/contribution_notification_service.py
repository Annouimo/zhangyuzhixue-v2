from functools import partial

from django.db import transaction

from system.models import StudentNotification
from system.notification_service import NotificationService

from .models import ContentContribution


_STATUS_COPY = {
    ContentContribution.Status.NEEDS_REVISION: (
        '投稿需要修改',
        '审核员提出了修改意见，请查看并完善投稿。',
        'contribution_edit',
    ),
    ContentContribution.Status.APPROVED_PENDING_RELEASE: (
        '投稿已通过审核',
        '你的投稿已通过审核，正在等待题库发布。',
        'contribution_detail',
    ),
    ContentContribution.Status.COMPLETED: (
        '投稿已发布',
        '你的投稿已经发布到题库。',
        'contribution_detail',
    ),
    ContentContribution.Status.REJECTED: (
        '投稿未被采纳',
        '审核已完成，请查看审核意见。',
        'contribution_detail',
    ),
}


def schedule_contribution_notification(contribution, *, event_suffix=''):
    """Create the notification only after the surrounding transaction commits."""
    copy = _STATUS_COPY.get(contribution.status)
    if copy is None:
        return
    revision_number = (
        contribution.revisions.order_by('-revision_number')
        .values_list('revision_number', flat=True)
        .first()
        or 0
    )
    title, content, target = copy
    if contribution.review_note:
        content = f'{content} 审核意见：{contribution.review_note}'
    suffix = f':{event_suffix}' if event_suffix else ''
    notify = partial(
        NotificationService.notify,
        student=contribution.student,
        event_key=(
            f'contribution:{contribution.pk}:status:{contribution.status}:'
            f'revision:{revision_number}{suffix}'
        ),
        category=StudentNotification.Category.CONTRIBUTION,
        title=title,
        content=content,
        priority=StudentNotification.Priority.IMPORTANT,
        action_type=StudentNotification.ActionType.ROUTE,
        action_target=target,
        payload={'id': contribution.pk},
    )
    transaction.on_commit(notify)

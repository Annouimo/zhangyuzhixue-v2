import pytest
from django.contrib.auth.models import User
from django.db import transaction

from accounts.models import Student
from interactions.contribution_notification_service import (
    schedule_contribution_notification,
)
from interactions.models import ContentContribution, ContributionRevision
from system.models import StudentNotification


@pytest.fixture
def contribution(db):
    user = User.objects.create_user(
        'notification-author', password='test-pass-123',
    )
    student = Student.objects.create(user=user)
    item = ContentContribution.objects.create(
        student=student,
        contribution_type=ContentContribution.ContributionType.NEW_QUESTION,
    )
    ContributionRevision.objects.create(
        contribution=item,
        revision_number=1,
        normalized_payload={},
    )
    return item


@pytest.mark.django_db(transaction=True)
def test_notification_is_created_after_commit(contribution):
    with transaction.atomic():
        contribution.status = ContentContribution.Status.NEEDS_REVISION
        contribution.review_note = '请补充验算过程'
        contribution.save()
        schedule_contribution_notification(contribution)
        assert StudentNotification.objects.count() == 0

    notification = StudentNotification.objects.get()
    assert notification.title == '投稿需要修改'
    assert notification.priority == StudentNotification.Priority.IMPORTANT
    assert notification.action_target == 'contribution_edit'
    assert notification.payload == {'id': contribution.id}
    assert '请补充验算过程' in notification.content


@pytest.mark.django_db(transaction=True)
def test_rolled_back_review_does_not_create_notification(contribution):
    with pytest.raises(RuntimeError):
        with transaction.atomic():
            contribution.status = ContentContribution.Status.REJECTED
            contribution.save()
            schedule_contribution_notification(contribution)
            raise RuntimeError('rollback')

    assert StudentNotification.objects.count() == 0


@pytest.mark.django_db(transaction=True)
def test_repeated_scheduling_is_idempotent(contribution):
    contribution.status = ContentContribution.Status.COMPLETED
    contribution.save()
    schedule_contribution_notification(contribution, event_suffix='qbank:12')
    schedule_contribution_notification(contribution, event_suffix='qbank:12')

    assert StudentNotification.objects.count() == 1

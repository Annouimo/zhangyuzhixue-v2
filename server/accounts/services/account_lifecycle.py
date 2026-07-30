from datetime import timedelta
from pathlib import Path
from uuid import uuid4

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from accounts.models import AccountDeletionRequest, Student


DELETION_COOLDOWN_DAYS = 7


class AccountLifecycleError(Exception):
    pass


@transaction.atomic
def request_account_deletion(user, current_password):
    locked_user = type(user).objects.select_for_update().get(pk=user.pk)
    if not locked_user.check_password(current_password):
        raise AccountLifecycleError('当前密码错误')
    if not hasattr(locked_user, 'student'):
        raise AccountLifecycleError('仅学生账号支持此操作')

    student = Student.objects.select_for_update().get(user=locked_user)
    existing = AccountDeletionRequest.objects.filter(user=locked_user).first()
    if existing and existing.status == AccountDeletionRequest.Status.PENDING:
        return existing
    if student.account_status == Student.AccountStatus.ANONYMIZED:
        raise AccountLifecycleError('账号已完成匿名化')

    now = timezone.now()
    deletion_request, _ = AccountDeletionRequest.objects.update_or_create(
        user=locked_user,
        defaults={
            'status': AccountDeletionRequest.Status.PENDING,
            'requested_at': now,
            'scheduled_for': now + timedelta(days=DELETION_COOLDOWN_DAYS),
            'cancelled_at': None,
            'anonymized_at': None,
        },
    )
    student.account_status = Student.AccountStatus.PENDING_DELETION
    student.save(update_fields=['account_status', 'updated_at'])
    locked_user.is_active = False
    locked_user.save(update_fields=['is_active'])
    return deletion_request


@transaction.atomic
def cancel_account_deletion(username, password):
    from django.contrib.auth.models import User

    try:
        user = User.objects.select_for_update().get(username=username)
    except User.DoesNotExist as exc:
        raise AccountLifecycleError('用户名或密码错误') from exc
    if not user.check_password(password):
        raise AccountLifecycleError('用户名或密码错误')

    try:
        deletion_request = AccountDeletionRequest.objects.select_for_update().get(
            user=user,
            status=AccountDeletionRequest.Status.PENDING,
        )
    except AccountDeletionRequest.DoesNotExist as exc:
        raise AccountLifecycleError('没有可撤销的注销申请') from exc
    if deletion_request.scheduled_for <= timezone.now():
        raise AccountLifecycleError('冷静期已结束，无法撤销')

    student = Student.objects.select_for_update().get(user=user)
    student.account_status = Student.AccountStatus.ACTIVE
    student.save(update_fields=['account_status', 'updated_at'])
    user.is_active = True
    user.save(update_fields=['is_active'])
    deletion_request.status = AccountDeletionRequest.Status.CANCELLED
    deletion_request.cancelled_at = timezone.now()
    deletion_request.save(update_fields=['status', 'cancelled_at'])
    return deletion_request


def _delete_local_avatar(avatar_url):
    if not avatar_url:
        return
    filename = Path(avatar_url).name
    if not filename:
        return
    avatar_dir = (Path(settings.MEDIA_ROOT) / 'avatars').resolve()
    avatar_path = (avatar_dir / filename).resolve()
    if avatar_dir not in avatar_path.parents:
        return
    avatar_path.unlink(missing_ok=True)


@transaction.atomic
def anonymize_account(deletion_request):
    deletion_request = AccountDeletionRequest.objects.select_for_update().get(
        pk=deletion_request.pk,
    )
    if deletion_request.status != AccountDeletionRequest.Status.PENDING:
        return False
    if deletion_request.scheduled_for > timezone.now():
        return False

    user = deletion_request.user
    student = Student.objects.select_for_update().get(user=user)
    anonymous_id = uuid4().hex
    _delete_local_avatar(student.avatar)

    user.username = f'deleted_{anonymous_id}'
    user.first_name = ''
    user.last_name = ''
    user.email = ''
    user.is_active = False
    user.set_unusable_password()
    user.save()

    student.student_id = f'deleted_{anonymous_id}'
    student.school = ''
    student.phone = ''
    student.gaokao_year = None
    student.avatar = ''
    student.account_status = Student.AccountStatus.ANONYMIZED
    student.save()

    deletion_request.status = AccountDeletionRequest.Status.ANONYMIZED
    deletion_request.anonymized_at = timezone.now()
    deletion_request.save(update_fields=[
        'status', 'anonymized_at',
    ])
    return True


def anonymize_due_accounts(now=None):
    now = now or timezone.now()
    due = AccountDeletionRequest.objects.filter(
        status=AccountDeletionRequest.Status.PENDING,
        scheduled_for__lte=now,
    ).values_list('pk', flat=True)
    count = 0
    for request_id in due.iterator():
        deletion_request = AccountDeletionRequest.objects.get(pk=request_id)
        count += int(anonymize_account(deletion_request))
    return count

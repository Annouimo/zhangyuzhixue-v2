from django.contrib.auth.models import Group, Permission, User
from django.db import transaction
from django.db.models import F
from django.utils import timezone

from accounts.models import AccountDeletionRequest, Student
from accounts.roles import ACCESS_STUDENT_APP, STUDENT_GROUP
from system.models import PointsTransaction


class AdminAccountError(Exception):
    pass


@transaction.atomic
def ensure_student_access(user):
    locked_user = User.objects.select_for_update().get(pk=user.pk)
    if locked_user.is_staff or locked_user.is_superuser:
        raise AdminAccountError('管理员账号不能同时设为学生账号')
    if hasattr(locked_user, 'deletion_request'):
        request = locked_user.deletion_request
        if request.status == AccountDeletionRequest.Status.PENDING:
            raise AdminAccountError('该账号正在注销冷静期内，请先撤销注销申请')

    student, created = Student.objects.get_or_create(user=locked_user)
    group, _ = Group.objects.get_or_create(name=STUDENT_GROUP)
    permission = Permission.objects.get(
        content_type__app_label='accounts',
        codename=ACCESS_STUDENT_APP.split('.', 1)[1],
    )
    group.permissions.add(permission)
    locked_user.groups.add(group)
    return student, created


@transaction.atomic
def adjust_student_points(student, amount, description):
    locked_student = Student.objects.select_for_update().get(pk=student.pk)
    transaction_type = 'EARN' if amount > 0 else 'SPEND'
    entry = PointsTransaction.objects.create(
        student=locked_student,
        amount=float(amount),
        transaction_type=transaction_type,
        source='ADMIN_ADJUST',
        description=description,
    )
    Student.objects.filter(pk=locked_student.pk).update(
        data_version=F('data_version') + 1,
    )
    return entry


@transaction.atomic
def cancel_deletion_by_admin(deletion_request):
    locked_request = AccountDeletionRequest.objects.select_for_update().select_related(
        'user',
    ).get(pk=deletion_request.pk)
    if locked_request.status != AccountDeletionRequest.Status.PENDING:
        raise AdminAccountError('该注销申请已经处理')
    if locked_request.scheduled_for <= timezone.now():
        raise AdminAccountError('冷静期已结束，请等待自动匿名化任务处理')

    user = User.objects.select_for_update().get(pk=locked_request.user_id)
    student = Student.objects.select_for_update().get(user=user)
    user.is_active = True
    user.save(update_fields=['is_active'])
    student.account_status = Student.AccountStatus.ACTIVE
    student.save(update_fields=['account_status', 'updated_at'])
    locked_request.status = AccountDeletionRequest.Status.CANCELLED
    locked_request.cancelled_at = timezone.now()
    locked_request.save(update_fields=['status', 'cancelled_at'])
    return locked_request

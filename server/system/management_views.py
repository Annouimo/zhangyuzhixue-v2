from functools import wraps

from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.models import User
from django.core.paginator import Paginator
from django.db import transaction
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone

from accounts.models import AccountDeletionRequest, Student, UserLoginLog
from accounts.roles import (
    ACCESS_LEVEL_CHOICES,
    ACCESS_LEVEL_HANDBOOK,
    ACCESS_LEVEL_REGULAR,
    ACCESS_LEVEL_REVIEWER,
    ACCESS_LEVEL_SUPERUSER,
    CONTENT_REVIEWER_GROUP,
    INTERNAL_PORTAL_GROUP,
    get_access_level,
    get_access_level_label,
)
from accounts.services.access_levels import AccessLevelError, set_access_level
from accounts.services.admin_accounts import (
    AdminAccountError,
    adjust_student_points,
    cancel_deletion_by_admin,
)
from interactions.models import StudentSubmission, SubmissionDetail
from system.management_forms import (
    AccessLevelForm,
    PasswordResetForm,
    PointsAdjustmentForm,
    StudentProfileForm,
)
from system.models import DbVersion


def management_staff_required(view_func):
    @staff_member_required(login_url='admin:login')
    @wraps(view_func)
    def wrapped(request, *args, **kwargs):
        return view_func(request, *args, **kwargs)
    return wrapped


@management_staff_required
def home(request):
    today = timezone.localdate()
    pending_deletions = AccountDeletionRequest.objects.filter(
        status=AccountDeletionRequest.Status.PENDING,
    )
    missing_profiles = User.objects.filter(student__isnull=True).count()
    missing_student_group = Student.objects.exclude(user__groups__name='student').count()
    reviewer_without_handbook = User.objects.filter(
        groups__name=CONTENT_REVIEWER_GROUP,
    ).exclude(groups__name=INTERNAL_PORTAL_GROUP).distinct().count()
    return render(request, 'management_portal/home.html', {
        'active_today': UserLoginLog.objects.filter(login_date=today).count(),
        'submission_count': SubmissionDetail.objects.filter(created_at__date=today).count(),
        'submission_students': StudentSubmission.objects.filter(
            created_at__date=today,
        ).values('student_id').distinct().count(),
        'pending_deletion_count': pending_deletions.count(),
        'due_deletion_count': pending_deletions.filter(
            scheduled_for__lte=timezone.now(),
        ).count(),
        'user_count': User.objects.count(),
        'internal_member_count': User.objects.filter(
            Q(groups__name=INTERNAL_PORTAL_GROUP) |
            Q(groups__name=CONTENT_REVIEWER_GROUP) |
            Q(is_superuser=True),
        ).distinct().count(),
        'inconsistency_count': (
            missing_profiles + missing_student_group + reviewer_without_handbook
        ),
        'recent_students': Student.objects.select_related('user').order_by('-created_at')[:8],
        'versions': {item.db_type: item for item in DbVersion.objects.all()},
    })


@management_staff_required
def user_list(request):
    query = request.GET.get('q', '').strip()[:100]
    view = request.GET.get('view', 'all')
    access_level = request.GET.get('access_level', '')
    account_status = request.GET.get('account_status', '')
    student_status = request.GET.get('student_status', '')
    users = (
        User.objects.select_related('student')
        .prefetch_related('groups')
        .order_by('-date_joined')
    )
    if query:
        users = users.filter(
            Q(username__icontains=query) | Q(first_name__icontains=query) |
            Q(student__student_id__icontains=query) | Q(student__phone__icontains=query),
        )
    internal_users = (
        Q(groups__name=INTERNAL_PORTAL_GROUP) |
        Q(groups__name=CONTENT_REVIEWER_GROUP) | Q(is_superuser=True)
    )
    if view == 'internal':
        users = users.filter(internal_users)
    elif view == 'pending':
        users = users.filter(
            Q(is_active=False) |
            Q(student__account_status=Student.AccountStatus.PENDING_DELETION),
        )
    elif view == 'superuser':
        users = users.filter(is_superuser=True)
    else:
        view = 'all'
    if access_level == ACCESS_LEVEL_REGULAR:
        users = users.exclude(is_superuser=True).exclude(
            Q(groups__name=INTERNAL_PORTAL_GROUP) |
            Q(groups__name=CONTENT_REVIEWER_GROUP),
        )
    elif access_level == ACCESS_LEVEL_HANDBOOK:
        users = users.filter(groups__name=INTERNAL_PORTAL_GROUP).exclude(
            groups__name=CONTENT_REVIEWER_GROUP,
        ).exclude(is_superuser=True)
    elif access_level == ACCESS_LEVEL_REVIEWER:
        users = users.filter(groups__name=CONTENT_REVIEWER_GROUP).exclude(is_superuser=True)
    elif access_level == ACCESS_LEVEL_SUPERUSER:
        users = users.filter(is_superuser=True)
    else:
        access_level = ''
    if account_status == 'active':
        users = users.filter(is_active=True)
    elif account_status == 'inactive':
        users = users.filter(is_active=False)
    else:
        account_status = ''
    if student_status in {choice for choice, _ in Student.AccountStatus.choices}:
        users = users.filter(student__account_status=student_status)
    else:
        student_status = ''

    page = Paginator(users.distinct(), 25).get_page(request.GET.get('page'))
    for listed_user in page:
        listed_user.access_level = get_access_level(listed_user)
        listed_user.access_level_label = get_access_level_label(listed_user)
    return render(request, 'management_portal/user_list.html', {
        'page': page,
        'query': query,
        'view': view,
        'access_level': access_level,
        'account_status': account_status,
        'student_status': student_status,
        'access_levels': ACCESS_LEVEL_CHOICES + ((ACCESS_LEVEL_SUPERUSER, '系统超级用户'),),
        'student_statuses': Student.AccountStatus.choices,
    })


@management_staff_required
def user_detail(request, user_id):
    user = get_object_or_404(User.objects.select_related('student'), pk=user_id)
    user.access_level = get_access_level(user)
    profile_form = StudentProfileForm(user=user)
    access_level_form = AccessLevelForm(user=user)
    points_form = PointsAdjustmentForm()
    password_form = PasswordResetForm(user=user)
    if request.method == 'POST':
        action = request.POST.get('action', '')
        try:
            if action == 'save_access_level':
                access_level_form = AccessLevelForm(request.POST, user=user)
                if access_level_form.is_valid():
                    set_access_level(
                        user,
                        access_level_form.cleaned_data['access_level'],
                        request.user,
                    )
                    messages.success(request, '日常权限已更新。')
                else:
                    return _render_user_detail(
                        request, user, profile_form, access_level_form, points_form, password_form,
                    )
            elif action == 'save_profile':
                profile_form = StudentProfileForm(request.POST, user=user)
                if profile_form.is_valid():
                    _save_profile(user, profile_form.cleaned_data)
                    messages.success(request, '学生资料已保存。')
                else:
                    return _render_user_detail(
                        request, user, profile_form, access_level_form, points_form, password_form,
                    )
            elif action == 'toggle_active':
                _toggle_active(user)
                messages.success(request, '账号已启用。' if not user.is_active else '账号已停用。')
            elif action == 'adjust_points':
                points_form = PointsAdjustmentForm(request.POST)
                if points_form.is_valid():
                    adjust_student_points(user.student, **points_form.cleaned_data)
                    messages.success(request, '积分调整已记录。')
                else:
                    return _render_user_detail(
                        request, user, profile_form, access_level_form, points_form, password_form,
                    )
            elif action == 'reset_password':
                password_form = PasswordResetForm(request.POST, user=user)
                if password_form.is_valid():
                    user.set_password(password_form.cleaned_data['new_password'])
                    user.save(update_fields=['password'])
                    messages.success(request, '密码已重置，现有令牌将失效。')
                else:
                    return _render_user_detail(
                        request, user, profile_form, access_level_form, points_form, password_form,
                    )
            else:
                messages.error(request, '未知操作。')
        except (AdminAccountError, AccessLevelError) as exc:
            messages.error(request, str(exc))
        return redirect('management_portal:user_detail', user_id=user.pk)
    return _render_user_detail(
        request, user, profile_form, access_level_form, points_form, password_form,
    )


def _render_user_detail(request, user, profile_form, access_level_form, points_form, password_form):
    student = getattr(user, 'student', None)
    point_total = None
    transactions = []
    login_logs = []
    if student:
        point_total = student.point_transactions.aggregate(total=Sum('amount'))['total'] or 0
        transactions = student.point_transactions.all()[:12]
        login_logs = student.login_logs.all().order_by('-login_date')[:12]
    return render(request, 'management_portal/user_detail.html', {
        'managed_user': user,
        'student': student,
        'point_total': point_total,
        'transactions': transactions,
        'login_logs': login_logs,
        'profile_form': profile_form,
        'access_level_form': access_level_form,
        'password_form': password_form,
        'points_form': points_form,
    })


@transaction.atomic
def _save_profile(user, data):
    locked_user = User.objects.select_for_update().get(pk=user.pk)
    student = Student.objects.select_for_update().get(user=locked_user)
    locked_user.first_name = data['real_name'].strip()
    locked_user.save(update_fields=['first_name'])
    student.phone = data['phone']
    student.school = data['school'].strip()
    student.gaokao_year = data['gaokao_year']
    student.save(update_fields=['phone', 'school', 'gaokao_year', 'updated_at'])


@transaction.atomic
def _toggle_active(user):
    locked_user = User.objects.select_for_update().get(pk=user.pk)
    if locked_user.is_superuser:
        raise AdminAccountError('不能在管理工作台停用系统超级用户')
    if not locked_user.is_active and AccountDeletionRequest.objects.filter(
        user=locked_user, status=AccountDeletionRequest.Status.PENDING,
    ).exists():
        raise AdminAccountError('该账号正在注销冷静期内，请从注销申请页面撤销')
    locked_user.is_active = not locked_user.is_active
    locked_user.save(update_fields=['is_active'])


@management_staff_required
def deletion_list(request):
    if request.method == 'POST':
        deletion_request = get_object_or_404(
            AccountDeletionRequest,
            pk=request.POST.get('request_id'),
        )
        try:
            cancel_deletion_by_admin(deletion_request)
            messages.success(request, '注销申请已撤销，账号已恢复。')
        except AdminAccountError as exc:
            messages.error(request, str(exc))
        return redirect('management_portal:deletion_list')
    requests = (
        AccountDeletionRequest.objects.select_related('user', 'user__student')
        .order_by('-requested_at')
    )
    status = request.GET.get('status', 'pending')
    if status in {choice for choice, _ in AccountDeletionRequest.Status.choices}:
        requests = requests.filter(status=status)
    else:
        status = 'all'
    return render(request, 'management_portal/deletion_list.html', {
        'requests': requests[:100], 'status': status, 'now': timezone.now(),
    })

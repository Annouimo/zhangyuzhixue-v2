from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db.models import Q, Sum
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView as BaseTokenRefreshView

from system.models import LevelConfig
from accounts.models import InvitationCode, Student, UserLoginLog
from accounts.serializers import (
    LoginSerializer,
    RegisterSerializer,
    UserSerializer,
    UserUpdateSerializer,
)
from system.models import PointsTransaction
from courses.models import ClassCourseAssignment

# ── 统一响应格式 ──────────────────────────────────────────────


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _err(code, message, http_status=status.HTTP_400_BAD_REQUEST):
    return Response(
        {'code': code, 'message': message, 'data': None},
        status=http_status,
    )


# ── 注册 ──────────────────────────────────────────────────────


@extend_schema(
    request=RegisterSerializer,
    responses={200: OpenApiResponse(description='注册成功，请登录')},
)
@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    serializer = RegisterSerializer(data=request.data)
    if not serializer.is_valid():
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40101, msg)

    data = serializer.validated_data

    user = User.objects.create_user(
        username=data['username'],
        password=data['password'],
    )
    user.first_name = data.get('real_name', '')
    user.save()

    student = Student.objects.create(
        user=user,
        school=data.get('school', ''),
        phone=data.get('phone', ''),
        gaokao_year=data.get('gaokao_year'),
    )

    code = InvitationCode.objects.get(code=data['invitation_code'])
    code.is_used = True
    code.used_by = user
    from django.utils import timezone
    code.used_at = timezone.now()
    code.save()

    # 赠送注册积分
    PointsTransaction.objects.create(
        student=student,
        amount=100,
        transaction_type='EARN',
        source='SIGNUP_BONUS',
        description='新用户注册赠送',
    )

    return _ok(message='注册成功，请登录')


# ── 登录 ──────────────────────────────────────────────────────


@extend_schema(
    request=LoginSerializer,
    responses={200: OpenApiResponse(description='登录成功，返回 access/refresh token + user 对象')},
)
@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if not serializer.is_valid():
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40001, msg)

    data = serializer.validated_data
    user = authenticate(
        username=data['username'],
        password=data['password'],
    )

    if user is None:
        return _err(40001, '用户名或密码错误')

    if user.is_staff:
        return _err(40003, '管理员账号不允许登录 App')

    from django.utils import timezone as tz
    user.last_login = tz.now()
    user.save(update_fields=['last_login'])

    refresh = RefreshToken.for_user(user)

    if hasattr(user, 'student'):
        from django.utils import timezone as tz
        UserLoginLog.objects.get_or_create(
            student=user.student,
            login_date=tz.localdate(),
        )

    return _ok(data={
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': UserSerializer(user).data,
    })


# ── 登出 ──────────────────────────────────────────────────────


@extend_schema(
    request=None,
    responses={200: OpenApiResponse(description='已登出')},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    return _ok(message='已登出')


# ── Token 刷新 ────────────────────────────────────────────────


class TokenRefreshView(BaseTokenRefreshView):
    """刷新 access token — 包裹 simplejwt 响应为 {code, message, data} 格式"""

    @extend_schema(
        responses={200: OpenApiResponse(description='刷新 access token')},
    )
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            return Response({
                'code': 0,
                'message': 'ok',
                'data': response.data,
            })
        return response


# ── 用户信息 ──────────────────────────────────────────────────


def _get_points_summary(user):
    """计算用户的积分汇总"""
    if not hasattr(user, 'student'):
        return {'earned': 0, 'bonus': 0, 'spent': 0, 'available': 0}

    student = user.student
    agg = PointsTransaction.objects.filter(student=student).aggregate(
        earned=Sum('amount', filter=Q(
            source__in=[
                'LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD',
            ])),
        bonus=Sum('amount', filter=Q(source__in=['SIGNUP_BONUS', 'REVIEW_REWARD', 'RATING_REWARD'])),
        spent=Sum('amount', filter=Q(source='PAPER_PURCHASE')),
    )
    earned = agg['earned'] or 0
    bonus = agg['bonus'] or 0
    spent = abs(agg['spent']) if agg['spent'] else 0
    available = earned + bonus - spent
    return {'earned': earned, 'bonus': bonus, 'spent': spent, 'available': available}


@extend_schema(
    request=UserUpdateSerializer,
    methods=['PATCH'],
    responses={200: UserSerializer},
)
@extend_schema(
    responses={200: UserSerializer},
    methods=['GET'],
)
@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def user_me_view(request):
    """当前用户信息（GET） / 修改个人信息（PATCH）"""
    if request.method == 'GET':
        data = UserSerializer(request.user).data
        data['points_summary'] = _get_points_summary(request.user)
        return _ok(data=data)

    # PATCH
    serializer = UserUpdateSerializer(data=request.data, partial=True)
    if not serializer.is_valid():
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40201, msg)

    data = serializer.validated_data
    user = request.user

    if 'real_name' in data:
        user.first_name = data['real_name']
        user.save(update_fields=['first_name'])

    if hasattr(user, 'student'):
        student = user.student
        changed = False
        for field in ('school', 'phone', 'gaokao_year'):
            if field in data:
                setattr(student, field, data[field])
                changed = True
        if changed:
            student.save(update_fields=['school', 'phone', 'gaokao_year'])

    return _ok(data=UserSerializer(user).data)


# ── 签到 ──────────────────────────────────────────────────────


@extend_schema(
    request=None,
    responses={200: OpenApiResponse(description='签到成功')},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def checkin_view(request):
    """签到 — 创建今日登录日志 + 发放签到积分"""
    if not hasattr(request.user, 'student'):
        return _err(40301, '仅学生可签到')

    student = request.user.student
    from django.utils import timezone as tz
    today = tz.localdate()

    # 创建/获取今日登录日志
    log, created = UserLoginLog.objects.get_or_create(
        student=student,
        login_date=today,
    )

    # 如果今日已签到过，返回已签到状态
    if not created:
        streak = _calc_checkin_streak(student)
        return _ok(data={
            'checked_in': True,
            'streak_days': streak,
            'points_earned': 0,
            'message': '今日已签到',
        })

    # 计算连续签到天数
    streak = _calc_checkin_streak(student)

    # 发放签到积分
    from django.conf import settings
    base_reward = float(getattr(settings, 'LOGIN_BONUS_BASE', 0.5))
    # 每周额外奖励
    weekly_bonus = float(getattr(settings, 'LOGIN_BONUS_WEEKLY', 3.0))
    reward = int(base_reward * 10)  # 基础奖励（转换为整数分）
    if streak % 7 == 0:
        reward += int(weekly_bonus * 10)

    PointsTransaction.objects.create(
        student=student,
        amount=reward,
        transaction_type='EARN',
        source='LOGIN_BONUS',
        description=f'第{streak}天签到奖励',
    )

    return _ok(data={
        'checked_in': True,
        'streak_days': streak,
        'points_earned': reward,
        'message': f'签到成功！连续第{streak}天',
    })


def _calc_checkin_streak(student):
    """计算学生连续签到天数"""
    logs = list(UserLoginLog.objects.filter(
        student=student,
    ).order_by('-login_date').values_list('login_date', flat=True))
    if not logs:
        return 0

    from datetime import date, timedelta
    today = date.today()
    streak = 0
    expected = today

    for log_date in logs:
        if log_date == expected:
            streak += 1
            expected -= timedelta(days=1)
        elif log_date < expected:
            break

    return streak


# ── 头像上传 ──────────────────────────────────────────────────


@extend_schema(
    request=None,
    responses={200: OpenApiResponse(description='头像上传成功，返回 avatar URL')},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def avatar_upload_view(request):
    """头像上传 — 接受 multipart，resize 200x200 WebP"""
    if not hasattr(request.user, 'student'):
        return _err(40301, '仅学生可上传头像')

    if 'avatar' not in request.FILES:
        return _err(40201, '请选择图片文件')

    file = request.FILES['avatar']

    # 大小检查（2MB）
    if file.size > 2 * 1024 * 1024:
        return _err(40201, '图片大小不能超过 2MB')

    try:
        from PIL import Image
        img = Image.open(file)
        img = img.convert('RGB')
        img.thumbnail((200, 200), Image.LANCZOS)

        import os
        from django.conf import settings
        from django.utils import timezone as tz

        ts = int(tz.now().timestamp())
        filename = f'{request.user.id}_{ts}.webp'
        rel_path = os.path.join('avatars', filename)
        abs_path = os.path.join(settings.MEDIA_ROOT, rel_path)
        os.makedirs(os.path.dirname(abs_path), exist_ok=True)

        img.save(abs_path, 'WEBP', quality=85)
    except Exception:
        return _err(50001, '图片处理失败',
                    http_status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    url = request.build_absolute_uri(f'{settings.MEDIA_URL}{rel_path}')
    student = request.user.student
    student.avatar = url
    student.save(update_fields=['avatar'])

    return _ok(data={'avatar': url})


# ── 等级百分位 ──────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='等级百分位数据')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def level_percentile_view(request):
    """等级百分位：当前用户积分超过百分之多少的学生"""
    if not hasattr(request.user, 'student'):
        return _ok(data={
            'level': 1,
            'title': '青铜学徒',
            'total_xp': 0,
            'level_percentile': 100,
        })

    student = request.user.student
    # 等级依据学习积分计算（只统计 earned 分类）
    my_total = PointsTransaction.objects.filter(
        student=student,
        source__in=['LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD']
    ).aggregate(total=Sum('amount'))['total'] or 0

    # 从 LevelConfig 表查询等级
    config = LevelConfig.objects.filter(min_xp__lte=my_total).order_by('-min_xp').first()
    level = config.level if config else 1
    title = config.title if config else '青铜学徒'

    # 计算所有学生的总积分（与当前用户相同口径：仅 earned 分类）
    all_totals = PointsTransaction.objects.filter(
        source__in=['LOGIN_BONUS', 'PRACTICE_REWARD', 'TASK_REWARD']
    ).values('student_id').annotate(total=Sum('amount')).values_list('total', flat=True)

    total_count = len(all_totals)
    if total_count == 0:
        return _ok(data={
            'level': level,
            'title': title,
            'total_xp': 0,
            'level_percentile': 100,
        })

    beat_count = sum(1 for t in all_totals if t is not None and t <= my_total)
    percentile = round(beat_count / total_count * 100, 1)

    return _ok(data={
        'level': level,
        'title': title,
        'total_xp': my_total,
        'level_percentile': percentile,
    })


# ── 待办作业 ─────────────────────────────────────────────────


@extend_schema(
    responses={200: OpenApiResponse(description='待办作业列表')},
)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_assignments_view(request):
    """当前学生班级的待办作业列表（含 deadline 信息）"""
    if not hasattr(request.user, 'student'):
        return _err(40003, '仅学生可查看待办作业')

    student = request.user.student
    class_group_id = student.class_group_id
    if class_group_id is None:
        return _ok(data={
            'accessible_course_ids': [],
            'assignments': [],
        })

    from django.utils import timezone
    today = timezone.localdate()

    ccas = ClassCourseAssignment.objects.filter(
        class_course__class_group_id=class_group_id,
        is_active=True,
    ).select_related(
        'assignment', 'class_course__course',
    )

    accessible_course_ids = set()
    assignments = []
    for cca in ccas:
        course_id = cca.class_course.course_id
        accessible_course_ids.add(course_id)

        deadline_remaining = None
        if cca.deadline:
            delta = (cca.deadline - today).days
            deadline_remaining = max(delta, 0)

        q_count = cca.assignment.assignment_questions.count()

        assignments.append({
            'id': cca.assignment.id,
            'title': cca.assignment.title,
            'course_id': course_id,
            'course_name': cca.class_course.course.name,
            'total_count': q_count,
            'deadline': cca.deadline.isoformat() if cca.deadline else None,
            'deadline_remaining': deadline_remaining,
        })

    return _ok(data={
        'accessible_course_ids': sorted(accessible_course_ids),
        'assignments': assignments,
    })

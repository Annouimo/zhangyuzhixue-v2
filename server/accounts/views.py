from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db.models import Sum
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from system.models import LevelConfig
from accounts.models import InvitationCode, Student, UserLoginLog
from accounts.serializers import (
    LoginSerializer,
    RegisterSerializer,
    UserSerializer,
    UserUpdateSerializer,
)
from system.models import PointsTransaction

# ── 统一响应格式 ──────────────────────────────────────────────


def _ok(data=None, message='ok'):
    return Response({'code': 0, 'message': message, 'data': data})


def _err(code, message, http_status=status.HTTP_400_BAD_REQUEST):
    return Response(
        {'code': code, 'message': message, 'data': None},
        status=http_status,
    )


# ── 注册 ──────────────────────────────────────────────────────


@api_view(['POST'])
@permission_classes([AllowAny])
def register_view(request):
    serializer = RegisterSerializer(data=request.data)
    if not serializer.is_valid():
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40001, msg)

    data = serializer.validated_data

    user = User.objects.create_user(
        username=data['username'],
        password=data['password'],
    )
    user.first_name = data.get('real_name', '')
    user.save()

    Student.objects.create(
        user=user,
        school=data.get('school', ''),
        gaokao_year=data.get('gaokao_year'),
    )

    code = InvitationCode.objects.get(code=data['invitation_code'])
    code.is_used = True
    code.used_by = user
    from django.utils import timezone
    code.used_at = timezone.now()
    code.save()

    return _ok(message='注册成功，请登录')


# ── 登录 ──────────────────────────────────────────────────────


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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    return _ok(message='已登出')


# ── 用户信息 ──────────────────────────────────────────────────


def _get_points_summary(user):
    """计算用户的积分汇总"""
    if not hasattr(user, 'student'):
        return {'total_points': 0, 'level': 1}

    student = user.student
    agg = PointsTransaction.objects.filter(
        student=student
    ).aggregate(total=Sum('amount'))
    total = agg['total'] or 0

    # 从 LevelConfig 表查询等级
    config = LevelConfig.objects.filter(min_xp__lte=total).order_by('-min_xp').first()
    if config:
        return {'total_points': total, 'level': config.level,
                'title': config.title, 'icon': config.icon_emoji}
    return {'total_points': total, 'level': 1, 'title': '青铜学徒', 'icon': '🥉'}


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
        return _err(40001, msg)

    data = serializer.validated_data
    user = request.user

    if 'real_name' in data:
        user.first_name = data['real_name']
        user.save(update_fields=['first_name'])

    if hasattr(user, 'student'):
        student = user.student
        changed = False
        for field in ('school', 'gaokao_year'):
            if field in data:
                setattr(student, field, data[field])
                changed = True
        if changed:
            student.save(update_fields=['school', 'gaokao_year'])

    return _ok(data=UserSerializer(user).data)


# ── 头像上传 ──────────────────────────────────────────────────


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

    url = f'{settings.MEDIA_URL}{rel_path}'
    student = request.user.student
    student.avatar = url
    student.save(update_fields=['avatar'])

    return _ok(data={'avatar': url})


# ── 等级百分位 ──────────────────────────────────────────────


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def level_percentile_view(request):
    """等级百分位：当前用户积分超过百分之多少的学生"""
    if not hasattr(request.user, 'student'):
        return _ok(data={'percentile': 100, 'total_points': 0})

    student = request.user.student
    my_total = PointsTransaction.objects.filter(
        student=student
    ).aggregate(total=Sum('amount'))['total'] or 0

    # 计算所有学生的总积分
    all_totals = PointsTransaction.objects.values(
        'student_id'
    ).annotate(total=Sum('amount')).values_list('total', flat=True)

    total_count = len(all_totals)
    if total_count == 0:
        return _ok(data={'percentile': 100, 'total_points': 0})

    beat_count = sum(1 for t in all_totals if t is not None and t <= my_total)
    percentile = round(beat_count / total_count * 100, 1)

    return _ok(data={
        'percentile': percentile,
        'total_points': my_total,
    })

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import InvitationCode, Student, UserLoginLog
from accounts.serializers import (
    LoginSerializer,
    RegisterSerializer,
    UserSerializer,
)

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
        # 取第一个校验错误
        first_err = list(serializer.errors.values())[0]
        msg = str(first_err[0]) if isinstance(first_err, list) else str(first_err)
        return _err(40001, msg)

    data = serializer.validated_data

    # 创建 User
    user = User.objects.create_user(
        username=data['username'],
        password=data['password'],
    )
    user.first_name = data.get('real_name', '')
    user.save()

    # 创建 Student
    Student.objects.create(
        user=user,
        school=data.get('school', ''),
        gaokao_year=data.get('gaokao_year'),
    )

    # 标记邀请码已使用
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

    # 管理员禁止登录 App
    if user.is_staff:
        return _err(40003, '管理员账号不允许登录 App')

    # 生成 JWT
    refresh = RefreshToken.for_user(user)

    # 记录登录日志（仅学生）
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
    # JWT 无状态，服务端仅返回成功
    return _ok(message='已登出')

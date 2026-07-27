from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from accounts.models import InvitationCode


class RegisterSerializer(serializers.Serializer):
    """注册请求校验"""
    invitation_code = serializers.CharField(max_length=32)
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(min_length=6, max_length=128)
    real_name = serializers.CharField(max_length=64)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    gaokao_year = serializers.IntegerField(required=False, allow_null=True)
    accepted_terms = serializers.BooleanField()
    accepted_privacy = serializers.BooleanField()

    def validate(self, attrs):
        if not attrs['accepted_terms'] or not attrs['accepted_privacy']:
            raise serializers.ValidationError('请先阅读并同意用户协议和隐私政策')
        return attrs

    def validate_invitation_code(self, value):
        try:
            code = InvitationCode.objects.get(code=value)
        except InvitationCode.DoesNotExist:
            raise serializers.ValidationError('邀请码无效')

        if code.is_used:
            raise serializers.ValidationError('邀请码已被使用')

        from django.utils import timezone
        if code.expires_at and code.expires_at < timezone.now():
            raise serializers.ValidationError('邀请码已过期')

        return value

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('用户名已存在')
        return value


class LoginSerializer(serializers.Serializer):
    """登录请求校验"""
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=128)


class AccountDeletionSerializer(serializers.Serializer):
    current_password = serializers.CharField(max_length=128, write_only=True)


class AccountDeletionCancelSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(max_length=128, write_only=True)


class PasswordChangeSerializer(serializers.Serializer):
    current_password = serializers.CharField(max_length=128, write_only=True)
    new_password = serializers.CharField(
        min_length=8, max_length=128, write_only=True,
    )

    def validate_new_password(self, value):
        validate_password(value, user=self.context['request'].user)
        return value

    def validate(self, attrs):
        user = self.context['request'].user
        if not user.check_password(attrs['current_password']):
            raise serializers.ValidationError({'current_password': '当前密码错误'})
        if attrs['current_password'] == attrs['new_password']:
            raise serializers.ValidationError({'new_password': '新密码不能与当前密码相同'})
        return attrs


class UserSerializer(serializers.ModelSerializer):
    """用户信息序列化（登录响应）"""
    real_name = serializers.SerializerMethodField()
    role = serializers.SerializerMethodField()
    student_id = serializers.SerializerMethodField()
    class_group_id = serializers.SerializerMethodField()
    school = serializers.SerializerMethodField()
    gaokao_year = serializers.SerializerMethodField()
    avatar = serializers.SerializerMethodField()
    phone = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'real_name', 'role', 'student_id',
            'class_group_id', 'school', 'gaokao_year', 'avatar', 'phone',
        ]

    def get_real_name(self, obj) -> str:
        return obj.get_full_name() or obj.username

    def get_role(self, obj) -> str:
        if hasattr(obj, 'student'):
            return 'student'
        if hasattr(obj, 'teacher'):
            return 'teacher'
        return 'admin'

    def get_student_id(self, obj) -> str | None:
        if hasattr(obj, 'student'):
            return obj.student.student_id
        return None

    def get_class_group_id(self, obj) -> int | None:
        if hasattr(obj, 'student') and hasattr(obj.student, 'class_group_id'):
            return obj.student.class_group_id
        return None

    def get_school(self, obj) -> str | None:
        if hasattr(obj, 'student'):
            return obj.student.school
        return None

    def get_gaokao_year(self, obj) -> int | None:
        if hasattr(obj, 'student'):
            return obj.student.gaokao_year
        return None

    def get_avatar(self, obj) -> str | None:
        if hasattr(obj, 'student'):
            return obj.student.avatar or None
        return None

    def get_phone(self, obj) -> str:
        if hasattr(obj, 'student'):
            return obj.student.phone or ''
        return ''


class UserUpdateSerializer(serializers.Serializer):
    """用户信息更新"""
    real_name = serializers.CharField(max_length=64, required=False)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    gaokao_year = serializers.IntegerField(required=False, allow_null=True)
    school = serializers.CharField(max_length=128, required=False, allow_blank=True)

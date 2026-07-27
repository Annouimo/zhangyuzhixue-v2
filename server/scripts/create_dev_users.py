"""
开发环境测试用户创建脚本
"""
import os
import sys

# 先设置 Django 环境
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')

import django  # noqa: E402
django.setup()

# setup 之后才能导入 Django 模型
from django.contrib.auth.models import User  # noqa: E402
from django.utils import timezone  # noqa: E402

from accounts.models import InvitationCode, Student  # noqa: E402

# ── 配置 ──────────────────────────────────────────────────────

USERS = [
    {'username': 'admin', 'password': 'admin123', 'role': 'admin',
     'real_name': '管理员'},
    {'username': 'student1', 'password': 'test123', 'role': 'student',
     'real_name': '张三', 'gaokao_year': 2026},
    {'username': 'student2', 'password': 'test123', 'role': 'student',
     'real_name': '李四', 'gaokao_year': 2026},
    {'username': 'student3', 'password': 'test123', 'role': 'student',
     'real_name': '王五', 'gaokao_year': 2027},
]

INVITATION_CODES = [
    'GR7X-K2P9-M4VB', 'DEV1-ABCD-0001', 'DEV2-ABCD-0002',
    'DEV3-ABCD-0003', 'DEV4-ABCD-0004',
]


def create_users():
    for u in USERS:
        if User.objects.filter(username=u['username']).exists():
            print('  SKIP', u['username'], '(exists)')
            continue
        if u['role'] == 'admin':
            User.objects.create_superuser(
                username=u['username'], password=u['password'], email='')
        else:
            user = User.objects.create_user(
                username=u['username'], password=u['password'])
            user.first_name = u['real_name']
            user.save()
            if u['role'] == 'student':
                Student.objects.create(user=user, gaokao_year=u.get('gaokao_year'))
        print('  OK', u['username'], '(' + u['real_name'] + ')')


def create_invitations():
    expires = timezone.now() + timezone.timedelta(days=365)
    for code_str in INVITATION_CODES:
        if InvitationCode.objects.filter(code=code_str).exists():
            print('  SKIP', code_str, '(exists)')
            continue
        InvitationCode.objects.create(code=code_str, is_used=False, expires_at=expires)
        print('  OK', code_str)


if __name__ == '__main__':
    print('Creating users...')
    create_users()
    print('Creating invitation codes...')
    create_invitations()
    print('Done.')

"""
开发环境测试用户创建脚本

请在 Phase 1.3 认证 API 实现后运行：
    python scripts/create_dev_users.py

注意：仅用于本地开发环境，不要在线上环境运行。
删除脚本中需要先 `git rm` 已有的迁移文件并重新迁移。
"""

import os
import sys

import django

# 设置 Django 环境
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
django.setup()

from django.contrib.auth.models import User
from django.utils import timezone

from accounts.models import InvitationCode, Student, Teacher

# ── 测试用户配置 ──────────────────────────────────────────────

USERS = [
    {'username': 'admin', 'password': 'admin123', 'role': 'admin',
     'real_name': '管理员'},
    {'username': 'teacher1', 'password': 'test123', 'role': 'teacher',
     'real_name': '李明老师'},
    {'username': 'student1', 'password': 'test123', 'role': 'student',
     'real_name': '张三', 'gaokao_year': 2026},
    {'username': 'student2', 'password': 'test123', 'role': 'student',
     'real_name': '李四', 'gaokao_year': 2026},
    {'username': 'student3', 'password': 'test123', 'role': 'student',
     'real_name': '王五', 'gaokao_year': 2027},
]

INVITATION_CODES = [
    'GR7X-K2P9-M4VB',
    'DEV1-ABCD-0001',
    'DEV2-ABCD-0002',
    'DEV3-ABCD-0003',
    'DEV4-ABCD-0004',
]

# ── 创建 ──────────────────────────────────────────────────────


def create_users():
    results = []
    for u in USERS:
        if User.objects.filter(username=u['username']).exists():
            results.append(f"⏭  {u['username']} 已存在，跳过")
            continue

        if u['role'] == 'admin':
            User.objects.create_superuser(
                username=u['username'],
                password=u['password'],
                email='',
            )
            results.append(f"✅ 管理员 {u['username']} 创建成功")
            continue

        user = User.objects.create_user(
            username=u['username'],
            password=u['password'],
        )
        user.first_name = u['real_name']
        user.save()

        if u['role'] == 'teacher':
            Teacher.objects.create(user=user)
            results.append(f"✅ 教师 {u['username']} ({u['real_name']}) 创建成功")
        elif u['role'] == 'student':
            Student.objects.create(
                user=user,
                gaokao_year=u.get('gaokao_year'),
            )
            results.append(f"✅ 学生 {u['username']} ({u['real_name']}) 创建成功")

    return results


def create_invitation_codes():
    results = []
    for code_str in INVITATION_CODES:
        if InvitationCode.objects.filter(code=code_str).exists():
            results.append(f"⏭  邀请码 {code_str} 已存在，跳过")
            continue

        InvitationCode.objects.create(
            code=code_str,
            is_used=False,
            expires_at=timezone.now() + timezone.timedelta(days=365),
        )
        results.append(f"✅ 邀请码 {code_str} 创建成功")

    return results


# ── 主入口 ────────────────────────────────────────────────────


if __name__ == '__main__':
    print('=' * 50)
    print('章鱼智学 v2 · 开发测试用户创建')
    print('=' * 50)

    print('\n📋 创建用户...')
    for r in create_users():
        print(f'  {r}')

    print('\n📋 创建邀请码...')
    for r in create_invitation_codes():
        print(f'  {r}')

    print('\n' + '=' * 50)
    print('完成！')

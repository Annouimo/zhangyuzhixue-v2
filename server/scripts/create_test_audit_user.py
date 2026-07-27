#!/usr/bin/env python3
"""Create comprehensive test user 'test_audit' with rich data for runtime verification."""
import os, sys
sys.path.insert(0, '/opt/zhangyuzhixue-v2/server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')
import django; django.setup()

from django.contrib.auth.models import User
from django.utils import timezone
from accounts.models import Student
from interactions.models import StudentSubmission
from system.models import PointsTransaction

username = 'test_audit'
password = 'test123'

# --- Create user ---
if User.objects.filter(username=username).exists():
    u = User.objects.get(username=username)
    print(f'User {username} already exists (id={u.id})')
else:
    u = User.objects.create_user(username=username, password=password)
    u.first_name = '审计测试'
    u.save()
    if not Student.objects.filter(user=u).exists():
        Student.objects.create(user=u, gaokao_year=2026)
    print(f'Created user {username} (id={u.id})')

student = Student.objects.get(user=u)

# --- Seed submissions ---
existing = StudentSubmission.objects.filter(student=student).count()
if existing > 0:
    print(f'Skipping submissions: {existing} already exist')
else:
    for i in range(20):
        StudentSubmission.objects.create(
            student=student,
        )
    print(f'Created 20 submissions')

# --- Seed points ---
existing_pts = PointsTransaction.objects.filter(student=student).count()
if existing_pts > 0:
    print(f'Skipping points: {existing_pts} already exist')
else:
    from random import choice
    for day in range(7):
        from datetime import timedelta
        PointsTransaction.objects.create(
            student=student,
            amount=choice([3, 5, 8, 10]),
            transaction_type='earn',
            source=choice(['做题奖励', '签到奖励', '评价奖励']),
            created_at=timezone.now() - timedelta(days=day),
        )
    print('Created 7 days of points history')

# --- Summary ---
print(f'\n{"="*50}')
print(f'Test account ready!')
print(f'  Username: {username}')
print(f'  Password: {password}')
print(f'  Submissions: {StudentSubmission.objects.filter(student=student).count()}')
print(f'  Points txns: {PointsTransaction.objects.filter(student=student).count()}')
print(f'{"="*50}')

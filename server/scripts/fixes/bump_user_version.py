"""
用法：python manage.py shell < bump_user_version.py

将 test_audit 账号的 data_version 递增 1，
触发客户端检测到用户数据版本差，弹出更新提示。
"""
from accounts.models import Student
from django.contrib.auth.models import User

user = User.objects.filter(username='test_audit').first()
if not user:
    print('❌ 未找到用户 test_audit')
    exit(1)

student = Student.objects.filter(user=user).first()
if not student:
    print('❌ 未找到 test_audit 的 Student 记录')
    exit(1)

old = student.data_version
student.data_version += 1
student.save(update_fields=['data_version'])

print(f'✅ test_audit data_version: {old} → {student.data_version}')
print('重启客户端 App，启动时即会检测到版本差，弹出更新 banner。')

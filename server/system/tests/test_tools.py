"""Admin tools 页面可访问性测试"""
import pytest
from django.contrib.auth.models import User
from django.test import Client
from django.urls import reverse


@pytest.fixture
def admin_user(db):
    user = User.objects.create_superuser('admin', 'admin@test.com', 'admin123')
    return user


@pytest.fixture
def test_data(db):
    """创建测试数据：班级、学生"""
    from courses.models import ClassGroup
    from accounts.models import Student
    cg = ClassGroup.objects.create(name='高三1班')
    user = User.objects.create_user(
        'teststudent', 'test@test.com', 'pass123'
    )
    student = Student.objects.create(
        user=user, class_group=cg, student_id='XS-000001'
    )
    return {'class_group': cg, 'student': student}


class TestAdminTools:

    def test_tools_page_requires_admin(self, db):
        """未认证用户：重定向到登录页"""
        client = Client()
        resp = client.get(reverse('admin-system-tools'))
        assert resp.status_code == 302

    def test_tools_page_accessible(self, db, admin_user):
        """管理员访问：页面可访问且有内容"""
        client = Client()
        client.force_login(admin_user)
        resp = client.get(reverse('admin-system-tools'))
        assert resp.status_code == 200
        content = resp.content.decode()
        assert '工具' in content or '构建' in content or '工具' in content

    def test_grant_points_success(self, db, admin_user, test_data):
        """赠送积分成功"""
        client = Client()
        client.force_login(admin_user)
        resp = client.post(reverse('admin-system-tools'), {
            'action': 'grant_points',
            'student_id': str(test_data['student'].id),
            'amount': '10',
            'description': '测试奖励',
        })
        assert resp.status_code == 302  # 重定向到工具页
        # 验证积分流水已创建
        from system.models import PointsTransaction
        tx = PointsTransaction.objects.filter(student=test_data['student']).first()
        assert tx is not None
        assert tx.amount == 10.0
        assert tx.transaction_type == 'EARN'
        assert tx.source == 'ADMIN_ADJUST'
        assert tx.description == '测试奖励'

    def test_grant_points_invalid_student(self, db, admin_user):
        """学生不存在时返回错误"""
        client = Client()
        client.force_login(admin_user)
        resp = client.post(reverse('admin-system-tools'), {
            'action': 'grant_points',
            'student_id': '99999',
            'amount': '10',
            'description': '测试',
        })
        assert resp.status_code == 302
        from system.models import PointsTransaction
        assert PointsTransaction.objects.count() == 0

    def test_grant_points_zero_amount(self, db, admin_user, test_data):
        """积分值必须大于 0"""
        client = Client()
        client.force_login(admin_user)
        resp = client.post(reverse('admin-system-tools'), {
            'action': 'grant_points',
            'student_id': str(test_data['student'].id),
            'amount': '0',
            'description': '测试',
        })
        assert resp.status_code == 302
        from system.models import PointsTransaction
        assert PointsTransaction.objects.count() == 0

    def test_grant_points_missing_description(self, db, admin_user, test_data):
        """缺少原因时返回错误"""
        client = Client()
        client.force_login(admin_user)
        resp = client.post(reverse('admin-system-tools'), {
            'action': 'grant_points',
            'student_id': str(test_data['student'].id),
            'amount': '5',
            'description': '',
        })
        assert resp.status_code == 302
        from system.models import PointsTransaction
        assert PointsTransaction.objects.count() == 0

"""Admin tools 页面可访问性测试"""
import pytest
from django.contrib.auth.models import User
from django.test import Client
from django.urls import reverse


@pytest.fixture
def admin_user(db):
    user = User.objects.create_superuser('admin', 'admin@test.com', 'admin123')
    return user


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

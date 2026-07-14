"""版本检查 API 测试"""

import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from system.models import DbVersion


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def qbank_version(db):
    return DbVersion.objects.create(
        db_type='qbank',
        schema_version=2,
        data_version=5,
        force_update=False,
        download_url='/static/dbs/qbank_v5.db.gz',
        checksum='abc123',
        size_bytes=1024000,
        message='新增 50 题',
    )


@pytest.fixture
def courses_version(db):
    return DbVersion.objects.create(
        db_type='courses',
        schema_version=1,
        data_version=3,
        force_update=True,
        download_url='/static/dbs/courses_v3.db.gz',
        checksum='def456',
        size_bytes=512000,
        message='修正公式渲染',
    )


class TestVersionCheck:
    """版本检查 API 测试"""

    def test_qbank_version_exists(self, api_client, qbank_version):
        """题库版本存在：正确返回版本信息"""
        resp = api_client.get(reverse('sync-qbank-version'))

        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert resp.data['data']['schema_version'] == 2
        assert resp.data['data']['data_version'] == 5
        assert resp.data['data']['force_update'] is False
        assert resp.data['data']['download_url'].startswith('http')
        assert resp.data['data']['checksum'] == 'abc123'
        assert resp.data['data']['size_bytes'] == 1024000

    def test_courses_version_exists(self, api_client, courses_version):
        """课程版本存在：正确返回版本信息"""
        resp = api_client.get(reverse('sync-courses-version'))

        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert resp.data['data']['data_version'] == 3
        assert resp.data['data']['force_update'] is True
        assert resp.data['data']['download_url'].startswith('http')
        assert resp.data['data']['message'] == '修正公式渲染'

    def test_version_not_found(self, db, api_client):
        """版本记录不存在：返回默认值"""
        resp = api_client.get(reverse('sync-qbank-version'))

        assert resp.status_code == 200
        assert resp.data['code'] == 0
        assert resp.data['data']['schema_version'] == 0
        assert resp.data['data']['data_version'] == 0
        assert resp.data['data']['download_url'] == ''
        assert resp.data['data']['message'] == '暂无数据'

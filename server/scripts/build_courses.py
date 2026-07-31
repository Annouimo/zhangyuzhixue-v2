"""
构建 courses.db（讲义数据）

用法：
    python scripts/build_courses.py          # 构建+更新版本号
    python scripts/build_courses.py --test   # 仅构建测试
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')

import django  # noqa: E402
django.setup()

from scripts.build_schemas import ASSETS_TABLES, COURSES_TABLES  # noqa: E402
from scripts.build_utils import build_database  # noqa: E402
from system.models import DbVersion  # noqa: E402


def get_version_info():
    try:
        ver = DbVersion.objects.get(db_type='courses')
        return {
            'schema_version': max(ver.schema_version, 2),
            'data_version': ver.data_version,
        }
    except DbVersion.DoesNotExist:
        return {'schema_version': 2, 'data_version': 1}


def bump_version(ver):
    ver['data_version'] += 1
    return ver


def main():
    test_mode = '--test' in sys.argv

    version_info = get_version_info()
    if not test_mode:
        version_info = bump_version(version_info)

    print('=' * 50)
    print('构建 courses.db (讲义数据)')
    print(f'  Schema v{version_info["schema_version"]}')
    print(f'  Data   v{version_info["data_version"]}')
    if test_mode:
        print('  [测试模式 — 不更新版本号]')
    print('=' * 50)

    build_database(
        schema=COURSES_TABLES,
        db_type='courses',
        version_info=version_info,
        test_mode=test_mode,
    )

    print()
    print('✅ 构建完成')


if __name__ == '__main__':
    main()

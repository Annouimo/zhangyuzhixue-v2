"""
构建 assets.db（题库数据）

用法：
    python scripts/build_assets.py          # 构建+更新版本号
    python scripts/build_assets.py --test   # 仅构建测试
"""
import os
import sys
import shutil

# Django 环境
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'math_platform.settings')

import django  # noqa: E402
django.setup()

from scripts.build_schemas import ASSETS_TABLES  # noqa: E402
from scripts.build_utils import build_database  # noqa: E402
from system.models import DbVersion  # noqa: E402
from interactions.publication_services import confirm_qbank_publication  # noqa: E402


def get_version_info():
    """获取当前版本号"""
    try:
        ver = DbVersion.objects.get(db_type='qbank')
        return {
            'schema_version': ver.schema_version,
            'data_version': ver.data_version,
        }
    except DbVersion.DoesNotExist:
        return {'schema_version': 1, 'data_version': 1}


def bump_version(ver):
    """递增 data_version"""
    ver['data_version'] += 1
    return ver


def main():
    test_mode = '--test' in sys.argv

    version_info = get_version_info()
    if not test_mode:
        version_info = bump_version(version_info)

    print('=' * 50)
    print('构建 assets.db (题库数据)')
    print(f'  Schema v{version_info["schema_version"]}')
    print(f'  Data   v{version_info["data_version"]}')
    if test_mode:
        print('  [测试模式 — 不更新版本号]')
    print('=' * 50)

    output_path = build_database(
        schema=ASSETS_TABLES,
        db_type='qbank',
        version_info=version_info,
        test_mode=test_mode,
    )

    if not test_mode:
        published = confirm_qbank_publication(
            output_path, version_info['data_version']
        )
        print(f'  已发布内容贡献: {published} 条')

    print()
    print('✅ 数据库构建完成')

    # ── 同步配图到 Flutter assets ──
    print()
    print('同步配图...')
    image_src = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        '..', 'static', 'questions', 'images')
    targets = []
    for rel in [['..', 'flutter_app', 'assets', 'questions', 'images']]:
        target = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            *rel)
        targets.append(target)

    if not os.path.isdir(image_src):
        print(f'  ⚠ 配图源目录不存在: {image_src}')
    else:
        for flutter_assets in targets:
            os.makedirs(flutter_assets, exist_ok=True)
            total_count = 0
            # Flatten: copy .webp files with unique names (replace / with _)
            for root, dirs, files in os.walk(image_src):
                for f in files:
                    if not f.lower().endswith('.webp'):
                        continue
                    rel = os.path.relpath(os.path.join(root, f), image_src)
                    flat_name = rel.replace('\\', '/').replace('/', '_')
                    shutil.copy2(os.path.join(root, f), os.path.join(flutter_assets, flat_name))
                    total_count += 1
            print(f'  student: {total_count} 张配图')
        print(f'✅ 配图同步完成')


if __name__ == '__main__':
    main()

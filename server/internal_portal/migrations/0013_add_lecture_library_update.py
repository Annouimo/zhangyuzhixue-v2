from datetime import date

from django.db import migrations


def add_lecture_library_update(apps, schema_editor):
    HandbookUpdate = apps.get_model('internal_portal', 'HandbookUpdate')
    HandbookUpdate.objects.update_or_create(
        date=date(2026, 7, 30),
        title='新增只读讲义库并统一内部导航',
        defaults={
            'description': (
                '团队成员可在工作手册中按系列和章节只读浏览讲义，支持'
                '公式渲染、章节切换和分隔提示；工作手册与内容工作台'
                '统一提供官网、工作手册、内容工作台和管理员后台入口。'
            ),
            'sort_order': 10,
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0012_handbook_display_types_and_entry_keys'),
    ]

    operations = [
        migrations.RunPython(
            add_lecture_library_update,
            migrations.RunPython.noop,
        ),
    ]

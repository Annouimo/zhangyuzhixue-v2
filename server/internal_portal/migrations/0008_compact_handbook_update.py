from django.db import migrations


def compact_handbook_update(apps, schema_editor):
    HandbookUpdate = apps.get_model('internal_portal', 'HandbookUpdate')
    HandbookUpdate.objects.filter(title='重构项目工作手册').update(
        description='重组手册页面与原有入口，补充题库结构和题库概况。',
    )


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0007_group_entries_by_meaning'),
    ]

    operations = [
        migrations.RunPython(compact_handbook_update, migrations.RunPython.noop),
    ]

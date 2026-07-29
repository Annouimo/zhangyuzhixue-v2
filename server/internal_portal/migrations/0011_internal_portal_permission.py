from django.db import migrations


def bind_portal_permission(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Permission = apps.get_model('auth', 'Permission')
    ContentType = apps.get_model('contenttypes', 'ContentType')
    content_type, _ = ContentType.objects.get_or_create(
        app_label='internal_portal', model='projectprofile'
    )
    permission, _ = Permission.objects.get_or_create(
        content_type=content_type,
        codename='access_internal_portal',
        defaults={'name': '可访问内部资料门户'},
    )
    group, _ = Group.objects.get_or_create(name='internal_portal')
    group.permissions.add(permission)


class Migration(migrations.Migration):
    dependencies = [
        ('internal_portal', '0010_define_media_video_workflow'),
    ]
    operations = [
        migrations.AlterModelOptions(
            name='projectprofile',
            options={
                'permissions': [('access_internal_portal', '可访问内部资料门户')],
                'verbose_name': '项目概览',
                'verbose_name_plural': '项目概览',
            },
        ),
        migrations.RunPython(bind_portal_permission, migrations.RunPython.noop),
    ]

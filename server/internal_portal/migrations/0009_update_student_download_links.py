from django.db import migrations


RELEASE_ROOT = (
    'https://gitee.com/annouimo/zhangyuzhixue-v2/'
    'releases/download/v1.2.0-beta.1'
)


def update_student_download_links(apps, schema_editor):
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')
    PortalEntry.objects.filter(name='学生端 Android').update(
        url=f'{RELEASE_ROOT}/app-release.apk',
    )
    PortalEntry.objects.filter(name='学生端 Windows').update(
        url=(
            f'{RELEASE_ROOT}/'
            '%E7%AB%A0%E9%B1%BC%E6%99%BA%E5%AD%A6-'
            '1.2.0-beta.1-windows.exe'
        ),
    )


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0008_compact_handbook_update'),
    ]

    operations = [
        migrations.RunPython(
            update_student_download_links,
            migrations.RunPython.noop,
        ),
    ]

from django.db import migrations


def create_reviewer_role(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Permission = apps.get_model('auth', 'Permission')
    ContentType = apps.get_model('contenttypes', 'ContentType')
    content_type, _ = ContentType.objects.get_or_create(
        app_label='interactions', model='contentcontribution'
    )
    permissions = []
    for codename, name in (
        ('access_review_workbench', '可访问内容审核工作台'),
        ('publish_content_contribution', '可将投稿录入正式题库'),
    ):
        permission, _ = Permission.objects.get_or_create(
            content_type=content_type,
            codename=codename,
            defaults={'name': name},
        )
        permissions.append(permission)
    group, _ = Group.objects.get_or_create(name='content_reviewer')
    group.permissions.add(*permissions)


def remove_reviewer_role(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Group.objects.filter(name='content_reviewer').delete()


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0010_unify_user_roles'),
        ('interactions', '0007_contentcontribution_contributionreview_and_more'),
    ]
    operations = [
        migrations.AlterModelOptions(
            name='contentcontribution',
            options={
                'ordering': ['-updated_at'],
                'permissions': [
                    ('access_review_workbench', '可访问内容审核工作台'),
                    ('publish_content_contribution', '可将投稿录入正式题库'),
                ],
                'verbose_name': '内容贡献',
                'verbose_name_plural': '内容贡献审核',
            },
        ),
        migrations.RunPython(create_reviewer_role, remove_reviewer_role),
    ]

from django.db import migrations, models


def create_roles(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Permission = apps.get_model('auth', 'Permission')
    ContentType = apps.get_model('contenttypes', 'ContentType')
    Student = apps.get_model('accounts', 'Student')

    student_type, _ = ContentType.objects.get_or_create(
        app_label='accounts', model='student'
    )
    permission, _ = Permission.objects.get_or_create(
        content_type=student_type,
        codename='access_student_app',
        defaults={'name': '可访问学生端'},
    )
    group, _ = Group.objects.get_or_create(name='student')
    group.permissions.add(permission)
    for student in Student.objects.select_related('user').iterator():
        student.user.groups.add(group)

    Group.objects.get_or_create(name='internal_portal')


def remove_roles(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    Group.objects.filter(name='student').delete()


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0009_remove_accountdeletionrequest_previous_class_group_and_more'),
    ]
    operations = [
        migrations.AlterModelOptions(
            name='student',
            options={
                'permissions': [('access_student_app', '可访问学生端')],
                'verbose_name': '学生',
                'verbose_name_plural': '学生',
            },
        ),
        migrations.RunPython(create_roles, remove_roles),
    ]

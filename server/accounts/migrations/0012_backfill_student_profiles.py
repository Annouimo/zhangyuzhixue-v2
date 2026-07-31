from django.db import migrations


def backfill_student_profiles(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    SystemConfig = apps.get_model('system', 'SystemConfig')
    User = apps.get_model('auth', 'User')
    Student = apps.get_model('accounts', 'Student')
    template_config = SystemConfig.objects.filter(
        key='student_id_template',
    ).first()
    student_id_template = (
        template_config.value if template_config else '202610{lcg}'
    )
    student_group, _ = Group.objects.get_or_create(name='student')
    handbook_group, _ = Group.objects.get_or_create(name='internal_portal')
    for user in User.objects.iterator():
        student, created = Student.objects.get_or_create(
            user_id=user.pk,
            defaults={'student_id': f'__backfill_user_{user.pk}'},
        )
        if created:
            lcg = f'{((student.pk - 1) * 71237 + 58417) % 100000:05d}'
            Student.objects.filter(pk=student.pk).update(
                student_id=student_id_template.replace('{lcg}', lcg),
            )
        user.groups.add(student_group)
        if user.groups.filter(name='content_reviewer').exists():
            user.groups.add(handbook_group)


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0011_remove_invitation_code'),
        ('system', '0002_systemconfig'),
    ]

    operations = [migrations.RunPython(backfill_student_profiles, migrations.RunPython.noop)]

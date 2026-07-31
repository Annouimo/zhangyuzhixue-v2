from django.db import migrations


def backfill_student_profiles(apps, schema_editor):
    Group = apps.get_model('auth', 'Group')
    User = apps.get_model('auth', 'User')
    Student = apps.get_model('accounts', 'Student')
    student_group, _ = Group.objects.get_or_create(name='student')
    handbook_group, _ = Group.objects.get_or_create(name='internal_portal')
    for user in User.objects.iterator():
        Student.objects.get_or_create(user_id=user.pk)
        user.groups.add(student_group)
        if user.groups.filter(name='content_reviewer').exists():
            user.groups.add(handbook_group)


class Migration(migrations.Migration):
    dependencies = [('accounts', '0011_remove_invitation_code')]

    operations = [migrations.RunPython(backfill_student_profiles, migrations.RunPython.noop)]

from datetime import datetime, timezone

from django.db import migrations, models


def deduplicate_student_phones(apps, schema_editor):
    Student = apps.get_model('accounts', 'Student')
    duplicates = (
        Student.objects.exclude(phone='')
        .values('phone')
        .annotate(count=models.Count('id'))
        .filter(count__gt=1)
    )

    for duplicate in duplicates.iterator():
        students = list(
            Student.objects.filter(phone=duplicate['phone'])
            .select_related('user')
        )
        keep = max(
            students,
            key=lambda student: (
                student.user.is_active,
                student.user.last_login is not None,
                student.user.last_login or datetime.min.replace(tzinfo=timezone.utc),
                student.user.date_joined,
                student.id,
            ),
        )
        Student.objects.filter(phone=duplicate['phone']).exclude(pk=keep.pk).update(phone='')


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0007_registration_consent'),
    ]

    operations = [
        migrations.RunPython(deduplicate_student_phones, migrations.RunPython.noop),
        migrations.AddConstraint(
            model_name='student',
            constraint=models.UniqueConstraint(
                condition=~models.Q(phone=''),
                fields=('phone',),
                name='unique_nonempty_student_phone',
            ),
        ),
    ]

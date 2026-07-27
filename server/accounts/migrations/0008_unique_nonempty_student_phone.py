from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0007_registration_consent'),
    ]

    operations = [
        migrations.AddConstraint(
            model_name='student',
            constraint=models.UniqueConstraint(
                condition=~models.Q(phone=''),
                fields=('phone',),
                name='unique_nonempty_student_phone',
            ),
        ),
    ]

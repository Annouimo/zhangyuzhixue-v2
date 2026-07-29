from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('system', '0010_studentnotification')]

    operations = [
        migrations.AddConstraint(
            model_name='pointstransaction',
            constraint=models.UniqueConstraint(
                fields=('student', 'source', 'source_object_id'),
                condition=models.Q(
                    source='PAPER_PURCHASE',
                    source_object_id__isnull=False,
                ),
                name='uq_paper_purchase_per_student_paper',
            ),
        ),
    ]

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('system', '0008_points_transaction_client_id'),
    ]

    operations = [
        migrations.AddConstraint(
            model_name='pointstransaction',
            constraint=models.UniqueConstraint(
                fields=('student', 'source', 'source_object_id'),
                condition=models.Q(
                    source='RATING_REWARD',
                    source_object_id__isnull=False,
                ),
                name='uq_rating_reward_per_student_question',
            ),
        ),
    ]

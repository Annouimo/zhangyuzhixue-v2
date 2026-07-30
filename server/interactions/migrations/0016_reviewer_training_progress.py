from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('interactions', '0015_preferencefilter_keyword'),
    ]

    operations = [
        migrations.CreateModel(
            name='ReviewerTrainingProgress',
            fields=[
                ('id', models.BigAutoField(
                    auto_created=True, primary_key=True, serialize=False,
                    verbose_name='ID',
                )),
                ('completed_steps', models.JSONField(
                    blank=True, default=list, verbose_name='已完成步骤',
                )),
                ('updated_at', models.DateTimeField(
                    auto_now=True, verbose_name='更新时间',
                )),
                ('reviewer', models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='reviewer_training_progress',
                    to=settings.AUTH_USER_MODEL, verbose_name='审核员',
                )),
            ],
            options={
                'verbose_name': '审核员培训进度',
                'verbose_name_plural': '审核员培训进度',
            },
        ),
    ]

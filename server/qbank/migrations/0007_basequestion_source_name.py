from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('qbank', '0006_normalize_fill_answer_blanks')]

    operations = [
        migrations.AddField(
            model_name='basequestion',
            name='source_name',
            field=models.CharField(
                blank=True, default='', max_length=255,
                verbose_name='试卷或资料名称',
            ),
        ),
    ]

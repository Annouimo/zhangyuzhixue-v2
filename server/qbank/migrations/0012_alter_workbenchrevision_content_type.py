from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [('qbank', '0011_workbenchrevision')]

    operations = [
        migrations.AlterField(
            model_name='workbenchrevision',
            name='content_type',
            field=models.CharField(
                choices=[
                    ('question', '题目'), ('tag', '概念标签'),
                    ('card', '知识卡片'), ('course', '讲义系列'),
                    ('document', '讲义章节'), ('video', '视频'),
                ],
                max_length=16,
                verbose_name='内容类型',
            ),
        ),
    ]

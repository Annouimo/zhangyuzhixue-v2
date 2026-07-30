import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('qbank', '0010_clean_choice_option_image_artifacts'),
    ]

    operations = [
        migrations.CreateModel(
            name='WorkbenchRevision',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('content_type', models.CharField(choices=[('question', '题目'), ('tag', '概念标签'), ('card', '知识卡片'), ('course', '讲义系列'), ('document', '讲义章节')], max_length=16, verbose_name='内容类型')),
                ('object_id', models.PositiveIntegerField(verbose_name='内容 ID')),
                ('object_label', models.CharField(blank=True, max_length=255, verbose_name='内容标题')),
                ('action', models.CharField(max_length=16, verbose_name='操作')),
                ('note', models.CharField(max_length=500, verbose_name='修改说明')),
                ('snapshot', models.JSONField(verbose_name='内容快照')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='修订时间')),
                ('actor', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='workbench_revisions', to=settings.AUTH_USER_MODEL, verbose_name='操作人')),
            ],
            options={
                'verbose_name': '工作台内容修订',
                'verbose_name_plural': '工作台内容修订',
                'ordering': ['-created_at', '-pk'],
            },
        ),
        migrations.AddIndex(
            model_name='workbenchrevision',
            index=models.Index(fields=['content_type', 'object_id', '-created_at'], name='qbank_wbrev_object_idx'),
        ),
    ]

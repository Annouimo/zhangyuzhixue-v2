from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('qbank', '0008_content_origin_and_contributor'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='ContentChangeLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('object_type', models.CharField(max_length=32, verbose_name='内容类型')),
                ('object_id', models.PositiveIntegerField(blank=True, null=True, verbose_name='内容 ID')),
                ('object_label', models.CharField(blank=True, max_length=255, verbose_name='内容标题')),
                ('action', models.CharField(max_length=32, verbose_name='操作')),
                ('note', models.CharField(max_length=500, verbose_name='修改说明')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='操作时间')),
                ('actor', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='content_change_logs', to=settings.AUTH_USER_MODEL, verbose_name='操作人')),
                ('question', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='workbench_changes', to='qbank.basequestion', verbose_name='题目')),
            ],
            options={
                'verbose_name': '内容修改记录',
                'verbose_name_plural': '内容修改记录',
                'ordering': ['-created_at', '-pk'],
            },
        ),
    ]

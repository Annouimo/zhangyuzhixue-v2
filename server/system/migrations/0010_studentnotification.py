from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0008_unique_nonempty_student_phone'),
        ('system', '0009_unique_rating_reward'),
    ]

    operations = [
        migrations.AddField(
            model_name='announcement',
            name='expires_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='失效时间'),
        ),
        migrations.AddField(
            model_name='announcement',
            name='priority',
            field=models.CharField(choices=[('normal', '普通'), ('important', '重要'), ('critical', '紧急')], default='normal', max_length=16, verbose_name='优先级'),
        ),
        migrations.AddField(
            model_name='announcement',
            name='publish_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='发布时间'),
        ),
        migrations.CreateModel(
            name='StudentNotification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('category', models.CharField(choices=[('contribution', '内容贡献'), ('sync', '数据同步'), ('account', '账号安全'), ('system', '系统消息'), ('achievement', '学习成就'), ('points', '积分')], max_length=24, verbose_name='类别')),
                ('event_key', models.CharField(max_length=160, verbose_name='事件键')),
                ('title', models.CharField(max_length=128, verbose_name='标题')),
                ('content', models.TextField(blank=True, default='', verbose_name='内容')),
                ('priority', models.CharField(choices=[('normal', '普通'), ('important', '重要'), ('critical', '紧急')], default='normal', max_length=16, verbose_name='优先级')),
                ('action_type', models.CharField(choices=[('none', '无操作'), ('route', '应用内跳转'), ('data_update', '数据更新'), ('login', '重新登录')], default='none', max_length=24, verbose_name='操作类型')),
                ('action_target', models.CharField(blank=True, default='', max_length=64, verbose_name='操作目标')),
                ('payload', models.JSONField(blank=True, default=dict, verbose_name='操作参数')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='创建时间')),
                ('read_at', models.DateTimeField(blank=True, null=True, verbose_name='已读时间')),
                ('expires_at', models.DateTimeField(blank=True, null=True, verbose_name='过期时间')),
                ('announcement', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='student_notifications', to='system.announcement')),
                ('student', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='accounts.student')),
            ],
            options={'verbose_name': '学生通知', 'verbose_name_plural': '学生通知', 'ordering': ['-created_at', '-id']},
        ),
        migrations.AddConstraint(
            model_name='studentnotification',
            constraint=models.UniqueConstraint(fields=('student', 'event_key'), name='uq_student_notification_event'),
        ),
        migrations.AddIndex(
            model_name='studentnotification',
            index=models.Index(fields=['student', 'read_at', '-created_at'], name='system_stud_student_0f7f3b_idx'),
        ),
    ]

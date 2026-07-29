from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [('interactions', '0012_paper_folder')]

    operations = [
        migrations.AddField(
            model_name='paperfolder',
            name='revision',
            field=models.PositiveIntegerField(default=0, verbose_name='版本号'),
        ),
        migrations.AddField(
            model_name='paperfolder',
            name='is_default',
            field=models.BooleanField(default=False, verbose_name='默认组卷夹'),
        ),
        migrations.CreateModel(
            name='SyncIdentity',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('entity_type', models.CharField(max_length=32, verbose_name='实体类型')),
                ('client_id', models.CharField(max_length=128, verbose_name='客户端唯一标识')),
                ('object_id', models.PositiveBigIntegerField(verbose_name='服务端对象 ID')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='创建时间')),
                ('student', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sync_identities', to='accounts.student')),
            ],
        ),
        migrations.AddConstraint(
            model_name='syncidentity',
            constraint=models.UniqueConstraint(fields=('student', 'entity_type', 'client_id'), name='uq_sync_identity_client'),
        ),
    ]

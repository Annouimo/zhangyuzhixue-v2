from django.db import migrations, models


def reset_unversioned_completed(apps, schema_editor):
    contribution = apps.get_model('interactions', 'ContentContribution')
    contribution.objects.filter(
        status='completed', published_qbank_version__isnull=True
    ).update(status='approved_pending_release')


class Migration(migrations.Migration):
    dependencies = [('interactions', '0009_contribution_publication_states')]

    operations = [
        migrations.RunPython(reset_unversioned_completed, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='contentcontribution',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', '待首次审核'),
                    ('resubmitted', '修改后待复审'),
                    ('needs_revision', '待修改'),
                    ('processing', '处理中'),
                    ('approved_pending_release', '已通过，待题库发布'),
                    ('completed', '已发布'),
                    ('rejected', '未采纳'),
                    ('withdrawn', '已撤回'),
                ],
                db_index=True,
                default='pending',
                max_length=24,
                verbose_name='状态',
            ),
        ),
        migrations.AlterField(
            model_name='contributionreview',
            name='action',
            field=models.CharField(
                choices=[
                    ('submitted', '已提交'),
                    ('resubmitted', '重新提交'),
                    ('needs_revision', '打回修改'),
                    ('processing', '进入处理'),
                    ('completed', '处理完成'),
                    ('published', '已发布到题库'),
                    ('publication_rolled_back', '题库发布已回滚'),
                    ('rejected', '未采纳'),
                    ('withdrawn', '已撤回'),
                ],
                max_length=24,
                verbose_name='操作',
            ),
        ),
    ]

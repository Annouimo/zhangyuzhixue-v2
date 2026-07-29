from django.db import migrations, models
import django.db.models.deletion


def migrate_contribution_origins(apps, schema_editor):
    contribution = apps.get_model('interactions', 'ContentContribution')
    revision = apps.get_model('interactions', 'ContributionRevision')
    contribution.objects.filter(
        contribution_type='solution_contribution'
    ).update(contribution_type='new_solution', content_origin='external')
    contribution.objects.filter(
        contribution_type='question_correction'
    ).update(content_origin=None)
    for item in contribution.objects.filter(contribution_type='new_question'):
        latest = revision.objects.filter(contribution=item).order_by(
            '-revision_number'
        ).first()
        source_type = (
            latest.normalized_payload.get('source', {}).get('source_type')
            if latest else None
        )
        item.content_origin = (
            'original' if source_type == 'self_created' else 'external'
        )
        item.save(update_fields=['content_origin'])


class Migration(migrations.Migration):
    dependencies = [
        ('interactions', '0012_paper_folder'),
        ('qbank', '0008_content_origin_and_contributor'),
    ]

    operations = [
        migrations.AddField(
            model_name='contentcontribution',
            name='content_origin',
            field=models.CharField(
                blank=True, choices=[('external', '外部'), ('original', '原创')],
                max_length=16, null=True, verbose_name='来源性质',
            ),
        ),
        migrations.AddField(
            model_name='contentcontribution',
            name='completed_solution_method',
            field=models.ForeignKey(
                blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL,
                related_name='source_contributions', to='qbank.solutionmethod',
                verbose_name='处理后解法',
            ),
        ),
        migrations.RunPython(migrate_contribution_origins, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='contentcontribution',
            name='contribution_type',
            field=models.CharField(
                choices=[
                    ('new_question', '新题投稿'),
                    ('new_solution', '解法投稿'),
                    ('question_correction', '题目纠错'),
                ],
                max_length=32, verbose_name='贡献类型',
            ),
        ),
    ]

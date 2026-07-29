from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


def infer_question_origins(apps, schema_editor):
    question = apps.get_model('qbank', 'BaseQuestion')
    question.objects.filter(exam_type='原创').update(content_origin='original')


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0010_unify_user_roles'),
        ('qbank', '0007_basequestion_source_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='basequestion',
            name='content_origin',
            field=models.CharField(
                choices=[('external', '外部'), ('original', '原创')],
                default='external', max_length=16, verbose_name='来源性质',
            ),
        ),
        migrations.AddField(
            model_name='basequestion',
            name='contributed_by',
            field=models.ForeignKey(
                blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL,
                related_name='contributed_questions', to='accounts.student',
                verbose_name='题目投稿人',
            ),
        ),
        migrations.AddField(
            model_name='solutionmethod',
            name='content_origin',
            field=models.CharField(
                choices=[('external', '外部'), ('original', '原创')],
                default='external', max_length=16, verbose_name='来源性质',
            ),
        ),
        migrations.AddField(
            model_name='solutionmethod',
            name='contributed_by',
            field=models.ForeignKey(
                blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL,
                related_name='contributed_solution_methods', to='accounts.student',
                verbose_name='解法投稿人',
            ),
        ),
        migrations.AddField(
            model_name='basequestion',
            name='updated_at',
            field=models.DateTimeField(
                auto_now=True, default=django.utils.timezone.now,
                verbose_name='更新时间',
            ),
            preserve_default=False,
        ),
        migrations.RunPython(infer_question_origins, migrations.RunPython.noop),
    ]

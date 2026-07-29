from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('interactions', '0010_reconcile_contribution_publication'),
        ('qbank', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='contentcontribution',
            name='target_sub_question',
            field=models.ForeignKey(
                blank=True, null=True, on_delete=models.SET_NULL,
                related_name='solution_contributions', to='qbank.subquestion',
                verbose_name='目标小题',
            ),
        ),
        migrations.AlterField(
            model_name='contentcontribution',
            name='contribution_type',
            field=models.CharField(
                choices=[
                    ('new_question', '新题投稿'),
                    ('solution_contribution', '解法投稿'),
                    ('question_correction', '题目纠错'),
                ],
                max_length=32, verbose_name='贡献类型',
            ),
        ),
    ]

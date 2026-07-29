from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('interactions', '0011_solution_contributions'),
        ('qbank', '0007_basequestion_source_name'),
    ]

    operations = [
        migrations.CreateModel(
            name='PaperFolder',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=128, verbose_name='名称')),
                ('client_updated_at', models.DateTimeField(verbose_name='客户端更新时间')),
                ('last_generated_at', models.DateTimeField(blank=True, null=True, verbose_name='最近生成时间')),
                ('last_generated_fingerprint', models.CharField(blank=True, default='', max_length=64, verbose_name='最近生成内容指纹')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='创建时间')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('last_generated_paper', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='source_folders', to='interactions.custompaper')),
                ('student', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='paper_folders', to='accounts.student')),
            ],
            options={
                'verbose_name': '组卷夹',
                'verbose_name_plural': '组卷夹',
                'ordering': ['-updated_at', '-id'],
            },
        ),
        migrations.CreateModel(
            name='PaperFolderQuestion',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('sort_order', models.IntegerField(verbose_name='排序')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='加入时间')),
                ('folder', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='folder_questions', to='interactions.paperfolder')),
                ('question', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='paper_folder_questions', to='qbank.basequestion')),
            ],
            options={
                'verbose_name': '组卷夹题目',
                'verbose_name_plural': '组卷夹题目',
                'ordering': ['folder', 'sort_order'],
            },
        ),
        migrations.AddConstraint(
            model_name='paperfolderquestion',
            constraint=models.UniqueConstraint(fields=('folder', 'question'), name='uq_paper_folder_question'),
        ),
        migrations.AddField(
            model_name='paperfolder',
            name='questions',
            field=models.ManyToManyField(blank=True, related_name='paper_folders', through='interactions.PaperFolderQuestion', to='qbank.basequestion'),
        ),
    ]

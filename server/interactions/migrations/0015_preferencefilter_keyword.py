from django.db import migrations, models


def rename_default_baskets(apps, schema_editor):
    paper_folder = apps.get_model('interactions', 'PaperFolder')
    paper_folder.objects.filter(
        is_default=True,
        name='默认组卷夹',
    ).update(name='默认试题篮')


class Migration(migrations.Migration):
    dependencies = [
        ('interactions', '0014_merge_20260729_1500'),
    ]

    operations = [
        migrations.AddField(
            model_name='preferencefilter',
            name='keyword',
            field=models.CharField(blank=True, default='', max_length=256, verbose_name='搜索词'),
        ),
        migrations.AlterModelOptions(
            name='paperfolder',
            options={'ordering': ['-updated_at', '-id'], 'verbose_name': '试题篮', 'verbose_name_plural': '试题篮'},
        ),
        migrations.AlterModelOptions(
            name='paperfolderquestion',
            options={'ordering': ['folder', 'sort_order'], 'verbose_name': '试题篮题目', 'verbose_name_plural': '试题篮题目'},
        ),
        migrations.AlterField(
            model_name='paperfolder',
            name='is_default',
            field=models.BooleanField(default=False, verbose_name='默认试题篮'),
        ),
        migrations.RunPython(rename_default_baskets, migrations.RunPython.noop),
    ]

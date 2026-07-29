from django.db import migrations, models


DISPLAY_TYPES = {
    ('overview', 'project-structure'): 'project_map',
    ('overview', 'changelog'): 'changelog',
    ('software', 'question-structure'): 'tree',
    ('software', 'question-overview'): 'question_stats',
}


def populate_handbook_metadata(apps, schema_editor):
    HandbookSection = apps.get_model('internal_portal', 'HandbookSection')
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')

    for section in HandbookSection.objects.select_related('page'):
        display_type = DISPLAY_TYPES.get((section.page.slug, section.slug))
        if display_type is None:
            display_type = 'entries' if section.entries.exists() else 'text'
        section.display_type = display_type
        section.save(update_fields=('display_type',))

    for entry in PortalEntry.objects.select_related('section'):
        section_key = entry.section.slug if entry.section_id else 'general'
        entry.key = f'{section_key}-{entry.pk}'
        entry.save(update_fields=('key',))


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0011_internal_portal_permission'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='businessarea',
            options={
                'ordering': ('sort_order', 'id'),
                'verbose_name': '项目板块',
                'verbose_name_plural': '项目板块',
            },
        ),
        migrations.AddField(
            model_name='handbooksection',
            name='display_type',
            field=models.CharField(
                choices=[
                    ('text', '普通正文'),
                    ('entries', '条目列表'),
                    ('project_map', '项目板块列表'),
                    ('changelog', '更新日志'),
                    ('tree', '树形文本'),
                    ('question_stats', '题库统计'),
                ],
                default='text', max_length=24, verbose_name='展示方式',
            ),
        ),
        migrations.AddField(
            model_name='portalentry',
            name='key',
            field=models.SlugField(blank=True, max_length=80, verbose_name='稳定标识'),
        ),
        migrations.RunPython(
            populate_handbook_metadata, migrations.RunPython.noop,
        ),
        migrations.AlterField(
            model_name='portalentry',
            name='key',
            field=models.SlugField(max_length=80, verbose_name='稳定标识'),
        ),
        migrations.AddConstraint(
            model_name='portalentry',
            constraint=models.UniqueConstraint(
                fields=('area', 'key'), name='unique_portal_area_entry_key',
            ),
        ),
    ]

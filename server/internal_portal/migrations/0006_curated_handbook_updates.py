from datetime import date

from django.db import migrations, models


def seed_handbook_update(apps, schema_editor):
    HandbookUpdate = apps.get_model('internal_portal', 'HandbookUpdate')
    HandbookUpdate.objects.get_or_create(
        date=date(2026, 7, 28),
        title='重构项目工作手册',
        defaults={
            'description': (
                '按总览、章鱼智学软件、官网门户、圆明智学自媒体内容和'
                '自媒体后期重组页面；迁移原有入口；增加题库结构和题库概况。'
            ),
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0005_build_work_handbook'),
    ]

    operations = [
        migrations.CreateModel(
            name='HandbookUpdate',
            fields=[
                ('id', models.BigAutoField(
                    auto_created=True, primary_key=True,
                    serialize=False, verbose_name='ID',
                )),
                ('date', models.DateField(verbose_name='更新日期')),
                ('title', models.CharField(max_length=160, verbose_name='更新内容')),
                ('description', models.TextField(blank=True, verbose_name='说明')),
                ('sort_order', models.PositiveIntegerField(
                    default=0, verbose_name='同日排序',
                )),
            ],
            options={
                'verbose_name': '手册更新记录',
                'verbose_name_plural': '手册更新记录',
                'ordering': ('-date', 'sort_order', '-id'),
            },
        ),
        migrations.RunPython(seed_handbook_update, migrations.RunPython.noop),
    ]

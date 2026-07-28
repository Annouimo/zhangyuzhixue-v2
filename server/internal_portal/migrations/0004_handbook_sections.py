from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0003_update_document_entries'),
    ]

    operations = [
        migrations.AlterField(
            model_name='projectprofile',
            name='positioning',
            field=models.CharField(blank=True, max_length=240, verbose_name='项目定位'),
        ),
        migrations.CreateModel(
            name='HandbookSection',
            fields=[
                ('id', models.BigAutoField(
                    auto_created=True, primary_key=True,
                    serialize=False, verbose_name='ID',
                )),
                ('title', models.CharField(max_length=100, verbose_name='章节标题')),
                ('slug', models.SlugField(max_length=50, verbose_name='章节标识')),
                ('body', models.TextField(blank=True, verbose_name='正文')),
                ('is_visible', models.BooleanField(default=True, verbose_name='显示')),
                ('sort_order', models.PositiveIntegerField(default=0, verbose_name='排序')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='更新时间')),
                ('page', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='sections',
                    to='internal_portal.businessarea',
                    verbose_name='所属页面',
                )),
            ],
            options={
                'verbose_name': '手册章节',
                'verbose_name_plural': '手册章节',
                'ordering': ('page__sort_order', 'sort_order', 'id'),
            },
        ),
        migrations.AddField(
            model_name='portalentry',
            name='section',
            field=models.ForeignKey(
                blank=True, null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='entries',
                to='internal_portal.handbooksection',
                verbose_name='所属章节',
            ),
        ),
        migrations.AddConstraint(
            model_name='handbooksection',
            constraint=models.UniqueConstraint(
                fields=('page', 'slug'),
                name='unique_handbook_page_section',
            ),
        ),
    ]

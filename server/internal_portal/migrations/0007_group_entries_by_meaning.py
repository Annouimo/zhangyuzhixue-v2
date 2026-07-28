from django.db import migrations


def group_entries_by_meaning(apps, schema_editor):
    BusinessArea = apps.get_model('internal_portal', 'BusinessArea')
    HandbookSection = apps.get_model('internal_portal', 'HandbookSection')
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')

    software = BusinessArea.objects.get(slug='software')
    downloads = HandbookSection.objects.get(
        page=software, slug='achievements',
    )
    downloads.title = '软件版本与下载'
    downloads.save(update_fields=('title',))
    HandbookSection.objects.filter(
        page=software, slug='question-structure',
    ).update(sort_order=50)
    HandbookSection.objects.filter(
        page=software, slug='question-overview',
    ).update(sort_order=60)

    section_data = (
        ('product-and-system', '产品与系统资料', 20),
        ('development-and-operations', '开发与运维资料', 30),
        ('technical-tools', '技术与管理入口', 40),
    )
    sections = {}
    for slug, title, order in section_data:
        sections[slug], _ = HandbookSection.objects.update_or_create(
            page=software,
            slug=slug,
            defaults={'title': title, 'sort_order': order},
        )

    PortalEntry.objects.filter(name__in={
        '产品边界', '系统架构', '数据架构',
    }).update(section=sections['product-and-system'])
    PortalEntry.objects.filter(name__in={
        '开发与测试', '发布与运维', '项目文档索引', '仓库地图',
    }).update(section=sections['development-and-operations'])
    PortalEntry.objects.filter(name__in={
        'Gitee 主仓库', 'API 文档', 'Django 管理后台',
    }).update(section=sections['technical-tools'])

    website = BusinessArea.objects.get(slug='website')
    links = HandbookSection.objects.get(page=website, slug='links')
    links.title = '主要页面'
    links.save(update_fields=('title',))
    policies, _ = HandbookSection.objects.update_or_create(
        page=website,
        slug='policies',
        defaults={'title': '协议与政策', 'sort_order': 20},
    )
    PortalEntry.objects.filter(
        area=website, name__in={'隐私政策', '用户协议'},
    ).update(section=policies)


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0006_curated_handbook_updates'),
    ]

    operations = [
        migrations.RunPython(group_entries_by_meaning, migrations.RunPython.noop),
    ]

from django.db import migrations


def revise_work_handbook(apps, schema_editor):
    BusinessArea = apps.get_model('internal_portal', 'BusinessArea')
    HandbookSection = apps.get_model('internal_portal', 'HandbookSection')
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')

    software = BusinessArea.objects.get(slug='software')
    content = BusinessArea.objects.get(slug='content')
    post = BusinessArea.objects.get(slug='post-production')
    content.summary = '视频内容类型与发布平台。'
    content.save(update_fields=('summary',))

    # Remove the retired software reference groups and their entries.
    removed_sections = HandbookSection.objects.filter(
        page=software,
        slug__in={'product-and-system', 'development-and-operations', 'technical-tools'},
    )
    PortalEntry.objects.filter(section__in=removed_sections).delete()
    removed_sections.delete()

    achievements = HandbookSection.objects.get(page=software, slug='achievements')
    PortalEntry.objects.update_or_create(
        area=software,
        key='zhangyuzhixue-code-repository',
        defaults={
            'section': achievements,
            'name': '章鱼智学代码仓库',
            'entry_type': 'tool',
            'description': '软件、服务端、官网及项目文档。',
            'status': 'active',
            'url': 'https://github.com/Annouimo/zhangyuzhixue_app_v2',
            'link_label': '打开仓库',
            'sort_order': 10,
        },
    )

    # Content-production details now belong to the post-production workflow.
    content_sections = HandbookSection.objects.filter(
        page=content, slug__in={'content-production', 'visual-forms'},
    )
    PortalEntry.objects.filter(section__in=content_sections).delete()
    content_sections.delete()

    directions = HandbookSection.objects.get(page=content, slug='directions')
    PortalEntry.objects.update_or_create(
        area=content,
        key='zhangyuzhixue-digital-assets',
        defaults={
            'section': directions,
            'name': '章鱼智学数字资产库',
            'entry_type': 'tool',
            'description': '集中管理供软件、官网和自媒体复用的数字资产。',
            'status': 'active',
            'url': 'https://github.com/Annouimo/zhangyuzhixue-digital-assets',
            'link_label': '打开仓库',
            'sort_order': 60,
        },
    )

    post_section = HandbookSection.objects.get(page=post, slug='overview')
    PortalEntry.objects.update_or_create(
        area=post,
        key='video-operations',
        defaults={
            'section': post_section,
            'name': '视频运营与发布',
            'entry_type': 'service',
            'description': '视频资料、录入规则和发布状态的工作入口。',
            'status': 'active',
            'url': '/internal/video-operations/',
            'link_label': '打开视频运营',
            'sort_order': 50,
        },
    )


class Migration(migrations.Migration):
    dependencies = [('internal_portal', '0013_add_lecture_library_update')]
    operations = [migrations.RunPython(revise_work_handbook, migrations.RunPython.noop)]

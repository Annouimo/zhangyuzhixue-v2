from datetime import date

from django.db import migrations


def create_entries(PortalEntry, area, section, entries):
    for name, description, order in entries:
        PortalEntry.objects.create(
            area=area,
            section=section,
            name=name,
            entry_type='service',
            description=description,
            status='active',
            url='',
            link_label='',
            sort_order=order,
        )


def define_media_video_workflow(apps, schema_editor):
    BusinessArea = apps.get_model('internal_portal', 'BusinessArea')
    HandbookSection = apps.get_model('internal_portal', 'HandbookSection')
    HandbookUpdate = apps.get_model('internal_portal', 'HandbookUpdate')
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')

    content = BusinessArea.objects.get(slug='content')
    content.summary = '视频内容类型、内容制作方式与发布平台。'
    content.save(update_fields=('summary',))
    post = BusinessArea.objects.get(slug='post-production')
    post.summary = '统筹视频素材，完成后期制作与成片输出。'
    post.save(update_fields=('summary',))

    content_types = HandbookSection.objects.get(
        page=content, slug='directions',
    )
    content_types.title = '视频内容类型'
    content_types.body = ''
    content_types.sort_order = 10
    content_types.save(update_fields=('title', 'body', 'sort_order'))
    content_work, _ = HandbookSection.objects.update_or_create(
        page=content,
        slug='content-production',
        defaults={
            'title': '内容制作',
            'body': (
                '内容制作负责形成视频所需的基础内容和素材。'
                '可视化是视觉内容的一种实现形式，不是独立的视频类型。'
            ),
            'sort_order': 20,
            'is_visible': True,
        },
    )
    visual_forms, _ = HandbookSection.objects.update_or_create(
        page=content,
        slug='visual-forms',
        defaults={
            'title': '视频类型与视觉呈现',
            'body': '',
            'sort_order': 30,
            'is_visible': True,
        },
    )
    HandbookSection.objects.filter(page=content, slug='platforms').update(
        sort_order=40,
    )

    PortalEntry.objects.filter(
        area=content, section=content_types,
    ).delete()
    create_entries(PortalEntry, content, content_types, (
        ('系列系统课程', '围绕完整知识体系制作的连续课程。', 10),
        ('专题深度解析', '针对具体问题或知识点进行深入讲解。', 20),
        ('学习经验分享', '分享学习方法、备考经验和成长经历。', 30),
        ('学术交流', '围绕数学、教育及相关学术问题开展讨论。', 40),
    ))
    create_entries(PortalEntry, content, content_work, (
        ('视觉内容', '根据文案制作画面素材，可采用可视化形式呈现。', 10),
        ('文案', '确定讲解结构并撰写视频文稿。', 20),
        ('配音', '根据文案完成音频录制。', 30),
    ))
    create_entries(PortalEntry, content, visual_forms, (
        ('系列系统课程', '包含可视化内容。', 10),
        ('专题深度解析', '包含可视化内容。', 20),
        ('学习经验分享', '根据具体选题确定视觉呈现形式。', 30),
        ('学术交流', '根据内容形式确定视觉呈现形式。', 40),
    ))

    post_section = HandbookSection.objects.get(page=post, slug='overview')
    post_section.title = '后期制作'
    post_section.body = (
        '后期制作负责统筹视觉内容、配音等素材，完成剪辑、包装、'
        '音画调整和最终成片输出。'
    )
    post_section.save(update_fields=('title', 'body'))
    PortalEntry.objects.filter(area=post, section=post_section).delete()
    create_entries(PortalEntry, post, post_section, (
        ('素材统筹', '接收、整理并协调视觉内容、文案和配音素材。', 10),
        ('剪辑与包装', '完成视频剪辑和必要的视觉包装。', 20),
        ('音画调整', '统一处理画面、配音和其他声音素材。', 30),
        ('成片输出', '检查成片并按发布要求输出最终文件。', 40),
    ))

    HandbookUpdate.objects.update_or_create(
        date=date(2026, 7, 28),
        title='完善自媒体视频工作分类',
        defaults={
            'description': (
                '明确四类视频内容，区分内容制作与后期制作，补充各类'
                '视频的视觉呈现方式。'
            ),
            'sort_order': 10,
        },
    )


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0009_update_student_download_links'),
    ]

    operations = [
        migrations.RunPython(
            define_media_video_workflow,
            migrations.RunPython.noop,
        ),
    ]

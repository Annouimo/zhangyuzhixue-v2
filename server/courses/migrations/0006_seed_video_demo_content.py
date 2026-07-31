from datetime import date

from django.db import migrations


DEMO_COURSE_NAME = '视频功能示例讲义'


def seed_video_demo_content(apps, schema_editor):
    Course = apps.get_model('courses', 'Course')
    Document = apps.get_model('courses', 'Document')
    VideoCategory = apps.get_model('courses', 'VideoCategory')
    Video = apps.get_model('courses', 'Video')
    VideoDocumentLink = apps.get_model('courses', 'VideoDocumentLink')

    course, _ = Course.objects.update_or_create(
        name=DEMO_COURSE_NAME,
        defaults={'description': '用于视频目录与讲义双向入口的测试内容。'},
    )
    documents = []
    document_specs = (
        ('01', '从集合开始理解函数', '# 从集合开始理解函数\n\n用集合、对应和变量的视角重新认识函数。'),
        ('02', '函数图象的平移与伸缩', '# 函数图象的平移与伸缩\n\n从 $y=f(x)$ 出发，记录常见变换的规律。'),
        ('03', '导数与单调性', '# 导数与单调性\n\n用导数符号判断函数的增减。'),
        ('04', '三角函数的图象方法', '# 三角函数的图象方法\n\n利用周期、振幅和相位分析三角函数。'),
        ('05', '备考错题的三步复盘法', '# 备考错题的三步复盘法\n\n记录错因、补齐知识点，并重新解决。'),
        ('06', '如何读懂一道综合题', '# 如何读懂一道综合题\n\n先拆解条件，再识别知识点和解题路径。'),
    )
    for chapter, title, content in document_specs:
        document, _ = Document.objects.update_or_create(
            course=course,
            chapter=chapter,
            defaults={'title': title, 'md_content': content},
        )
        documents.append(document)

    categories = {
        category.name: category
        for category in VideoCategory.objects.all()
    }
    video_specs = (
        ('系列系统课程', '系统课 01：用集合语言理解函数', '用一个小问题说清函数的基本概念。', 1, (0, '')),
        ('系列系统课程', '系统课 02：函数图象与变换', '从图象变换入手，建立函数直观理解。', 2, (1, '配套讲解')),
        ('专题深度解析', '专题：导数判断单调性', '用图像、表格和导数三种方法复核单调性。', 1, (2, '例题演示')),
        ('专题深度解析', '专题：三角函数参数题', '拆解参数对周期、振幅和相位的影响。', 2, (3, '配套讲解')),
        ('学习经验分享', '经验分享：错题本怎么才有用', '三步记录错题，避免把错题本变成抄题本。', 1, (4, '拓展内容')),
        ('学习经验分享', '经验分享：综合题的时间分配', '分享考场中读题、计算和检查的节奏。', 2, (5, '拓展内容')),
        ('学术交流', '学术交流：什么是数学视觉化', '讨论动态图形如何帮助我们理解抽象概念。', 1, (0, '拓展内容')),
        ('学术交流', '学术交流：从问题到数学模型', '用一个生活问题展示建模思维。', 2, (5, '拓展内容')),
    )
    for category_name, title, description, sort_order, (document_index, relation_label) in video_specs:
        video, _ = Video.objects.update_or_create(
            title=title,
            defaults={
                'category': categories[category_name],
                'description': description,
                'cover_url': '',
                'platform_name': 'B站（示例）',
                'video_url': 'https://www.bilibili.com/',
                'published_at': date(2026, 7, 31),
                'sort_order': sort_order,
                'is_published': True,
            },
        )
        VideoDocumentLink.objects.update_or_create(
            video=video,
            document=documents[document_index],
            defaults={'relation_label': relation_label, 'sort_order': 1},
        )


class Migration(migrations.Migration):
    dependencies = [
        ('courses', '0005_videocategory_video_videodocumentlink_and_more'),
    ]

    operations = [
        migrations.RunPython(seed_video_demo_content, migrations.RunPython.noop),
    ]

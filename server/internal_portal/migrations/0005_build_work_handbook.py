from django.db import migrations


QUESTION_STRUCTURE = '''题目 BaseQuestion
├─ 基本属性：年份、地区、考试类型、题号、题型
├─ 数值属性：难度、计算量、参考分值
├─ 内容：题干、配图
├─ 概念标签 ConceptTag（多对多、支持树形层级）
├─ 小题 SubQuestion（支持父子小题）
│  ├─ 答案
│  ├─ 解析
│  └─ 解法 SolutionMethod（一道小题可有多个解法）
│     └─ 步骤 SolutionStep
│        ├─ 标题
│        ├─ LaTeX 内容
│        └─ 关联知识卡片标题
└─ 选择题扩展 ChoiceExt
   └─ A/B/C/D 选项'''


def build_work_handbook(apps, schema_editor):
    ProjectProfile = apps.get_model('internal_portal', 'ProjectProfile')
    BusinessArea = apps.get_model('internal_portal', 'BusinessArea')
    HandbookSection = apps.get_model('internal_portal', 'HandbookSection')
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')

    ProjectProfile.objects.update(
        title='项目工作手册',
        positioning='',
        current_phase='',
        current_focus='',
    )

    technology = BusinessArea.objects.get(slug='technology')
    technology.name = '章鱼智学软件'
    technology.slug = 'software'
    technology.summary = '软件开发、设计与持续迭代。'
    technology.sort_order = 10
    technology.save()
    software = technology

    content = BusinessArea.objects.get(slug='content')
    content.name = '圆明智学自媒体内容'
    content.summary = '可视化、系统课程、经验分享和学术交流。'
    content.sort_order = 30
    content.save()

    website, _ = BusinessArea.objects.get_or_create(
        slug='website',
        defaults={
            'name': '章鱼智学官网门户',
            'summary': '公开官网及相关页面。',
            'sort_order': 20,
        },
    )
    post, _ = BusinessArea.objects.get_or_create(
        slug='post-production',
        defaults={
            'name': '圆明智学自媒体后期',
            'summary': '素材处理、剪辑和成熟视频成片输出。',
            'sort_order': 40,
        },
    )
    overview, _ = BusinessArea.objects.get_or_create(
        slug='overview',
        defaults={
            'name': '总览',
            'summary': '项目结构、协作规范和内部页面更新记录。',
            'sort_order': 0,
        },
    )

    sections = {}
    section_data = (
        (overview, 'project-structure', '项目结构', '', 10),
        (overview, 'rules', '规范', '', 20),
        (overview, 'changelog', '更新日志', '', 30),
        (software, 'achievements', '当前成果', '', 10),
        (software, 'question-structure', '题库结构', QUESTION_STRUCTURE, 20),
        (software, 'question-overview', '题库概况', '', 30),
        (website, 'links', '官网链接', '', 10),
        (content, 'directions', '内容方向', '', 10),
        (content, 'platforms', '发布平台', '', 20),
        (post, 'overview', '自媒体后期', '', 10),
    )
    for page, slug, title, body, order in section_data:
        section, _ = HandbookSection.objects.update_or_create(
            page=page,
            slug=slug,
            defaults={'title': title, 'body': body, 'sort_order': order},
        )
        sections[(page.slug, slug)] = section

    product = BusinessArea.objects.get(slug='product')
    team = BusinessArea.objects.get(slug='team')

    software_names = {
        '学生端 Android', '学生端 Windows', '学生端 iOS',
        'Gitee 主仓库', '系统架构', '数据架构', '开发与测试',
        '发布与运维', 'API 文档', 'Django 管理后台',
        '项目文档索引', '仓库地图', '产品边界',
    }
    PortalEntry.objects.filter(name__in=software_names).update(
        area=software, section=sections[('software', 'achievements')],
    )

    website_names = {'产品介绍与下载', '隐私政策', '用户协议'}
    PortalEntry.objects.filter(name__in=website_names).update(
        area=website, section=sections[('website', 'links')],
    )
    PortalEntry.objects.filter(area=content).exclude(name='产品边界').update(
        section=sections[('content', 'platforms')],
    )

    website_entries = (
        ('官网首页', '章鱼智学公开官网。', '/', '打开官网', 10),
        ('团队介绍', '项目团队公开介绍。', '/team.html', '查看页面', 30),
        ('关于我们', '项目背景和联系方式。', '/about.html', '查看页面', 40),
    )
    for name, description, url, label, order in website_entries:
        PortalEntry.objects.update_or_create(
            area=website,
            name=name,
            defaults={
                'section': sections[('website', 'links')],
                'entry_type': 'product',
                'description': description,
                'status': 'active',
                'url': url,
                'link_label': label,
                'sort_order': order,
            },
        )

    content_directions = (
        ('可视化', '史谨毓', 10),
        ('系统课程', '张誉宝', 20),
        ('经验分享', '', 30),
        ('学术交流', '', 40),
    )
    for name, owner, order in content_directions:
        PortalEntry.objects.update_or_create(
            area=content,
            name=name,
            defaults={
                'section': sections[('content', 'directions')],
                'entry_type': 'service',
                'description': owner,
                'status': 'active',
                'url': '',
                'link_label': '',
                'sort_order': order,
            },
        )

    PortalEntry.objects.filter(area__in=(product, team)).update(area=software)
    product.delete()
    team.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0004_handbook_sections'),
    ]

    operations = [
        migrations.RunPython(build_work_handbook, migrations.RunPython.noop),
    ]

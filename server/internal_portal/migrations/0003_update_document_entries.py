from django.db import migrations


GITEE_DOCS = 'https://gitee.com/annouimo/zhangyuzhixue-v2/blob/master/docs'


def update_document_entries(apps, schema_editor):
    PortalEntry = apps.get_model('internal_portal', 'PortalEntry')
    updates = {
        '官网品牌口径': {
            'name': '产品边界',
            'description': '当前产品范围、保留能力和明确不再维护的边界。',
            'url': f'{GITEE_DOCS}/current/product-scope.md',
        },
        '架构概览': {
            'name': '系统架构',
            'description': '系统分层、核心组件、数据流和架构原则。',
            'url': f'{GITEE_DOCS}/current/system-architecture.md',
        },
        '服务端架构': {
            'name': '数据架构',
            'description': '服务端数据库、客户端数据包和用户数据边界。',
            'url': f'{GITEE_DOCS}/current/data-architecture.md',
        },
        '测试运行手册': {
            'name': '开发与测试',
            'description': '服务端、Flutter、集成测试和本地开发约定。',
            'url': f'{GITEE_DOCS}/current/development-and-testing.md',
        },
        '开发工作流程': {
            'name': '发布与运维',
            'description': '生产部署、备份、恢复和发布后验证流程。',
            'url': f'{GITEE_DOCS}/current/deployment-and-operations.md',
        },
        '设计文档索引': {
            'name': '项目文档索引',
            'description': '当前文档、决策记录和历史归档的统一入口。',
            'url': f'{GITEE_DOCS}/README.md',
        },
        '页面导航': {
            'name': '仓库地图',
            'description': '代码、文档、资源和发布工具的目录职责。',
            'url': f'{GITEE_DOCS}/current/repository-map.md',
        },
    }
    for old_name, values in updates.items():
        PortalEntry.objects.filter(name=old_name).update(**values)


class Migration(migrations.Migration):

    dependencies = [
        ('internal_portal', '0002_seed_initial_portal'),
    ]

    operations = [
        migrations.RunPython(update_document_entries, migrations.RunPython.noop),
    ]

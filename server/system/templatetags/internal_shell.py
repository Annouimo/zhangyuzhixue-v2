from django import template
from django.urls import reverse

from accounts.roles import ACCESS_REVIEW_WORKBENCH


register = template.Library()


@register.simple_tag
def internal_shell_state(request):
    user = request.user
    namespace = request.resolver_match.namespace if request.resolver_match else ''
    definitions = (
        {
            'key': 'management',
            'namespace': 'management_portal',
            'name': '管理工作台',
            'description': '用户与系统',
            'url': reverse('management_portal:home'),
            'allowed': user.is_active and user.is_staff,
            'logout_url': reverse('admin:logout'),
        },
        {
            'key': 'review',
            'namespace': 'review_workbench',
            'name': '内容工作台',
            'description': '审核与内容维护',
            'url': reverse('review_workbench:home'),
            'allowed': user.is_active and user.has_perm(ACCESS_REVIEW_WORKBENCH),
            'logout_url': reverse('review_workbench:logout'),
        },
        {
            'key': 'handbook',
            'namespace': 'internal_portal',
            'name': '工作手册',
            'description': '内部资料与讲义',
            'url': reverse('internal_portal:index'),
            'allowed': user.is_active and user.has_perm(
                'internal_portal.access_internal_portal'
            ),
            'logout_url': reverse('internal_portal:logout'),
        },
    )
    apps = [app for app in definitions if app['allowed']]
    current = next(
        (app for app in definitions if app['namespace'] == namespace),
        definitions[0],
    )
    return {
        'apps': apps,
        'current': current,
        'logout_url': current['logout_url'],
    }

from django.contrib.auth.models import Group


STUDENT_GROUP = 'student'
CONTENT_REVIEWER_GROUP = 'content_reviewer'
INTERNAL_PORTAL_GROUP = 'internal_portal'

ACCESS_LEVEL_REGULAR = 'regular'
ACCESS_LEVEL_HANDBOOK = 'handbook'
ACCESS_LEVEL_REVIEWER = 'reviewer'
ACCESS_LEVEL_SUPERUSER = 'superuser'
ACCESS_LEVEL_CHOICES = (
    (ACCESS_LEVEL_REGULAR, '普通用户'),
    (ACCESS_LEVEL_HANDBOOK, '工作手册成员'),
    (ACCESS_LEVEL_REVIEWER, '内容审核员'),
)

ACCESS_STUDENT_APP = 'accounts.access_student_app'
ACCESS_REVIEW_WORKBENCH = 'interactions.access_review_workbench'
PUBLISH_CONTRIBUTION = 'interactions.publish_content_contribution'


def add_user_to_group(user, group_name):
    group, _ = Group.objects.get_or_create(name=group_name)
    user.groups.add(group)
    for cache_name in ('_perm_cache', '_group_perm_cache', '_user_perm_cache'):
        user.__dict__.pop(cache_name, None)
    return group


def is_student_user(user):
    return bool(
        user.is_authenticated
        and user.is_active
        and hasattr(user, 'student')
        and user.has_perm(ACCESS_STUDENT_APP)
    )


def is_content_reviewer(user):
    return bool(
        user.is_authenticated
        and user.is_active
        and user.has_perm(ACCESS_REVIEW_WORKBENCH)
    )


def get_access_level(user):
    """Return the effective internal access level without exposing group details."""
    if user.is_superuser:
        return ACCESS_LEVEL_SUPERUSER
    group_names = {group.name for group in user.groups.all()}
    if CONTENT_REVIEWER_GROUP in group_names:
        return ACCESS_LEVEL_REVIEWER
    if INTERNAL_PORTAL_GROUP in group_names:
        return ACCESS_LEVEL_HANDBOOK
    return ACCESS_LEVEL_REGULAR


def get_access_level_label(user):
    labels = dict(ACCESS_LEVEL_CHOICES)
    labels[ACCESS_LEVEL_SUPERUSER] = '系统超级用户'
    return labels[get_access_level(user)]

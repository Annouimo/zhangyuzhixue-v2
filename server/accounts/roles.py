from django.contrib.auth.models import Group


STUDENT_GROUP = 'student'
CONTENT_REVIEWER_GROUP = 'content_reviewer'
INTERNAL_PORTAL_GROUP = 'internal_portal'

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

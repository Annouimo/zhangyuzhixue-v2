from django.contrib.admin.models import CHANGE, LogEntry
from django.contrib.auth.models import Group, User
from django.contrib.contenttypes.models import ContentType
from django.db import transaction

from accounts.roles import (
    ACCESS_LEVEL_CHOICES,
    ACCESS_LEVEL_HANDBOOK,
    ACCESS_LEVEL_REVIEWER,
    ACCESS_LEVEL_SUPERUSER,
    CONTENT_REVIEWER_GROUP,
    INTERNAL_PORTAL_GROUP,
    get_access_level,
)


class AccessLevelError(Exception):
    pass


@transaction.atomic
def set_access_level(user, level, actor=None):
    choices = dict(ACCESS_LEVEL_CHOICES)
    if level not in choices:
        raise AccessLevelError('无效的权限级别')
    locked_user = User.objects.select_for_update().get(pk=user.pk)
    if locked_user.is_superuser or get_access_level(locked_user) == ACCESS_LEVEL_SUPERUSER:
        raise AccessLevelError('系统超级用户只能通过高级数据管理维护')

    groups = {
        group.name: group
        for group in Group.objects.filter(
            name__in=[INTERNAL_PORTAL_GROUP, CONTENT_REVIEWER_GROUP],
        )
    }
    if level in (ACCESS_LEVEL_HANDBOOK, ACCESS_LEVEL_REVIEWER):
        groups.setdefault(INTERNAL_PORTAL_GROUP, Group.objects.get_or_create(
            name=INTERNAL_PORTAL_GROUP,
        )[0])
        locked_user.groups.add(groups[INTERNAL_PORTAL_GROUP])
    else:
        internal_group = groups.get(INTERNAL_PORTAL_GROUP)
        if internal_group:
            locked_user.groups.remove(internal_group)
    if level == ACCESS_LEVEL_REVIEWER:
        groups.setdefault(CONTENT_REVIEWER_GROUP, Group.objects.get_or_create(
            name=CONTENT_REVIEWER_GROUP,
        )[0])
        locked_user.groups.add(groups[CONTENT_REVIEWER_GROUP])
    elif groups.get(CONTENT_REVIEWER_GROUP):
        locked_user.groups.remove(groups[CONTENT_REVIEWER_GROUP])

    if actor:
        LogEntry.objects.create(
            user_id=actor.pk,
            content_type=ContentType.objects.get_for_model(locked_user),
            object_id=str(locked_user.pk),
            object_repr=locked_user.get_username(),
            action_flag=CHANGE,
            change_message=f'权限级别：{choices[level]}',
        )
    return locked_user

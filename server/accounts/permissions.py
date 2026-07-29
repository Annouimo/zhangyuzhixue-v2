from rest_framework import permissions

from accounts.roles import is_content_reviewer, is_student_user


class IsStudent(permissions.BasePermission):
    """仅学生用户可访问"""

    def has_permission(self, request, view):
        return is_student_user(request.user)


class IsContentReviewer(permissions.BasePermission):
    """仅具有内容审核权限的账号可访问。"""

    def has_permission(self, request, view):
        return is_content_reviewer(request.user)

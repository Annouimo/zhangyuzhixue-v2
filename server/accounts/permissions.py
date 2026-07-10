from rest_framework import permissions


class IsStudent(permissions.BasePermission):
    """仅学生用户可访问"""

    def has_permission(self, request, view):
        return hasattr(request.user, 'student')


class IsTeacher(permissions.BasePermission):
    """仅教师用户可访问"""

    def has_permission(self, request, view):
        return hasattr(request.user, 'teacher')

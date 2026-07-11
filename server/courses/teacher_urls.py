"""教师端 API 路由"""
from django.urls import path

from courses import teacher_views as views

urlpatterns = [
    path('assignments/', views.assignment_list_create, name='teacher-assignment-list'),
    path('assignments/<int:id>/', views.assignment_rud, name='teacher-assignment-detail'),
    path('papers/', views.paper_list, name='teacher-paper-list'),
    path('classes/', views.class_list, name='teacher-class-list'),
    path('students/', views.student_list, name='teacher-student-list'),
    path('students/<int:id>/', views.student_detail, name='teacher-student-detail'),
    path('about/', views.about_info, name='teacher-about'),
]

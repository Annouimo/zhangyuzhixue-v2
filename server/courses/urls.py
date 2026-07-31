from django.urls import path

from courses import views

urlpatterns = [
    path('courses/', views.lecture_courses_list, name='lecture-courses'),
    path('courses/<int:course_id>/chapters/', views.chapter_list, name='lecture-chapters'),
    path('chapters/<int:chapter_id>/content/', views.chapter_content, name='lecture-content'),
    path('videos/', views.video_list, name='video-list'),
    path('videos/<int:video_id>/', views.video_detail, name='video-detail'),
]

from django.urls import path

from . import views

app_name = 'internal_portal'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('lectures/', views.lecture_library, name='lecture-library'),
    path(
        'lectures/series/<int:course_id>/', views.lecture_library,
        name='lecture-course',
    ),
    path(
        'lectures/documents/<int:document_id>/', views.lecture_document,
        name='lecture-document',
    ),
    path('', views.index, name='index'),
    path('<slug:slug>/', views.page_detail, name='page-detail'),
]

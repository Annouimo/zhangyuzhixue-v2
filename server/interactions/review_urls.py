from django.urls import path

from . import content_workbench_views, review_views


app_name = 'review_workbench'

urlpatterns = [
    path('login/', review_views.login_view, name='login'),
    path('logout/', review_views.logout_view, name='logout'),
    path('', review_views.queue_view, name='queue'),
    path('<int:contribution_id>/', review_views.detail_view, name='detail'),
    path('questions/', content_workbench_views.question_list, name='question_list'),
    path('questions/new/', content_workbench_views.question_create, name='question_create'),
    path(
        'questions/<int:question_id>/edit/',
        content_workbench_views.question_edit,
        name='question_edit',
    ),
    path('content/tags/', content_workbench_views.tag_list, name='tag_list'),
    path('content/tags/new/', content_workbench_views.tag_create, name='tag_create'),
    path('content/tags/<int:object_id>/edit/', content_workbench_views.tag_edit, name='tag_edit'),
    path('content/cards/', content_workbench_views.card_list, name='card_list'),
    path('content/cards/new/', content_workbench_views.card_create, name='card_create'),
    path(
        'content/cards/<int:object_id>/edit/',
        content_workbench_views.card_edit,
        name='card_edit',
    ),
]

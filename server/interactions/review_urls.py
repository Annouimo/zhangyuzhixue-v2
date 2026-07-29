from django.urls import path

from . import review_views


app_name = 'review_workbench'

urlpatterns = [
    path('login/', review_views.login_view, name='login'),
    path('logout/', review_views.logout_view, name='logout'),
    path('', review_views.queue_view, name='queue'),
    path('<int:contribution_id>/', review_views.detail_view, name='detail'),
]

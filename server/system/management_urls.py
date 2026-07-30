from django.urls import path

from system import management_views


app_name = 'management_portal'

urlpatterns = [
    path('', management_views.home, name='home'),
    path('users/', management_views.user_list, name='user_list'),
    path('users/<int:user_id>/', management_views.user_detail, name='user_detail'),
    path('deletions/', management_views.deletion_list, name='deletion_list'),
]

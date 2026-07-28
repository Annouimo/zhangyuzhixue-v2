from django.urls import path

from . import views

app_name = 'internal_portal'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('', views.index, name='index'),
    path('<slug:slug>/', views.page_detail, name='page-detail'),
]

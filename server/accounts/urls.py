from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from accounts import views

urlpatterns = [
    path('login/', views.login_view, name='auth-login'),
    path('register/', views.register_view, name='auth-register'),
    path('refresh/', TokenRefreshView.as_view(), name='auth-refresh'),
    path('logout/', views.logout_view, name='auth-logout'),
]

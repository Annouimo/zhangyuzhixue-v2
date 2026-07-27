from django.urls import path

from accounts import views

urlpatterns = [
    path('login/', views.login_view, name='auth-login'),
    path('register/', views.register_view, name='auth-register'),
    path('refresh/', views.TokenRefreshView.as_view(), name='auth-refresh'),
    path('logout/', views.logout_view, name='auth-logout'),
    path(
        'deletion/cancel/', views.account_deletion_cancel_view,
        name='account-deletion-cancel',
    ),
    path('me/', views.user_me_view, name='user-me'),
    path('avatar/', views.avatar_upload_view, name='user-avatar'),
    path('checkin/', views.checkin_view, name='user-checkin'),
    path('level-percentile/', views.level_percentile_view, name='user-level-percentile'),
    path('deletion/', views.account_deletion_view, name='account-deletion'),
    path('password/', views.password_change_view, name='password-change'),
]

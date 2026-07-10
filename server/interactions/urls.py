from django.urls import path

from interactions.views import SyncPushView

urlpatterns = [
    path('push/', SyncPushView.as_view(), name='sync-push'),
]

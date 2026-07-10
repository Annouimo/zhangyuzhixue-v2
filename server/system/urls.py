from django.urls import path

from interactions.views import SyncPushView
from system.views import VersionCheckView

urlpatterns = [
    path('qbank/version/', VersionCheckView.as_view(), {'db_type': 'qbank'},
         name='sync-qbank-version'),
    path('lecture/version/', VersionCheckView.as_view(), {'db_type': 'lecture'},
         name='sync-lecture-version'),
    path('push/', SyncPushView.as_view(), name='sync-push'),
]

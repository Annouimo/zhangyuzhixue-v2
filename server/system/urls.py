from django.urls import path

from interactions.sync_views import pull_user_db
from interactions.views import SyncPushView
from system.views import VersionCheckView

urlpatterns = [
    path('qbank/version/', VersionCheckView.as_view(), {'db_type': 'qbank'},
         name='sync-qbank-version'),
    path('courses/version/', VersionCheckView.as_view(), {'db_type': 'courses'},
         name='sync-courses-version'),
    path('push/', SyncPushView.as_view(), name='sync-push'),
    path('user/pull/', pull_user_db, name='sync-user-pull'),
]

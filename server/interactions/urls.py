from django.urls import path

from interactions.pdf_views import pdf_request_token
from interactions.views import SyncPushView

urlpatterns = [
    path('push/', SyncPushView.as_view(), name='sync-push'),
    path('pdf/request-token/', pdf_request_token, name='pdf-request-token'),
]

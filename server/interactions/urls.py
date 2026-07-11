from django.urls import path

from interactions.pdf_views import pdf_request_token

urlpatterns = [
    path('pdf/request-token/', pdf_request_token, name='pdf-request-token'),
]

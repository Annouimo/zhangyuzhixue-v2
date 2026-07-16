from django.urls import path

from interactions.pdf_views import pdf_request_token
from interactions.views import ExamExploreView, ExamPreviewOtherView

urlpatterns = [
    path('pdf/request-token/', pdf_request_token, name='pdf-request-token'),
    path('exam/explore/', ExamExploreView.as_view(), name='exam-explore'),
    path('exam/preview-other/<int:paper_id>/', ExamPreviewOtherView.as_view(), name='exam-preview-other'),
]

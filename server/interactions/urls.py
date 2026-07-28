from django.urls import path

from interactions.pdf_views import pdf_request_token
from interactions.views import ExamExploreView, ExamPreviewOtherView, ExamFavoritesView
from interactions.contribution_views import (
    ContributionConfigView,
    ContributionDetailView,
    ContributionListCreateView,
    ContributionQuestionContextView,
    ContributionResubmitView,
    ContributionWithdrawView,
)

urlpatterns = [
    path('contributions/config/', ContributionConfigView.as_view(),
         name='contribution-config'),
    path('contributions/', ContributionListCreateView.as_view(),
         name='contribution-list-create'),
    path('contributions/<int:contribution_id>/', ContributionDetailView.as_view(),
         name='contribution-detail'),
    path('contributions/<int:contribution_id>/resubmit/',
         ContributionResubmitView.as_view(), name='contribution-resubmit'),
    path('contributions/<int:contribution_id>/withdraw/',
         ContributionWithdrawView.as_view(), name='contribution-withdraw'),
    path('contributions/question/<int:question_id>/context/',
         ContributionQuestionContextView.as_view(), name='contribution-question-context'),
    path('pdf/request-token/', pdf_request_token, name='pdf-request-token'),
    path('exam/explore/', ExamExploreView.as_view(), name='exam-explore'),
    path('exam/preview-other/<int:paper_id>/',
         ExamPreviewOtherView.as_view(), name='exam-preview-other'),
    path('exam/favorites/', ExamFavoritesView.as_view(), name='exam-favorites'),
]

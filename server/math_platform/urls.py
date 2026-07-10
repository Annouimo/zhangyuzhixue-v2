"""
URL configuration for math_platform project.

API endpoints are mounted under /api/v1/.
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from interactions.pdf_views import pdf_view
from system.admin import ToolsView

api_v1 = [
    path('auth/', include('accounts.urls')),
    path('user/', include('accounts.urls')),
    path('qbank/', include('qbank.urls')),
    path('courses/', include('courses.urls')),
    path('interactions/', include('interactions.urls')),
    path('system/', include('system.urls')),
    path('lectures/', include('courses.urls')),

    # sync: version check + push
    path('sync/', include('system.urls')),

    # API documentation
    path('docs/', SpectacularAPIView.as_view(), name='schema'),
    path('docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('admin/system/tools/', ToolsView.as_view(), name='admin-system-tools'),
    path('api/v1/', include(api_v1)),

    # PDF view (browser-facing, no api/v1 prefix)
    path('pdf/view/', pdf_view, name='pdf-view'),
]

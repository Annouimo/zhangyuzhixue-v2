"""
URL configuration for math_platform project.

API endpoints are mounted under /api/v1/.
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from interactions.pdf_views import pdf_view
from system.admin import ToolsView, HelpView

api_v1 = [
    path('auth/', include('accounts.urls')),
    path('user/', include('accounts.urls')),
    path('interactions/', include('interactions.urls')),
    path('lectures/', include('courses.urls')),

    # sync: version check + push
    path('sync/', include('system.urls')),

    # API documentation
    path('docs/', SpectacularAPIView.as_view(), name='schema'),
    path('docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

urlpatterns = [
    path('internal/', include('internal_portal.urls')),

    # 管理工具必须在 admin.site.urls 之前，避免被 admin catch-all 拦截
    path('admin/system/tools/', ToolsView.as_view(), name='admin-system-tools'),
    path('admin/system/help/', HelpView.as_view(), name='admin-system-help'),
    path('admin/', admin.site.urls),
    path('api/v1/', include(api_v1)),

    # PDF view (browser-facing, no api/v1 prefix)
    path('pdf/view/', pdf_view, name='pdf-view'),
]

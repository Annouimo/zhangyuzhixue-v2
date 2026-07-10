"""
URL configuration for math_platform project.

API endpoints are mounted under /api/v1/.
"""
from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

api_v1 = [
    path('auth/', include('accounts.urls')),
    path('qbank/', include('qbank.urls')),
    path('courses/', include('courses.urls')),
    path('interactions/', include('interactions.urls')),
    path('system/', include('system.urls')),

    # API documentation
    path('docs/', SpectacularAPIView.as_view(), name='schema'),
    path('docs/swagger/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include(api_v1)),
]

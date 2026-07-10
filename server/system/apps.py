from django.apps import AppConfig


class SystemConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'system'

    def ready(self):
        """应用就绪后注册审计日志"""
        import audit_registry
        audit_registry.register_all()

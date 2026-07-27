"""
审计日志注册 — 集中管理所有需 auditlog 追踪的模型

设计文档参照：docs/03-服务端/服务端架构.md §6.2 审计范围
"""


def register_all():
    """注册所有需审计的模型（由 system.apps.SystemConfig.ready() 调用）"""
    from auditlog.registry import auditlog as auditlog_registry
    from django.contrib.auth.models import User

    from accounts.models import InvitationCode, Student
    from courses.models import Course, Document
    from qbank.models import (
        BaseQuestion,
        ChoiceExt,
        ConceptTag,
        KnowledgeCard,
        SolutionMethod,
        SolutionStep,
        SubQuestion,
    )
    from system.models import DbVersion

    # ── 应审计的模型 ──────────────────────────────────────────
    # 说明见 docs/03-服务端/服务端架构.md §6.2

    auditlog_registry.register(Student)
    auditlog_registry.register(InvitationCode)
    auditlog_registry.register(BaseQuestion)
    auditlog_registry.register(ChoiceExt)
    auditlog_registry.register(SubQuestion)
    auditlog_registry.register(SolutionMethod)
    auditlog_registry.register(SolutionStep)
    auditlog_registry.register(KnowledgeCard)
    auditlog_registry.register(ConceptTag)
    auditlog_registry.register(Course)
    auditlog_registry.register(Document)
    auditlog_registry.register(DbVersion)
    auditlog_registry.register(User)

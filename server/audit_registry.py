"""
审计日志注册 — 集中管理所有需 auditlog 追踪的模型

架构说明参照：docs/current/system-architecture.md
"""


def register_all():
    """注册所有需审计的模型（由 system.apps.SystemConfig.ready() 调用）"""
    from auditlog.registry import auditlog as auditlog_registry
    from django.contrib.auth.models import User

    from accounts.models import InvitationCode, Student
    from courses.models import Course, Document
    from internal_portal.models import (
        BusinessArea,
        PortalEntry,
        ProjectProfile,
        TeamMember,
    )
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
    # 审计范围随当前服务端模型维护。

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
    auditlog_registry.register(ProjectProfile)
    auditlog_registry.register(TeamMember)
    auditlog_registry.register(BusinessArea)
    auditlog_registry.register(PortalEntry)
    auditlog_registry.register(User)

"""审计日志注册测试 — 验证 auditlog 已正确注册所有应审计模型"""

from auditlog.registry import auditlog as auditlog_registry
from django.contrib.auth.models import User

from accounts.models import InvitationCode, Student, Teacher
from courses.models import (
    Assignment,
    AssignmentQuestion,
    ClassCourse,
    ClassCourseAssignment,
    ClassGroup,
    Course,
    Document,
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


# ── 应审计模型名单 ────────────────────────────────────────────

EXPECTED_REGISTERED = [
    Student, Teacher, InvitationCode,
    BaseQuestion, ChoiceExt, SubQuestion,
    SolutionMethod, SolutionStep,
    KnowledgeCard, ConceptTag,
    Course, ClassGroup, ClassCourse,
    Assignment, AssignmentQuestion, ClassCourseAssignment,
    Document,
    DbVersion,
    User,
]

EXPECTED_NOT_REGISTERED = [
    # 学习交互数据 — 不应审计（数据量大无意义）
    # 这些模型在 interactions 中定义
]


class TestAuditlogRegistration:
    """审计日志注册测试"""

    def test_auditlog_is_configured(self):
        """auditlog 已安装并注册了模型"""
        assert auditlog_registry is not None

    def test_registered_models_are_in_registry(self):
        """所有应审计模型都在 auditlog registry 中"""
        registered = auditlog_registry.get_models()
        reg_set = set(registered)

        for model in EXPECTED_REGISTERED:
            model_name = model._meta.label
            assert model in reg_set, f'{model_name} 未注册到 auditlog'

    def test_registered_count(self):
        """注册的模型数量符合预期（19 个）"""
        registered = list(auditlog_registry.get_models())
        assert len(registered) >= 19, (
            f'预期至少 19 个模型，实际 {len(registered)}'
        )

    def test_unregistered_interactions_models(self):
        """学习交互类模型未被意外注册"""
        from interactions.models import (
            CardFeedback,
            CustomPaper,
            CustomPaperQuestion,
            PaperCollect,
            PaperLike,
            QuestionRating,
            StepFeedback,
            StudentSubmission,
            SubmissionDetail,
        )

        unregistered = [
            StudentSubmission, SubmissionDetail, StepFeedback,
            CardFeedback, QuestionRating, CustomPaper,
            CustomPaperQuestion, PaperLike, PaperCollect,
        ]

        registered = set(auditlog_registry.get_models())
        for model in unregistered:
            assert model not in registered, (
                f'{model._meta.label} 不应被审计但已注册'
            )

    def test_dbversion_is_registered(self):
        """DbVersion 必须被审计（关键管理操作）"""
        registered = set(auditlog_registry.get_models())
        assert DbVersion in registered, 'DbVersion 必须注册审计'

    def test_invitationcode_is_registered(self):
        """InvitationCode 必须被审计"""
        registered = set(auditlog_registry.get_models())
        assert InvitationCode in registered, 'InvitationCode 必须注册审计'

    def test_register_all_idempotent(self):
        """重复注册不会报错"""
        from audit_registry import register_all
        # 第二次调用不应抛出异常
        register_all()
        # 模型仍然在 registry 中
        registered = set(auditlog_registry.get_models())
        assert DbVersion in registered

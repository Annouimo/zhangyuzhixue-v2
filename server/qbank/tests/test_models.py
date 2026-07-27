"""题库模型基础测试"""
import pytest
from django.db import IntegrityError

from qbank.models import (
    BaseQuestion, ConceptTag, KnowledgeCard, SubQuestion,
)


class TestBaseQuestion:
    """题目主表 CRUD + choices"""

    def test_create_choice_question(self, db):
        q = BaseQuestion.objects.create(
            year=2026, exam_type='一模', region='海淀',
            question_type='choice', stem='测试题干',
        )
        assert q.pk > 0
        assert q.year == 2026
        assert q.get_question_type_display() == '选择题'

    def test_create_fill_question(self, db):
        q = BaseQuestion.objects.create(
            year=2025, exam_type='高考', region='北京',
            question_type='fill', stem='____',
        )
        assert q.question_type == 'fill'

    def test_create_solution_question(self, db):
        q = BaseQuestion.objects.create(
            question_type='solution', stem='证明题',
        )
        assert q.question_type == 'solution'

    def test_question_str(self, db):
        q = BaseQuestion.objects.create(
            question_type='choice', stem='测试',
            year=2026, region='海淀', exam_type='一模',
        )
        assert '2026' in str(q)
        assert '海淀' in str(q)

    def test_default_fields(self, db):
        """非必填字段为 null/blank"""
        q = BaseQuestion.objects.create(question_type='choice', stem='x')
        assert q.exam_type == ''
        assert q.region == ''
        assert q.number == ''
        assert q.difficulty is None
        assert q.calculation is None

    def test_type_choices_are_valid(self, db):
        """所有 QUESTION_TYPE_CHOICES 都能创建"""
        for t, _ in BaseQuestion.QUESTION_TYPE_CHOICES:
            q = BaseQuestion.objects.create(question_type=t, stem=f'{t}_test')
            assert q.question_type == t


class TestConceptTag:
    """概念标签 - 树形 + 唯一约束"""

    def test_create_tag(self, db):
        t = ConceptTag.objects.create(name='函数')
        assert t.pk > 0
        assert str(t) == '函数'

    def test_unique_name(self, db):
        ConceptTag.objects.create(name='函数')
        with pytest.raises(IntegrityError):
            ConceptTag.objects.create(name='函数')

    def test_parent_child(self, db):
        parent = ConceptTag.objects.create(name='函数')
        child = ConceptTag.objects.create(name='指数函数', parent=parent)
        assert child.parent == parent
        assert list(parent.children.all()) == [child]


class TestKnowledgeCard:
    """知识卡片 CRUD"""

    def test_create_card(self, db):
        c = KnowledgeCard.objects.create(
            title='辅助角公式', category='定理',
            content=r'$a\sin x + b\cos x = \sqrt{a^2+b^2}\sin(x+\varphi)$'
        )
        assert c.pk > 0
        assert str(c) == '辅助角公式'

    def test_bad_category_not_blocked(self, db):
        """Django choices 不是 DB 约束，非法分类可创建"""
        c = KnowledgeCard.objects.create(
            title='x', category='非法分类', content='x'
        )
        assert c.pk > 0


class TestSubQuestion:
    """子题 - 多题嵌套"""

    def test_create_sub_question(self, db):
        parent = BaseQuestion.objects.create(question_type='solution', stem='大题')
        sub = SubQuestion.objects.create(
            question=parent, sort_order=1, stem='第一小问'
        )
        assert sub.pk > 0
        assert sub.sort_order == 1

import pytest
from django.core.management import call_command
from django.core.management.base import CommandError

from qbank.models import (
    BaseQuestion,
    ChoiceExt,
    SolutionMethod,
    SolutionStep,
    SubQuestion,
)


def create_choice(*, year=2026, options=None):
    question = BaseQuestion.objects.create(
        year=year,
        question_type='choice',
        stem='若 $x=1$，则选择正确答案。',
    )
    ChoiceExt.objects.create(
        question=question,
        options=options or {'A': '1', 'B': '2', 'C': '3', 'D': '4'},
    )
    sub = SubQuestion.objects.create(
        question=question,
        answer='A',
        sort_order=1,
    )
    method = SolutionMethod.objects.create(sub_question=sub, sort_order=1)
    SolutionStep.objects.create(
        method=method,
        step_number=1,
        title='代入',
        content='代入可得答案为 A。',
    )
    return question


@pytest.mark.django_db
def test_valid_question_has_no_blockers():
    create_choice()
    call_command('audit_question_bank', '--fail-on-blockers')


@pytest.mark.django_db
def test_visually_empty_choice_is_a_blocker():
    create_choice(options={'A': '&emsp;', 'B': '2', 'C': '3', 'D': '4'})
    with pytest.raises(CommandError, match='题库存在发布阻断项'):
        call_command('audit_question_bank', '--fail-on-blockers')


@pytest.mark.django_db
def test_test_data_is_excluded_by_default():
    create_choice(year=2099, options={'A': '', 'B': '2', 'C': '3', 'D': '4'})
    call_command('audit_question_bank', '--fail-on-blockers')

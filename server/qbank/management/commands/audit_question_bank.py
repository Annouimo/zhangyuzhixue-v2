import html
import json
import re
from collections import Counter
from pathlib import Path, PurePosixPath

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db.models import Prefetch

from qbank.models import (
    BaseQuestion,
    KnowledgeCard,
    SolutionMethod,
    SolutionStep,
    SubQuestion,
)


HTML_TAG_RE = re.compile(r'<[^>]+>')
CHOICE_KEYS = {'A', 'B', 'C', 'D'}


def visible_text(value):
    if not isinstance(value, str):
        return ''
    return HTML_TAG_RE.sub('', html.unescape(value)).strip()


def audit_question_bank(include_test_data=False):
    findings = []

    def add(level, code, object_type, object_id, message):
        findings.append({
            'level': level,
            'code': code,
            'object_type': object_type,
            'object_id': object_id,
            'message': message,
        })

    steps = SolutionStep.objects.order_by('step_number')
    methods = SolutionMethod.objects.order_by('sort_order').prefetch_related(
        Prefetch('solution_steps', queryset=steps),
    )
    subs = SubQuestion.objects.order_by('sort_order').prefetch_related(
        'children',
        Prefetch('solution_methods', queryset=methods),
    )
    questions = BaseQuestion.objects.prefetch_related(
        'question_concept_tags',
        Prefetch('sub_questions', queryset=subs),
    ).select_related('choice_ext')
    if not include_test_data:
        questions = questions.exclude(year=2099)

    card_titles = set(KnowledgeCard.objects.values_list('title', flat=True))
    image_root = (Path(settings.BASE_DIR) / 'static/questions/images').resolve()
    question_count = 0

    for question in questions.iterator(chunk_size=100):
        question_count += 1
        if not visible_text(question.stem):
            add('blocker', 'empty_stem', 'question', question.pk, '题干为空')

        if not question.question_concept_tags.all():
            add('warning', 'missing_concept_tag', 'question', question.pk,
                '未关联概念标签')

        images = question.images
        if not isinstance(images, list):
            add('blocker', 'invalid_images', 'question', question.pk,
                'images 必须是列表')
        else:
            for image in images:
                if not isinstance(image, str) or not image.strip():
                    add('blocker', 'invalid_image_path', 'question', question.pk,
                        '图片路径必须是非空字符串')
                    continue
                normalized = image.replace('\\', '/')
                path = PurePosixPath(normalized)
                if path.is_absolute() or '..' in path.parts:
                    add('blocker', 'unsafe_image_path', 'question', question.pk,
                        f'不安全的图片路径: {image}')
                    continue
                resolved = (image_root / Path(*path.parts)).resolve()
                if image_root not in resolved.parents or not resolved.is_file():
                    add('blocker', 'missing_image_file', 'question', question.pk,
                        f'图片文件不存在: {image}')

        if question.question_type == 'choice':
            try:
                options = question.choice_ext.options
            except BaseQuestion.choice_ext.RelatedObjectDoesNotExist:
                add('blocker', 'missing_choice_ext', 'question', question.pk,
                    '选择题缺少选项记录')
                options = None
            if not isinstance(options, dict):
                if options is not None:
                    add('blocker', 'invalid_choice_options', 'question',
                        question.pk, '选项必须是对象')
            else:
                keys = {str(key).upper() for key in options}
                if keys != CHOICE_KEYS:
                    add('blocker', 'invalid_choice_keys', 'question', question.pk,
                        f'选项键应为 A/B/C/D，实际为 {sorted(keys)}')
                empty = sorted(
                    str(key).upper() for key, value in options.items()
                    if not visible_text(value)
                )
                if empty:
                    add('blocker', 'empty_choice_options', 'question',
                        question.pk, f'空选项: {"/".join(empty)}')

        sub_questions = list(question.sub_questions.all())
        if not sub_questions:
            add('blocker', 'missing_subquestion', 'question', question.pk,
                '题目没有小题记录')
            continue

        duplicate_sub_orders = [
            order for order, count in Counter(
                sub.sort_order for sub in sub_questions
            ).items() if count > 1
        ]
        if duplicate_sub_orders:
            add('blocker', 'duplicate_sub_order', 'question', question.pk,
                f'小题排序重复: {sorted(duplicate_sub_orders)}')

        for sub in sub_questions:
            is_leaf = not sub.children.all()
            if is_leaf and not visible_text(sub.answer):
                add('warning', 'missing_leaf_answer', 'subquestion', sub.pk,
                    '叶子小题答案为空')
            if (question.question_type == 'choice' and is_leaf and
                    visible_text(sub.answer).upper() not in CHOICE_KEYS):
                add('blocker', 'invalid_choice_answer', 'subquestion', sub.pk,
                    f'选择题答案无效: {sub.answer!r}')

            solution_methods = list(sub.solution_methods.all())
            if not solution_methods:
                add('blocker', 'missing_solution_method', 'subquestion', sub.pk,
                    '小题没有解法')
                continue
            duplicate_method_orders = [
                order for order, count in Counter(
                    method.sort_order for method in solution_methods
                ).items() if count > 1
            ]
            if duplicate_method_orders:
                add('blocker', 'duplicate_method_order', 'subquestion', sub.pk,
                    f'解法排序重复: {sorted(duplicate_method_orders)}')

            for method in solution_methods:
                solution_steps = list(method.solution_steps.all())
                if not solution_steps:
                    add('blocker', 'missing_solution_step', 'method', method.pk,
                        '解法没有步骤')
                    continue
                duplicate_step_numbers = [
                    number for number, count in Counter(
                        step.step_number for step in solution_steps
                    ).items() if count > 1
                ]
                if duplicate_step_numbers:
                    add('blocker', 'duplicate_step_number', 'method', method.pk,
                        f'步骤编号重复: {sorted(duplicate_step_numbers)}')
                for step in solution_steps:
                    if not visible_text(step.content):
                        add('blocker', 'empty_solution_step', 'step', step.pk,
                            '解题步骤内容为空')
                    titles = step.card_titles
                    if not isinstance(titles, list):
                        add('blocker', 'invalid_card_titles', 'step', step.pk,
                            'card_titles 必须是列表')
                        continue
                    missing = sorted({title for title in titles
                                      if title not in card_titles})
                    if missing:
                        add('blocker', 'missing_knowledge_card', 'step', step.pk,
                            f'知识卡片不存在: {missing}')

    counts = Counter(item['level'] for item in findings)
    return {
        'question_count': question_count,
        'blocker_count': counts['blocker'],
        'warning_count': counts['warning'],
        'findings': findings,
    }


class Command(BaseCommand):
    help = '只读审查题库的结构完整性和可发布性'

    def add_arguments(self, parser):
        parser.add_argument('--json', action='store_true', dest='as_json')
        parser.add_argument('--include-test-data', action='store_true')
        parser.add_argument('--fail-on-blockers', action='store_true')

    def handle(self, *args, **options):
        report = audit_question_bank(options['include_test_data'])
        if options['as_json']:
            self.stdout.write(json.dumps(report, ensure_ascii=False, indent=2))
        else:
            self.stdout.write(
                f"审查 {report['question_count']} 道题："
                f"{report['blocker_count']} 个 blocker，"
                f"{report['warning_count']} 个 warning"
            )
            for item in report['findings']:
                self.stdout.write(
                    f"[{item['level'].upper()}] {item['code']} "
                    f"{item['object_type']}#{item['object_id']}: "
                    f"{item['message']}"
                )
        if options['fail_on_blockers'] and report['blocker_count']:
            raise CommandError('题库存在发布阻断项')

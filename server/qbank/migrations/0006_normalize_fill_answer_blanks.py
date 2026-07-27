import re

from django.db import migrations


CANONICAL_BLANK = r'$\underline{\hspace{2cm}}$'
LEGACY_ESCAPED_BLANK = re.compile(r'\$?(?:\\{1,2}_){3,}')
LEGACY_PLAIN_BLANK = re.compile(r'\$?_{3,}')
UNWRAPPED_LATEX_BLANK = re.compile(
    r'(?<!\$)\\underline\{\\hspace\{[0-9.]+(?:cm|em|pt)\}\}(?!\$)'
)


def normalize_fill_blanks(apps, schema_editor):
    BaseQuestion = apps.get_model('qbank', 'BaseQuestion')
    for question in BaseQuestion.objects.filter(question_type='fill').iterator():
        normalized = LEGACY_ESCAPED_BLANK.sub(
            lambda _: CANONICAL_BLANK, question.stem
        )
        normalized = LEGACY_PLAIN_BLANK.sub(
            lambda _: CANONICAL_BLANK, normalized
        )
        normalized = UNWRAPPED_LATEX_BLANK.sub(
            lambda _: CANONICAL_BLANK, normalized
        )
        if normalized != question.stem:
            BaseQuestion.objects.filter(pk=question.pk).update(stem=normalized)


def restore_legacy_blanks(apps, schema_editor):
    BaseQuestion = apps.get_model('qbank', 'BaseQuestion')
    legacy_blank = r'\\_\\_\\_\\_\\_\\_\\_'
    for question in BaseQuestion.objects.filter(question_type='fill').iterator():
        restored = question.stem.replace(CANONICAL_BLANK, legacy_blank)
        if restored != question.stem:
            BaseQuestion.objects.filter(pk=question.pk).update(stem=restored)


class Migration(migrations.Migration):

    dependencies = [
        ('qbank', '0005_restore_question_134_options'),
    ]

    operations = [
        migrations.RunPython(normalize_fill_blanks, restore_legacy_blanks),
    ]

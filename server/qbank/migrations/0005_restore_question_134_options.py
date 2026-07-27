from django.db import migrations


QUESTION_ID = 134
IMAGE_PATH = 'mock1_2023_haidian_q08_options.webp'
RESTORED_OPTIONS = {
    'A': '图 A',
    'B': '图 B',
    'C': '图 C',
    'D': '图 D',
}
ORIGINAL_OPTIONS = {
    'A': '&emsp;',
    'B': '&emsp;',
    'C': '&emsp;',
    'D': '',
}


def restore_options(apps, schema_editor):
    BaseQuestion = apps.get_model('qbank', 'BaseQuestion')
    ChoiceExt = apps.get_model('qbank', 'ChoiceExt')
    question = BaseQuestion.objects.filter(
        pk=QUESTION_ID,
        year=2023,
        exam_type='一模',
        region='海淀',
        number='8',
        question_type='choice',
    ).first()
    if question is None:
        return
    question.images = [IMAGE_PATH]
    question.save(update_fields=['images'])
    ChoiceExt.objects.filter(question_id=QUESTION_ID).update(
        options=RESTORED_OPTIONS,
    )


def revert_options(apps, schema_editor):
    BaseQuestion = apps.get_model('qbank', 'BaseQuestion')
    ChoiceExt = apps.get_model('qbank', 'ChoiceExt')
    BaseQuestion.objects.filter(
        pk=QUESTION_ID,
        images=[IMAGE_PATH],
    ).update(images=[])
    ChoiceExt.objects.filter(
        question_id=QUESTION_ID,
        options=RESTORED_OPTIONS,
    ).update(options=ORIGINAL_OPTIONS)


class Migration(migrations.Migration):

    dependencies = [
        ('qbank', '0004_subquestion_explanation'),
    ]

    operations = [
        migrations.RunPython(restore_options, revert_options),
    ]

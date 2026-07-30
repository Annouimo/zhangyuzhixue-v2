import re

from django.db import migrations


IMAGE_TAG_PATTERN = re.compile(r'<img[^>]*>', re.IGNORECASE)


def clean_choice_option_image_artifacts(apps, schema_editor):
    ChoiceExt = apps.get_model('qbank', 'ChoiceExt')

    for choice_ext in ChoiceExt.objects.iterator():
        options = choice_ext.options
        if not isinstance(options, dict):
            continue

        cleaned = {}
        changed = False
        for key, value in options.items():
            if isinstance(value, str):
                clean_value = IMAGE_TAG_PATTERN.sub('', value).rstrip()
                cleaned[key] = clean_value
                changed = changed or clean_value != value
            else:
                cleaned[key] = value

        if changed:
            ChoiceExt.objects.filter(pk=choice_ext.pk).update(options=cleaned)


class Migration(migrations.Migration):
    dependencies = [('qbank', '0009_contentchangelog')]

    operations = [
        migrations.RunPython(
            clean_choice_option_image_artifacts,
            migrations.RunPython.noop,
        ),
    ]

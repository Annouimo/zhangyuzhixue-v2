from django.db import migrations


REPLACEMENTS = (
    (r'`\{a, b, c\}`', r'$\{a, b, c\}$'),
    (r'`\{x | P(x)\}`', r'$\{x \mid P(x)\}$'),
)


def normalize_inline_math(apps, schema_editor):
    Document = apps.get_model('courses', 'Document')
    for document in Document.objects.all().iterator():
        normalized = document.md_content
        for source, target in REPLACEMENTS:
            normalized = normalized.replace(source, target)
        if normalized != document.md_content:
            Document.objects.filter(pk=document.pk).update(md_content=normalized)


def restore_inline_code(apps, schema_editor):
    Document = apps.get_model('courses', 'Document')
    for document in Document.objects.all().iterator():
        restored = document.md_content
        for source, target in REPLACEMENTS:
            restored = restored.replace(target, source)
        if restored != document.md_content:
            Document.objects.filter(pk=document.pk).update(md_content=restored)


class Migration(migrations.Migration):

    dependencies = [
        ('courses', '0002_alter_classcourseassignment_deadline'),
    ]

    operations = [
        migrations.RunPython(normalize_inline_math, restore_inline_code),
    ]

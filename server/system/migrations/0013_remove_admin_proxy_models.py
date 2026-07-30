from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ('system', '0012_merge_20260729_1500'),
    ]
    operations = [
        migrations.DeleteModel(name='AdminHelpProxy'),
        migrations.DeleteModel(name='SystemToolsProxy'),
    ]

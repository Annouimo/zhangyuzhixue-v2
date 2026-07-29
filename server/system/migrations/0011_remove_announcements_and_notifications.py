from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ('system', '0010_studentnotification'),
    ]

    operations = [
        migrations.DeleteModel(name='StudentNotification'),
        migrations.DeleteModel(name='Announcement'),
    ]

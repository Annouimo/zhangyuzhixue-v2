from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0010_unify_user_roles'),
    ]
    operations = [
        migrations.DeleteModel(name='InvitationCode'),
    ]

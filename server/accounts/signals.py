from django.db.models.signals import post_save
from django.dispatch import receiver

from accounts.models import Student
from accounts.roles import STUDENT_GROUP, add_user_to_group


@receiver(post_save, sender=Student)
def grant_student_role(sender, instance, created, **kwargs):
    if created:
        add_user_to_group(instance.user, STUDENT_GROUP)

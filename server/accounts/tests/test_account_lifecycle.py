from datetime import timedelta

import pytest
from django.contrib.auth.models import User
from django.core.management import call_command
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import AccountDeletionRequest, Student


@pytest.fixture
def account(db):
    user = User.objects.create_user(
        'delete_me', password='test-password-123', first_name='测试学生',
    )
    student = user.student
    student.school = '测试学校'
    student.phone = '13800000000'
    student.gaokao_year = 2027
    student.save(update_fields=['school', 'phone', 'gaokao_year', 'updated_at'])
    return user, student


def authenticated_client(user):
    client = APIClient()
    token = RefreshToken.for_user(user).access_token
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    return client


@pytest.mark.django_db
class TestAccountDeletion:
    def test_request_requires_current_password(self, account):
        user, _ = account
        response = authenticated_client(user).post(
            reverse('account-deletion'),
            {'current_password': 'wrong-password'},
            format='json',
        )
        assert response.status_code == 400
        user.refresh_from_db()
        assert user.is_active is True

    def test_request_disables_and_hides_account(self, account):
        user, student = account
        client = authenticated_client(user)
        response = client.post(
            reverse('account-deletion'),
            {'current_password': 'test-password-123'},
            format='json',
        )
        assert response.status_code == 200

        user.refresh_from_db()
        student.refresh_from_db()
        deletion_request = AccountDeletionRequest.objects.get(user=user)
        assert user.is_active is False
        assert student.account_status == Student.AccountStatus.PENDING_DELETION
        assert deletion_request.scheduled_for > timezone.now()

        blocked = client.get(reverse('user-me'))
        assert blocked.status_code == 401

    def test_cancel_restores_account(self, account):
        user, student = account
        authenticated_client(user).post(
            reverse('account-deletion'),
            {'current_password': 'test-password-123'},
            format='json',
        )

        response = APIClient().post(
            reverse('account-deletion-cancel'),
            {'username': 'delete_me', 'password': 'test-password-123'},
            format='json',
        )
        assert response.status_code == 200
        user.refresh_from_db()
        student.refresh_from_db()
        deletion_request = AccountDeletionRequest.objects.get(user=user)
        assert user.is_active is True
        assert student.account_status == Student.AccountStatus.ACTIVE
        assert deletion_request.status == AccountDeletionRequest.Status.CANCELLED

    def test_due_request_is_irreversibly_anonymized(self, account):
        user, student = account
        original_user_id = user.pk
        authenticated_client(user).post(
            reverse('account-deletion'),
            {'current_password': 'test-password-123'},
            format='json',
        )
        AccountDeletionRequest.objects.filter(user=user).update(
            scheduled_for=timezone.now() - timedelta(minutes=1),
        )

        call_command('anonymize_deleted_accounts')

        user.refresh_from_db()
        student.refresh_from_db()
        deletion_request = AccountDeletionRequest.objects.get(user_id=original_user_id)
        assert user.username.startswith('deleted_')
        assert user.has_usable_password() is False
        assert user.first_name == ''
        assert student.student_id.startswith('deleted_')
        assert student.school == ''
        assert student.phone == ''
        assert student.account_status == Student.AccountStatus.ANONYMIZED
        assert deletion_request.status == AccountDeletionRequest.Status.ANONYMIZED


@pytest.mark.django_db
class TestPasswordChange:
    def test_change_password_revokes_existing_token(self, account):
        user, _ = account
        client = authenticated_client(user)
        response = client.post(
            reverse('password-change'),
            {
                'current_password': 'test-password-123',
                'new_password': 'new-secure-password-456',
            },
            format='json',
        )
        assert response.status_code == 200
        assert client.get(reverse('user-me')).status_code == 401

        login = APIClient().post(reverse('auth-login'), {
            'username': 'delete_me',
            'password': 'new-secure-password-456',
        }, format='json')
        assert login.status_code == 200

    def test_change_password_rejects_wrong_current_password(self, account):
        user, _ = account
        response = authenticated_client(user).post(
            reverse('password-change'),
            {
                'current_password': 'wrong-password',
                'new_password': 'new-secure-password-456',
            },
            format='json',
        )
        assert response.status_code == 400

"""Data model for the authentication module (specification section 31)."""

from __future__ import annotations

import uuid
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.db import models
from django.utils import timezone

from . import phone as phone_utils


class AccountStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    SUSPENDED = "SUSPENDED", "Suspended"
    DELETED = "DELETED", "Deleted"


class CustomerManager(BaseUserManager):
    """Creates customers keyed by phone number.

    There is no `create_superuser` taking a password because passwords are not
    part of the MVP (section 37); staff access is granted by flag on an
    existing customer instead.
    """

    def create_customer(
        self, *, phone_number: str, full_name: str, email: str
    ) -> "Customer":
        digits = phone_utils.normalise(phone_number)
        if not phone_utils.is_valid(digits):
            raise ValueError("phone_number is not a valid Tanzanian mobile number")

        customer = self.model(
            phone_number=digits,
            full_name=full_name.strip(),
            email=self.normalize_email(email).strip().lower(),
            phone_verified=True,
        )
        # Nothing can authenticate by password; the field exists only because
        # AbstractBaseUser requires it.
        customer.set_unusable_password()
        customer.save(using=self._db)
        return customer


class Customer(AbstractBaseUser):
    """A customer of the platform, identified by their phone number.

    `last_login` and `password` come from AbstractBaseUser. The password is
    always unusable -- keeping the field costs nothing and keeps the Django
    admin and session machinery working.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    full_name = models.CharField(max_length=150)

    # The canonical nine digits. Uniqueness is enforced here, in the database,
    # rather than by a check-then-insert in the view: two devices registering
    # the same number at the same moment would both pass a pre-check.
    phone_number = models.CharField(max_length=9, unique=True, db_index=True)

    email = models.EmailField()
    phone_verified = models.BooleanField(default=False)
    account_status = models.CharField(
        max_length=16,
        choices=AccountStatus.choices,
        default=AccountStatus.ACTIVE,
    )
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CustomerManager()

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = ["full_name", "email"]

    class Meta:
        db_table = "customers"
        indexes = [models.Index(fields=["email"])]

    def __str__(self) -> str:
        return f"{self.full_name} ({phone_utils.mask(self.phone_number)})"

    @property
    def is_active(self) -> bool:
        """Django checks this before allowing authentication."""
        return self.account_status == AccountStatus.ACTIVE

    def has_perm(self, perm, obj=None) -> bool:
        return self.is_staff

    def has_module_perms(self, app_label) -> bool:
        return self.is_staff


class OtpPurpose(models.TextChoices):
    REGISTRATION = "REGISTRATION", "Registration"
    LOGIN = "LOGIN", "Login"
    PHONE_CHANGE = "PHONE_CHANGE", "Phone change"


class OtpStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    VERIFIED = "VERIFIED", "Verified"
    EXPIRED = "EXPIRED", "Expired"
    BLOCKED = "BLOCKED", "Blocked"
    SUPERSEDED = "SUPERSEDED", "Superseded"


class OtpRequest(models.Model):
    """A pending verification, held apart from the customer record.

    Section 31 asks for this separation, and it is what allows registration to
    persist nothing at all for an unverified number: until the code is checked,
    the only trace of the attempt is a row here.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(max_length=9, db_index=True)
    purpose = models.CharField(max_length=16, choices=OtpPurpose.choices)

    # The code is never stored. See `otp.hash_code`.
    otp_hash = models.CharField(max_length=64)

    expires_at = models.DateTimeField()
    attempt_count = models.PositiveSmallIntegerField(default=0)
    status = models.CharField(
        max_length=16, choices=OtpStatus.choices, default=OtpStatus.PENDING
    )

    # Set for PHONE_CHANGE, where the request belongs to a signed-in customer
    # and the phone_number above is the *new* number being claimed.
    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="otp_requests",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    last_sent_at = models.DateTimeField(default=timezone.now)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "otp_requests"
        indexes = [
            # The hot lookup: the live request for this number and purpose.
            models.Index(fields=["phone_number", "purpose", "status"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self) -> str:
        return (
            f"{self.purpose} for {phone_utils.mask(self.phone_number)} "
            f"({self.status})"
        )

    # --- Lifecycle ----------------------------------------------------------

    @property
    def is_expired(self) -> bool:
        return timezone.now() >= self.expires_at

    @property
    def attempts_remaining(self) -> int:
        return max(0, settings.OTP_MAX_ATTEMPTS - self.attempt_count)

    @property
    def resend_available_at(self):
        return self.last_sent_at + timedelta(
            seconds=settings.OTP_RESEND_COOLDOWN_SECONDS
        )

    @property
    def seconds_until_resend(self) -> int:
        remaining = (self.resend_available_at - timezone.now()).total_seconds()
        return max(0, int(remaining))

    @property
    def seconds_until_expiry(self) -> int:
        remaining = (self.expires_at - timezone.now()).total_seconds()
        return max(0, int(remaining))

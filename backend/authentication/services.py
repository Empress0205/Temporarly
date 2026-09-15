"""The authentication flows.

Views stay thin: they validate input and call one function here. Each function
owns the rules for its flow, which keeps the specification's requirements in
one readable place per journey.
"""

from __future__ import annotations

import logging

from django.conf import settings
from django.db import IntegrityError, transaction
from rest_framework_simplejwt.token_blacklist.models import (
    BlacklistedToken,
    OutstandingToken,
)
from rest_framework_simplejwt.tokens import RefreshToken

from . import otp
from . import phone as phone_utils
from .errors import ApiError, ErrorCode
from .models import AccountStatus, Customer, OtpPurpose, OtpRequest

logger = logging.getLogger(__name__)


# --- Shared helpers ----------------------------------------------------------


def clean_phone(raw: str) -> str:
    """Normalise and validate, or fail with the client's phone error."""
    digits = phone_utils.normalise(raw)
    if not phone_utils.is_valid(digits):
        raise ApiError(
            ErrorCode.VALIDATION_FAILED,
            "Please enter a valid Tanzanian phone number.",
            details={"field": "phone_number"},
        )
    return digits


def _customer_for(phone_number: str) -> Customer | None:
    return Customer.objects.filter(phone_number=phone_number).first()


def _assert_usable(customer: Customer) -> None:
    """A suspended account must not be able to obtain a session."""
    if customer.account_status != AccountStatus.ACTIVE:
        raise ApiError(
            ErrorCode.ACCOUNT_SUSPENDED,
            "This account is not active. Please contact support.",
            http_status=403,
        )


def issue_tokens(customer: Customer) -> dict:
    """Mints an access/refresh pair for a verified customer."""
    refresh = RefreshToken.for_user(customer)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "access_expires_in": int(
            settings.SIMPLE_JWT["ACCESS_TOKEN_LIFETIME"].total_seconds()
        ),
    }


def revoke_all_sessions(customer: Customer, *, keep: str | None = None) -> int:
    """Blacklists every outstanding refresh token for a customer.

    Used when the login identifier changes. `keep` preserves the current
    device's token so the customer who made the change is not signed out of the
    app they are holding.
    """
    revoked = 0
    for token in OutstandingToken.objects.filter(user=customer):
        if keep is not None and token.token == keep:
            continue
        _, created = BlacklistedToken.objects.get_or_create(token=token)
        revoked += int(created)
    return revoked


# --- Registration ------------------------------------------------------------


def register_request_otp(raw_phone: str) -> OtpRequest:
    """Starts registration. Nothing is persisted about the person yet.

    The number is checked here so the customer is told immediately rather than
    after receiving a code they cannot use (section 15).
    """
    phone_number = clean_phone(raw_phone)

    if _customer_for(phone_number) is not None:
        raise ApiError(
            ErrorCode.PHONE_ALREADY_REGISTERED,
            "This phone number is already registered.",
            http_status=409,
        )

    return otp.issue(phone_number=phone_number, purpose=OtpPurpose.REGISTRATION)


def register_verify(
    *, raw_phone: str, code: str, full_name: str, email: str
) -> tuple[Customer, dict]:
    """Verifies the code and creates the account in the same transaction.

    The profile arrives here rather than at request time, so an abandoned
    registration leaves only an expiring OTP row behind -- no half-formed
    customer to clean up.

    Deliberately not wrapped in a single transaction: `otp.verify` must commit
    the attempt it recorded, and an outer rollback would undo that.
    """
    phone_number = clean_phone(raw_phone)
    otp.verify(
        phone_number=phone_number, purpose=OtpPurpose.REGISTRATION, code=code
    )

    if settings.ENFORCE_EMAIL_UNIQUENESS:
        if Customer.objects.filter(email__iexact=email.strip()).exists():
            raise ApiError(
                ErrorCode.VALIDATION_FAILED,
                "This email address is already in use.",
                details={"field": "email"},
            )

    try:
        customer = Customer.objects.create_customer(
            phone_number=phone_number, full_name=full_name, email=email
        )
    except IntegrityError:
        # Two devices registered the same number at once. The unique index is
        # the arbiter -- a check before the insert would let both through.
        raise ApiError(
            ErrorCode.PHONE_ALREADY_REGISTERED,
            "This phone number is already registered.",
            http_status=409,
        ) from None

    logger.info("Registered customer %s", customer.id)
    return customer, issue_tokens(customer)


# --- Login -------------------------------------------------------------------


def login_request_otp(raw_phone: str) -> OtpRequest:
    """An unknown number is refused; login never creates an account."""
    phone_number = clean_phone(raw_phone)

    customer = _customer_for(phone_number)
    if customer is None:
        raise ApiError(
            ErrorCode.PHONE_NOT_REGISTERED,
            "This phone number is not registered.",
            http_status=404,
        )

    # Checked before sending, so a suspended account costs no SMS.
    _assert_usable(customer)

    return otp.issue(phone_number=phone_number, purpose=OtpPurpose.LOGIN)


def login_verify(*, raw_phone: str, code: str) -> tuple[Customer, dict]:
    phone_number = clean_phone(raw_phone)
    otp.verify(phone_number=phone_number, purpose=OtpPurpose.LOGIN, code=code)

    customer = _customer_for(phone_number)
    if customer is None:
        # The account was removed between the code being sent and verified.
        raise ApiError(
            ErrorCode.PHONE_NOT_REGISTERED,
            "This phone number is not registered.",
            http_status=404,
        )
    _assert_usable(customer)

    return customer, issue_tokens(customer)


# --- Phone change ------------------------------------------------------------


def phone_change_request(*, customer: Customer, raw_phone: str) -> OtpRequest:
    """Sends a code to the *new* number, proving the customer holds it."""
    new_number = clean_phone(raw_phone)

    if new_number == customer.phone_number:
        raise ApiError(
            ErrorCode.PHONE_SAME_AS_CURRENT,
            "This is already your registered number.",
            http_status=409,
        )

    if _customer_for(new_number) is not None:
        raise ApiError(
            ErrorCode.PHONE_BELONGS_TO_OTHER,
            "This phone number is associated with another Jihudumie account.",
            http_status=409,
        )

    return otp.issue(
        phone_number=new_number,
        purpose=OtpPurpose.PHONE_CHANGE,
        customer=customer,
    )


def phone_change_verify(
    *, customer: Customer, raw_phone: str, code: str, current_refresh: str | None
) -> Customer:
    """Moves the account to the new number, and only then.

    Ownership is re-checked here, not only at request time: the number could
    have been registered by someone else while this code was in flight.
    """
    new_number = clean_phone(raw_phone)

    request = otp.verify(
        phone_number=new_number, purpose=OtpPurpose.PHONE_CHANGE, code=code
    )

    # The code must belong to this customer's change request, not to a code
    # someone else happens to have outstanding for the same number.
    if request.customer_id != customer.id:
        raise ApiError(
            ErrorCode.OTP_NOT_FOUND,
            "No phone number change is in progress for this account.",
            http_status=404,
        )

    if Customer.objects.filter(phone_number=new_number).exists():
        raise ApiError(
            ErrorCode.PHONE_BELONGS_TO_OTHER,
            "This phone number is associated with another Jihudumie account.",
            http_status=409,
        )

    customer.phone_number = new_number
    try:
        customer.save(update_fields=["phone_number", "updated_at"])
    except IntegrityError:
        raise ApiError(
            ErrorCode.PHONE_BELONGS_TO_OTHER,
            "This phone number is associated with another Jihudumie account.",
            http_status=409,
        ) from None

    if settings.PHONE_CHANGE_REVOKES_OTHER_SESSIONS:
        revoked = revoke_all_sessions(customer, keep=current_refresh)
        logger.info(
            "Phone change for %s revoked %d other session(s)",
            customer.id,
            revoked,
        )

    return customer


# --- Session -----------------------------------------------------------------


def logout(refresh_token: str) -> None:
    """Revokes the refresh token.

    Idempotent: signing out twice, or with a token that has already expired, is
    a success from the customer's point of view. The access token remains valid
    until it expires, which is why its lifetime is short.
    """
    try:
        RefreshToken(refresh_token).blacklist()
    except Exception:  # noqa: BLE001 - any invalid token is already "logged out"
        logger.info("Logout presented an unusable refresh token; treating as done")


def resend_code(*, raw_phone: str, purpose: str) -> OtpRequest:
    phone_number = clean_phone(raw_phone)
    return otp.resend(phone_number=phone_number, purpose=purpose)

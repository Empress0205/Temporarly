"""The OTP lifecycle: issue, resend, verify.

Everything the specification says about codes (sections 8-13, 32, 33) lives
here rather than in the views, so registration, login and phone change all get
identical behaviour and there is one place to audit.
"""

from __future__ import annotations

import hashlib
import hmac
import logging
import secrets
from dataclasses import dataclass
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from . import phone as phone_utils
from . import sms
from .errors import ApiError, ErrorCode
from .models import Customer, OtpPurpose, OtpRequest, OtpStatus

logger = logging.getLogger(__name__)


# --- Code generation and hashing --------------------------------------------


def generate_code() -> str:
    """A cryptographically random code of the configured length.

    Returned as a string throughout: `012345` is a perfectly valid code, and
    treating it as an integer would silently turn it into `12345`.
    """
    upper = 10**settings.OTP_LENGTH
    return str(secrets.randbelow(upper)).zfill(settings.OTP_LENGTH)


def hash_code(code: str, *, phone_number: str, purpose: str) -> str:
    """HMAC of the code, bound to the number and purpose it was issued for.

    Plain codes are never stored (section 32). Binding the hash to phone and
    purpose means a registration code cannot be replayed against the login
    endpoint even if the digits happen to match.

    A 6-digit space is small, so the hash is not what makes this safe -- the
    attempt limit and the rate limits are. HMAC-SHA256 with a server-side
    pepper keeps verification cheap while ensuring a database leak alone does
    not reveal any live code.
    """
    message = f"{purpose}:{phone_number}:{code}".encode()
    return hmac.new(
        settings.OTP_PEPPER.encode(), message, hashlib.sha256
    ).hexdigest()


def _matches(request: OtpRequest, code: str) -> bool:
    candidate = hash_code(
        code, phone_number=request.phone_number, purpose=request.purpose
    )
    return hmac.compare_digest(candidate, request.otp_hash)


# --- Rate limiting (section 33) ---------------------------------------------


def _enforce_request_limits(phone_number: str) -> None:
    """Caps how often a number can trigger an SMS.

    Guards against OTP flooding, SMS abuse and provider cost. Applied to the
    normalised number, so spelling the same number differently does not reset
    the count.
    """
    now = timezone.now()

    hourly = OtpRequest.objects.filter(
        phone_number=phone_number, created_at__gte=now - timedelta(hours=1)
    ).count()
    if hourly >= settings.OTP_MAX_REQUESTS_PER_HOUR:
        raise ApiError(
            ErrorCode.RATE_LIMITED,
            "Too many verification codes requested. Please try again later.",
            http_status=429,
            details={"retry_after_seconds": 3600},
        )

    daily = OtpRequest.objects.filter(
        phone_number=phone_number, created_at__gte=now - timedelta(days=1)
    ).count()
    if daily >= settings.OTP_MAX_SMS_PER_DAY:
        raise ApiError(
            ErrorCode.RATE_LIMITED,
            "Daily verification limit reached. Please try again tomorrow.",
            http_status=429,
            details={"retry_after_seconds": 86400},
        )


# --- Issue -------------------------------------------------------------------


def _live_request(phone_number: str, purpose: str) -> OtpRequest | None:
    """The most recent request still capable of being verified."""
    return (
        OtpRequest.objects.filter(
            phone_number=phone_number,
            purpose=purpose,
            status=OtpStatus.PENDING,
            expires_at__gt=timezone.now(),
        )
        .order_by("-created_at")
        .first()
    )


@transaction.atomic
def issue(
    *,
    phone_number: str,
    purpose: str,
    customer: Customer | None = None,
) -> OtpRequest:
    """Creates and sends a code, superseding any earlier live one.

    If a live code already exists and its resend cooldown has not elapsed, the
    existing request is returned unchanged and **no second SMS is sent**. That
    is what makes a client retry after a network timeout safe: the customer
    gets one message, not two, and the timings they see stay correct.
    """
    existing = _live_request(phone_number, purpose)
    if existing is not None and existing.seconds_until_resend > 0:
        logger.info(
            "Reusing live OTP request for %s (%s)",
            phone_utils.mask(phone_number),
            purpose,
        )
        return existing

    _enforce_request_limits(phone_number)

    # A new code invalidates the previous one (section 12).
    OtpRequest.objects.filter(
        phone_number=phone_number, purpose=purpose, status=OtpStatus.PENDING
    ).update(status=OtpStatus.SUPERSEDED)

    code = generate_code()
    request = OtpRequest.objects.create(
        phone_number=phone_number,
        purpose=purpose,
        otp_hash=hash_code(code, phone_number=phone_number, purpose=purpose),
        expires_at=timezone.now() + timedelta(seconds=settings.OTP_TTL_SECONDS),
        customer=customer,
    )

    # Sent inside the transaction on purpose: if delivery fails, the request
    # row rolls back with it and the customer is not left with a code they
    # never received.
    sms.send_otp(phone_number=phone_number, code=code, purpose=purpose)

    logger.info(
        "Issued %s OTP for %s", purpose, phone_utils.mask(phone_number)
    )
    return request


@transaction.atomic
def resend(*, phone_number: str, purpose: str) -> OtpRequest:
    """Explicitly requests a fresh code.

    Unlike `issue`, this refuses while the cooldown is running rather than
    quietly returning the existing request -- the customer asked for a new
    code, so silence would look broken.
    """
    existing = _live_request(phone_number, purpose)
    if existing is None:
        raise ApiError(
            ErrorCode.OTP_NOT_FOUND,
            "No verification is in progress for this number.",
            http_status=404,
        )

    if existing.seconds_until_resend > 0:
        raise ApiError(
            ErrorCode.OTP_RESEND_TOO_SOON,
            "A code was sent recently. Please wait before requesting another.",
            http_status=429,
            details={"retry_after_seconds": existing.seconds_until_resend},
        )

    _enforce_request_limits(phone_number)

    existing.status = OtpStatus.SUPERSEDED
    existing.save(update_fields=["status"])

    code = generate_code()
    request = OtpRequest.objects.create(
        phone_number=phone_number,
        purpose=purpose,
        otp_hash=hash_code(code, phone_number=phone_number, purpose=purpose),
        expires_at=timezone.now() + timedelta(seconds=settings.OTP_TTL_SECONDS),
        customer=existing.customer,
    )
    sms.send_otp(phone_number=phone_number, code=code, purpose=purpose)
    return request


# --- Verify ------------------------------------------------------------------


@dataclass
class _Outcome:
    """The result of one verification attempt.

    Returned rather than raised so the surrounding transaction can commit
    first. Raising from inside `transaction.atomic` would roll back the very
    writes that record the attempt -- see `verify`.
    """

    request: OtpRequest | None = None
    error_code: str | None = None
    message: str = ""
    http_status: int = 400
    details: dict | None = None


@transaction.atomic
def _attempt(phone_number: str, purpose: str, code: str) -> _Outcome:
    """Applies one attempt and records it. Never raises for an expected
    failure.

    The row is locked for the duration, so two submissions arriving together
    cannot both increment the counter or both consume the same code.
    """
    request = (
        OtpRequest.objects.select_for_update()
        .filter(
            phone_number=phone_number,
            purpose=purpose,
            status__in=[OtpStatus.PENDING, OtpStatus.BLOCKED],
        )
        .order_by("-created_at")
        .first()
    )

    if request is None:
        return _Outcome(
            error_code=ErrorCode.OTP_NOT_FOUND,
            message="No verification is in progress for this number.",
            http_status=404,
        )

    # Locked stays locked until a new code is requested -- a correct code does
    # not rescue an exhausted request (section 13).
    if request.status == OtpStatus.BLOCKED:
        return _Outcome(
            request=request,
            error_code=ErrorCode.OTP_ATTEMPTS_EXCEEDED,
            message=(
                "Too many verification attempts. Request a new code and try "
                "again."
            ),
        )

    if request.is_expired:
        request.status = OtpStatus.EXPIRED
        request.save(update_fields=["status"])
        return _Outcome(
            request=request,
            error_code=ErrorCode.OTP_EXPIRED,
            message=(
                "This verification code has expired. Please request a new "
                "code."
            ),
        )

    if not _matches(request, code):
        request.attempt_count += 1
        exhausted = request.attempt_count >= settings.OTP_MAX_ATTEMPTS
        if exhausted:
            request.status = OtpStatus.BLOCKED
        request.save(update_fields=["attempt_count", "status"])

        if exhausted:
            return _Outcome(
                request=request,
                error_code=ErrorCode.OTP_ATTEMPTS_EXCEEDED,
                message=(
                    "Too many verification attempts. Request a new code and "
                    "try again."
                ),
            )
        return _Outcome(
            request=request,
            error_code=ErrorCode.OTP_INCORRECT,
            message="The verification code is incorrect. Please try again.",
            details={"attempts_remaining": request.attempts_remaining},
        )

    request.status = OtpStatus.VERIFIED
    request.verified_at = timezone.now()
    request.save(update_fields=["status", "verified_at"])
    return _Outcome(request=request)


def verify(*, phone_number: str, purpose: str, code: str) -> OtpRequest:
    """Checks a code and consumes it on success.

    The attempt is recorded in its own committed transaction *before* any error
    is raised. This is not incidental: raising from inside the transaction
    would roll back the counter increment, so a wrong code would cost nothing
    and the three-attempt lockout in section 13 would never trigger, leaving
    the code open to unlimited guessing.

    For the same reason callers must not wrap this in an outer atomic block --
    an outer rollback would discard the attempt too.
    """
    outcome = _attempt(phone_number, purpose, code)

    if outcome.error_code:
        raise ApiError(
            outcome.error_code,
            outcome.message,
            http_status=outcome.http_status,
            details=outcome.details,
        )

    assert outcome.request is not None
    return outcome.request


def purge_expired(older_than_days: int = 7) -> int:
    """Removes spent authentication records.

    Run on a schedule. Keeps the table small and limits how long any trace of
    an authentication attempt is retained.
    """
    cutoff = timezone.now() - timedelta(days=older_than_days)
    deleted, _ = OtpRequest.objects.filter(created_at__lt=cutoff).delete()
    return deleted


__all__ = [
    "OtpPurpose",
    "generate_code",
    "hash_code",
    "issue",
    "purge_expired",
    "resend",
    "verify",
]

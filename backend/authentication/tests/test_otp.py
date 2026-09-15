"""The OTP state machine (specification sections 8-13, 32, 33)."""

from __future__ import annotations

from datetime import timedelta
from unittest.mock import patch

from django.test import override_settings
from django.utils import timezone

from authentication import otp, phone
from authentication.errors import ApiError, ErrorCode
from authentication.models import OtpPurpose, OtpRequest, OtpStatus

from .support import ApiTestCase

PHONE = "712000111"


@override_settings(SMS_PROVIDER="memory")
class CodeGenerationTests(ApiTestCase):
    def test_code_has_the_configured_length(self):
        for _ in range(50):
            self.assertEqual(len(otp.generate_code()), 6)

    def test_leading_zeros_survive(self):
        # `012345` is a valid code. Generating into an int would silently drop
        # the zero and produce a five-character code the customer cannot enter.
        with patch("authentication.otp.secrets.randbelow", return_value=12345):
            self.assertEqual(otp.generate_code(), "012345")

    def test_hash_is_bound_to_phone_and_purpose(self):
        code = "123456"
        base = otp.hash_code(code, phone_number=PHONE, purpose="LOGIN")

        self.assertNotEqual(
            base, otp.hash_code(code, phone_number="712000222", purpose="LOGIN")
        )
        self.assertNotEqual(
            base,
            otp.hash_code(code, phone_number=PHONE, purpose="REGISTRATION"),
        )

    def test_plain_code_is_never_stored(self):
        request = otp.issue(
            phone_number=PHONE, purpose=OtpPurpose.REGISTRATION
        )
        code = self.latest_code()
        self.assertNotIn(code, request.otp_hash)
        self.assertEqual(len(request.otp_hash), 64)


@override_settings(SMS_PROVIDER="memory")
class VerificationTests(ApiTestCase):
    def issue(self) -> tuple[OtpRequest, str]:
        request = otp.issue(
            phone_number=PHONE, purpose=OtpPurpose.REGISTRATION
        )
        return request, self.latest_code()

    def verify(self, code: str) -> OtpRequest:
        return otp.verify(
            phone_number=PHONE, purpose=OtpPurpose.REGISTRATION, code=code
        )

    def test_correct_code_verifies_once_and_is_then_spent(self):
        _, code = self.issue()
        request = self.verify(code)
        self.assertEqual(request.status, OtpStatus.VERIFIED)
        self.assertIsNotNone(request.verified_at)

        # Replaying a consumed code must not work.
        with self.assertRaises(ApiError) as caught:
            self.verify(code)
        self.assertEqual(caught.exception.code, ErrorCode.OTP_NOT_FOUND)

    def test_wrong_code_reports_attempts_remaining(self):
        self.issue()
        with self.assertRaises(ApiError) as caught:
            self.verify("000000")
        self.assertEqual(caught.exception.code, ErrorCode.OTP_INCORRECT)
        self.assertEqual(caught.exception.details["attempts_remaining"], 2)

    def test_third_failure_locks_the_request(self):
        _, code = self.issue()

        for expected_remaining in (2, 1):
            with self.assertRaises(ApiError) as caught:
                self.verify("000000")
            self.assertEqual(caught.exception.code, ErrorCode.OTP_INCORRECT)
            self.assertEqual(
                caught.exception.details["attempts_remaining"],
                expected_remaining,
            )

        with self.assertRaises(ApiError) as caught:
            self.verify("000000")
        self.assertEqual(caught.exception.code, ErrorCode.OTP_ATTEMPTS_EXCEEDED)

        # Locked is locked: even the right code does not rescue it.
        with self.assertRaises(ApiError) as caught:
            self.verify(code)
        self.assertEqual(caught.exception.code, ErrorCode.OTP_ATTEMPTS_EXCEEDED)

    def test_expired_code_is_rejected(self):
        request, code = self.issue()
        OtpRequest.objects.filter(pk=request.pk).update(
            expires_at=timezone.now() - timedelta(seconds=1)
        )

        with self.assertRaises(ApiError) as caught:
            self.verify(code)
        self.assertEqual(caught.exception.code, ErrorCode.OTP_EXPIRED)

        request.refresh_from_db()
        self.assertEqual(request.status, OtpStatus.EXPIRED)

    def test_a_registration_code_cannot_be_used_for_login(self):
        # The purpose is part of the lookup and of the hash, so a code issued
        # for one journey is inert in another.
        _, code = self.issue()
        with self.assertRaises(ApiError) as caught:
            otp.verify(
                phone_number=PHONE, purpose=OtpPurpose.LOGIN, code=code
            )
        self.assertEqual(caught.exception.code, ErrorCode.OTP_NOT_FOUND)

    def test_verifying_with_no_request_is_not_found(self):
        with self.assertRaises(ApiError) as caught:
            self.verify("123456")
        self.assertEqual(caught.exception.code, ErrorCode.OTP_NOT_FOUND)


@override_settings(SMS_PROVIDER="memory")
class IssueAndResendTests(ApiTestCase):
    def test_repeat_request_within_cooldown_does_not_send_twice(self):
        # A client retrying after a network timeout must not cost a second SMS
        # or leave the customer holding two different codes.
        first = otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        second = otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)

        self.assertEqual(first.pk, second.pk)
        self.assertEqual(self.sent_count, 1)

    def test_resend_before_cooldown_is_refused_with_a_retry_hint(self):
        otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)

        with self.assertRaises(ApiError) as caught:
            otp.resend(phone_number=PHONE, purpose=OtpPurpose.LOGIN)

        self.assertEqual(caught.exception.code, ErrorCode.OTP_RESEND_TOO_SOON)
        self.assertGreater(
            caught.exception.details["retry_after_seconds"], 0
        )

    def test_resend_invalidates_the_previous_code(self):
        request = otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        first_code = self.latest_code()

        # Move the cooldown into the past rather than sleeping.
        OtpRequest.objects.filter(pk=request.pk).update(
            last_sent_at=timezone.now() - timedelta(hours=1)
        )

        otp.resend(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        second_code = self.latest_code()
        self.assertEqual(self.sent_count, 2)

        with self.assertRaises(ApiError) as caught:
            otp.verify(
                phone_number=PHONE, purpose=OtpPurpose.LOGIN, code=first_code
            )
        self.assertEqual(caught.exception.code, ErrorCode.OTP_INCORRECT)

        verified = otp.verify(
            phone_number=PHONE, purpose=OtpPurpose.LOGIN, code=second_code
        )
        self.assertEqual(verified.status, OtpStatus.VERIFIED)

    def test_resend_resets_the_attempt_counter(self):
        request = otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        with self.assertRaises(ApiError):
            otp.verify(
                phone_number=PHONE, purpose=OtpPurpose.LOGIN, code="000000"
            )

        OtpRequest.objects.filter(pk=request.pk).update(
            last_sent_at=timezone.now() - timedelta(hours=1)
        )
        fresh = otp.resend(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        self.assertEqual(fresh.attempt_count, 0)

    def test_resend_without_a_live_request_is_not_found(self):
        with self.assertRaises(ApiError) as caught:
            otp.resend(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        self.assertEqual(caught.exception.code, ErrorCode.OTP_NOT_FOUND)


@override_settings(SMS_PROVIDER="memory", OTP_MAX_REQUESTS_PER_HOUR=3)
class RateLimitTests(ApiTestCase):
    def test_hourly_cap_stops_flooding_one_number(self):
        for index in range(3):
            request = otp.issue(
                phone_number=PHONE, purpose=OtpPurpose.LOGIN
            )
            # Clear the cooldown so each call issues a genuinely new code.
            OtpRequest.objects.filter(pk=request.pk).update(
                last_sent_at=timezone.now() - timedelta(hours=1)
            )
            self.assertEqual(self.sent_count, index + 1)

        with self.assertRaises(ApiError) as caught:
            otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)

        self.assertEqual(caught.exception.code, ErrorCode.RATE_LIMITED)
        self.assertEqual(caught.exception.http_status, 429)
        # The refused request must not have cost an SMS.
        self.assertEqual(self.sent_count, 3)

    def test_limit_follows_the_normalised_number(self):
        # Spelling the number differently must not buy a fresh allowance, so
        # the counter is keyed on the canonical form.
        for spelling in ("0712000111", "+255712000111", "255712000111"):
            request = otp.issue(
                phone_number=phone.normalise(spelling),
                purpose=OtpPurpose.LOGIN,
            )
            OtpRequest.objects.filter(pk=request.pk).update(
                last_sent_at=timezone.now() - timedelta(hours=1)
            )

        with self.assertRaises(ApiError) as caught:
            otp.issue(phone_number="712000111", purpose=OtpPurpose.LOGIN)
        self.assertEqual(caught.exception.code, ErrorCode.RATE_LIMITED)


@override_settings(SMS_PROVIDER="memory")
class HousekeepingTests(ApiTestCase):
    def test_purge_removes_old_records_only(self):
        old = otp.issue(phone_number=PHONE, purpose=OtpPurpose.LOGIN)
        OtpRequest.objects.filter(pk=old.pk).update(
            created_at=timezone.now() - timedelta(days=30)
        )
        recent = otp.issue(
            phone_number="712000222", purpose=OtpPurpose.LOGIN
        )

        self.assertEqual(otp.purge_expired(older_than_days=7), 1)
        self.assertFalse(OtpRequest.objects.filter(pk=old.pk).exists())
        self.assertTrue(OtpRequest.objects.filter(pk=recent.pk).exists())

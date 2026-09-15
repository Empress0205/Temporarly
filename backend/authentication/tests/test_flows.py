"""End-to-end journeys through the API.

These follow the acceptance criteria in specification section 40, and mirror
the widget tests in the Flutter app one-for-one, so a behaviour change shows up
on whichever side introduced it.
"""

from __future__ import annotations

from datetime import timedelta

from django.test import override_settings
from django.utils import timezone

from authentication.errors import ErrorCode
from authentication.models import Customer, OtpPurpose, OtpRequest

from .support import ApiTestCase


@override_settings(SMS_PROVIDER="memory")
class RegistrationTests(ApiTestCase):
    def test_account_is_created_only_after_the_code_verifies(self):
        response = self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "0712000111"},
            format="json",
        )
        self.assertEqual(response.status_code, 202)

        # The code is out, but nothing has been persisted about the person.
        self.assertFalse(Customer.objects.exists())
        self.assertEqual(response.data["otp_length"], 6)
        self.assertGreater(response.data["expires_in"], 0)

        response = self.client.post(
            "/api/auth/register/verify-otp",
            {
                "phone_number": "0712000111",
                "code": self.latest_code(),
                "full_name": "Grace Mushi",
                "email": "grace@example.com",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)

        customer = Customer.objects.get()
        self.assertEqual(customer.full_name, "Grace Mushi")
        # Stored canonically, whatever spelling was sent.
        self.assertEqual(customer.phone_number, "712000111")
        self.assertTrue(customer.phone_verified)
        self.assertIn("access", response.data["tokens"])

    def test_abandoned_registration_leaves_no_customer(self):
        self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "712000111"},
            format="json",
        )
        self.assertFalse(Customer.objects.exists())
        self.assertEqual(OtpRequest.objects.count(), 1)

    def test_already_registered_number_is_refused(self):
        self.make_customer(phone_number="712345678")

        response = self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "0712345678"},
            format="json",
        )
        self.assertEqual(response.status_code, 409)
        self.assertErrorCode(response, ErrorCode.PHONE_ALREADY_REGISTERED)
        # Refused before any SMS was paid for.
        self.assertEqual(self.sent_count, 0)

    def test_invalid_number_is_rejected_before_sending(self):
        response = self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "0812345678"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertErrorCode(response, ErrorCode.VALIDATION_FAILED)
        self.assertEqual(self.sent_count, 0)

    def test_short_name_is_rejected(self):
        self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "712000111"},
            format="json",
        )
        response = self.client.post(
            "/api/auth/register/verify-otp",
            {
                "phone_number": "712000111",
                "code": self.latest_code(),
                "full_name": "G",
                "email": "grace@example.com",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertFalse(Customer.objects.exists())


@override_settings(SMS_PROVIDER="memory")
class LoginTests(ApiTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.customer = self.make_customer()

    def test_registered_number_can_log_in(self):
        session = self.login()
        self.assertEqual(session["customer"]["full_name"], "Amina Hassan")
        self.assertEqual(
            session["customer"]["phone_number_display"], "+255 712 345 678"
        )

    def test_unknown_number_is_refused_and_no_account_is_created(self):
        response = self.client.post(
            "/api/auth/login/request-otp",
            {"phone_number": "799999999"},
            format="json",
        )
        self.assertEqual(response.status_code, 404)
        self.assertErrorCode(response, ErrorCode.PHONE_NOT_REGISTERED)
        self.assertEqual(Customer.objects.count(), 1)
        self.assertEqual(self.sent_count, 0)

    def test_suspended_account_cannot_obtain_a_session(self):
        self.customer.account_status = "SUSPENDED"
        self.customer.save(update_fields=["account_status"])

        response = self.client.post(
            "/api/auth/login/request-otp",
            {"phone_number": "712345678"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)
        self.assertErrorCode(response, ErrorCode.ACCOUNT_SUSPENDED)
        # No SMS spent on an account that could not sign in anyway.
        self.assertEqual(self.sent_count, 0)

    def test_wrong_code_reports_attempts_remaining(self):
        self.client.post(
            "/api/auth/login/request-otp",
            {"phone_number": "712345678"},
            format="json",
        )
        response = self.client.post(
            "/api/auth/login/verify-otp",
            {"phone_number": "712345678", "code": "000000"},
            format="json",
        )
        self.assertErrorCode(response, ErrorCode.OTP_INCORRECT)
        self.assertEqual(
            response.data["error"]["details"]["attempts_remaining"], 2
        )


@override_settings(SMS_PROVIDER="memory")
class SessionTests(ApiTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.customer = self.make_customer()
        self.session = self.login()

    def test_me_identifies_the_customer_from_the_token(self):
        self.authenticate(self.session["tokens"])
        response = self.client.get("/api/auth/me")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["id"], str(self.customer.id))

    def test_me_requires_authentication(self):
        self.assertEqual(self.client.get("/api/auth/me").status_code, 401)

    def test_a_forged_identity_in_the_body_is_ignored(self):
        # Identity comes from the token, never from the request (section 37).
        other = self.make_customer(
            phone_number="765000000", full_name="Someone Else",
            email="other@example.com",
        )
        self.authenticate(self.session["tokens"])
        response = self.client.get("/api/auth/me", {"id": str(other.id)})
        self.assertEqual(response.data["id"], str(self.customer.id))

    def test_logout_revokes_the_refresh_token(self):
        self.authenticate(self.session["tokens"])
        response = self.client.post(
            "/api/auth/logout",
            {"refresh": self.session["tokens"]["refresh"]},
            format="json",
        )
        self.assertEqual(response.status_code, 204)

        refreshed = self.client.post(
            "/api/auth/token/refresh",
            {"refresh": self.session["tokens"]["refresh"]},
            format="json",
        )
        self.assertEqual(refreshed.status_code, 401)

    def test_logging_out_twice_is_not_an_error(self):
        self.authenticate(self.session["tokens"])
        payload = {"refresh": self.session["tokens"]["refresh"]}
        self.client.post("/api/auth/logout", payload, format="json")
        again = self.client.post("/api/auth/logout", payload, format="json")
        self.assertEqual(again.status_code, 204)

    def test_refresh_token_cannot_be_replayed_after_rotation(self):
        original = self.session["tokens"]["refresh"]
        first = self.client.post(
            "/api/auth/token/refresh", {"refresh": original}, format="json"
        )
        self.assertEqual(first.status_code, 200)

        # Rotation blacklists the old token: presenting it again is a replay.
        replay = self.client.post(
            "/api/auth/token/refresh", {"refresh": original}, format="json"
        )
        self.assertEqual(replay.status_code, 401)


@override_settings(SMS_PROVIDER="memory")
class PhoneChangeTests(ApiTestCase):
    def setUp(self) -> None:
        super().setUp()
        self.customer = self.make_customer()
        self.session = self.login()
        self.authenticate(self.session["tokens"])

    def request_change(self, phone_number: str):
        return self.client.post(
            "/api/customer/phone/request-change",
            {"phone_number": phone_number},
            format="json",
        )

    def test_number_moves_only_after_verification(self):
        self.assertEqual(self.request_change("754111222").status_code, 202)

        self.customer.refresh_from_db()
        self.assertEqual(self.customer.phone_number, "712345678")

        response = self.client.post(
            "/api/customer/phone/verify-change",
            {"phone_number": "754111222", "code": self.latest_code()},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)

        self.customer.refresh_from_db()
        self.assertEqual(self.customer.phone_number, "754111222")

    def test_current_number_is_refused(self):
        response = self.request_change("0712345678")
        self.assertEqual(response.status_code, 409)
        self.assertErrorCode(response, ErrorCode.PHONE_SAME_AS_CURRENT)

    def test_number_held_by_another_account_is_refused(self):
        self.make_customer(
            phone_number="765000000", full_name="Other Person",
            email="other@example.com",
        )
        response = self.request_change("765000000")
        self.assertEqual(response.status_code, 409)
        self.assertErrorCode(response, ErrorCode.PHONE_BELONGS_TO_OTHER)

    def test_number_claimed_while_the_code_was_in_flight_is_refused(self):
        # The interesting race: free at request time, taken by verify time.
        self.request_change("754111222")
        code = self.latest_code()

        self.make_customer(
            phone_number="754111222", full_name="Faster Person",
            email="faster@example.com",
        )

        response = self.client.post(
            "/api/customer/phone/verify-change",
            {"phone_number": "754111222", "code": code},
            format="json",
        )
        self.assertEqual(response.status_code, 409)
        self.assertErrorCode(response, ErrorCode.PHONE_BELONGS_TO_OTHER)

        self.customer.refresh_from_db()
        self.assertEqual(self.customer.phone_number, "712345678")

    def test_a_failed_verification_leaves_the_number_untouched(self):
        self.request_change("754111222")
        response = self.client.post(
            "/api/customer/phone/verify-change",
            {"phone_number": "754111222", "code": "000000"},
            format="json",
        )
        self.assertErrorCode(response, ErrorCode.OTP_INCORRECT)

        self.customer.refresh_from_db()
        self.assertEqual(self.customer.phone_number, "712345678")

    def test_change_requires_authentication(self):
        self.client.credentials()
        self.assertEqual(self.request_change("754111222").status_code, 401)

    def test_other_devices_are_signed_out(self):
        # A second device, signed in before the change.
        second = APIClientSession(self)
        self.request_change("754111222")
        self.client.post(
            "/api/customer/phone/verify-change",
            {
                "phone_number": "754111222",
                "code": self.latest_code(),
                "refresh": self.session["tokens"]["refresh"],
            },
            format="json",
        )

        refreshed = self.client.post(
            "/api/auth/token/refresh",
            {"refresh": second.refresh},
            format="json",
        )
        self.assertEqual(refreshed.status_code, 401)


class APIClientSession:
    """A second signed-in device, for testing cross-device revocation."""

    def __init__(self, case: ApiTestCase) -> None:
        session = case.login()
        self.refresh = session["tokens"]["refresh"]


@override_settings(SMS_PROVIDER="memory")
class ResendEndpointTests(ApiTestCase):
    def test_resend_returns_fresh_timings(self):
        self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "712000111"},
            format="json",
        )
        OtpRequest.objects.update(
            last_sent_at=timezone.now() - timedelta(hours=1)
        )

        response = self.client.post(
            "/api/auth/resend-otp",
            {
                "phone_number": "712000111",
                "purpose": OtpPurpose.REGISTRATION,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 202)
        self.assertGreater(response.data["resend_available_in"], 0)
        self.assertEqual(self.sent_count, 2)

    def test_resend_during_cooldown_is_refused(self):
        self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": "712000111"},
            format="json",
        )
        response = self.client.post(
            "/api/auth/resend-otp",
            {
                "phone_number": "712000111",
                "purpose": OtpPurpose.REGISTRATION,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 429)
        self.assertErrorCode(response, ErrorCode.OTP_RESEND_TOO_SOON)

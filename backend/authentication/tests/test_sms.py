"""The Webline SMS provider.

Every test here mocks the HTTP call. Nothing in the suite sends a real message
or spends credit.
"""

from __future__ import annotations

from unittest.mock import patch

import requests
from django.test import SimpleTestCase, override_settings

from authentication import phone, sms
from authentication.errors import ErrorCode
from authentication.sms import (
    ImproperlyConfiguredProvider,
    SmsDeliveryError,
    WeblineSmsProvider,
)

WEBLINE = {
    "SMS_PROVIDER": "webline",
    "SMS_API_TOKEN": "500|test-token",
    "SMS_SENDER_ID": "TAARIFA",
    "SMS_BASE_URL": "https://sms.webline.africa/api/http",
}


class FakeResponse:
    def __init__(self, payload, status_code=200, valid_json=True):
        self._payload = payload
        self.status_code = status_code
        self._valid_json = valid_json

    def json(self):
        if not self._valid_json:
            raise ValueError("not json")
        return self._payload


@override_settings(**WEBLINE)
class PayloadTests(SimpleTestCase):
    def test_sends_the_documented_payload(self):
        with patch("authentication.sms.requests.post") as post:
            post.return_value = FakeResponse({"status": "success", "data": "ok"})
            WeblineSmsProvider().send(
                phone_number="757697765", message="123456 is your code."
            )

        _, kwargs = post.call_args
        self.assertEqual(
            kwargs["json"],
            {
                "api_token": "500|test-token",
                "recipient": "255757697765",
                "sender_id": "TAARIFA",
                "type": "plain",
                "message": "123456 is your code.",
            },
        )
        self.assertEqual(
            post.call_args[0][0],
            "https://sms.webline.africa/api/http/sms/send",
        )
        self.assertEqual(kwargs["headers"]["Accept"], "application/json")
        self.assertEqual(kwargs["timeout"], 15)

    def test_recipient_has_no_leading_plus(self):
        # Webline's examples use `31612345678`. Sending `+255...` is the kind
        # of mistake that fails on their side, not ours.
        self.assertEqual(phone.to_msisdn("757697765"), "255757697765")
        self.assertEqual(phone.to_e164("757697765"), "+255757697765")

    def test_a_timeout_is_a_failure_not_a_success(self):
        with patch("authentication.sms.requests.post") as post:
            post.side_effect = requests.Timeout("timed out")
            with self.assertRaises(SmsDeliveryError):
                WeblineSmsProvider().send(
                    phone_number="757697765", message="hello"
                )


@override_settings(**WEBLINE)
class FailureDetectionTests(SimpleTestCase):
    def test_error_returned_with_http_200_is_still_a_failure(self):
        # The trap in this API: it answers 200 and puts the real result in
        # `status`. Trusting the status code would report an undelivered code
        # as sent, and the customer would wait for an SMS that never comes.
        with patch("authentication.sms.requests.post") as post:
            post.return_value = FakeResponse(
                {"status": "error", "message": "Insufficient balance"},
                status_code=200,
            )
            with self.assertRaises(SmsDeliveryError) as caught:
                WeblineSmsProvider().send(
                    phone_number="757697765", message="hello"
                )

        self.assertIn("Insufficient balance", str(caught.exception))

    def test_non_json_response_is_a_failure(self):
        with patch("authentication.sms.requests.post") as post:
            post.return_value = FakeResponse(None, status_code=502, valid_json=False)
            with self.assertRaises(SmsDeliveryError):
                WeblineSmsProvider().send(
                    phone_number="757697765", message="hello"
                )

    def test_delivery_failure_surfaces_as_sms_send_failed(self):
        from authentication.errors import ApiError

        with patch("authentication.sms.requests.post") as post:
            post.return_value = FakeResponse(
                {"status": "error", "message": "Invalid sender id"}
            )
            with self.assertRaises(ApiError) as caught:
                sms.send_otp(
                    phone_number="757697765", code="123456", purpose="LOGIN"
                )

        self.assertEqual(caught.exception.code, ErrorCode.SMS_SEND_FAILED)
        self.assertEqual(caught.exception.http_status, 502)


class ConfigurationTests(SimpleTestCase):
    @override_settings(**{**WEBLINE, "SMS_API_TOKEN": ""})
    def test_missing_token_is_refused_at_construction(self):
        with self.assertRaises(ImproperlyConfiguredProvider):
            WeblineSmsProvider()

    @override_settings(**{**WEBLINE, "SMS_SENDER_ID": "WAY_TOO_LONG_SENDER"})
    def test_over_long_sender_id_is_refused(self):
        # Webline caps alphanumeric sender IDs at 11 characters; catching it
        # here beats a rejection per message.
        with self.assertRaises(ImproperlyConfiguredProvider) as caught:
            WeblineSmsProvider()
        self.assertIn("maximum is 11", str(caught.exception))

    @override_settings(SMS_PROVIDER="carrier-pigeon")
    def test_unknown_provider_names_the_known_ones(self):
        with self.assertRaises(ImproperlyConfiguredProvider) as caught:
            sms.get_provider()
        self.assertIn("webline", str(caught.exception))

    @override_settings(SMS_PROVIDER="logging", DEBUG=False, TESTING=False)
    def test_development_provider_is_refused_in_production(self):
        # Shipping with SMS_PROVIDER=logging would leave every customer unable
        # to sign in while the server reported success.
        with self.assertRaises(ImproperlyConfiguredProvider):
            sms.get_provider()

    @override_settings(SMS_PROVIDER="logging", DEBUG=True)
    def test_development_provider_is_allowed_in_debug(self):
        self.assertIsInstance(sms.get_provider(), sms.LoggingSmsProvider)

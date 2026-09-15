"""Shared test helpers."""

from __future__ import annotations

import re

from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from authentication import sms
from authentication.models import Customer

CODE_PATTERN = re.compile(r"\b(\d{6})\b")


class ApiTestCase(TestCase):
    """Base class: an API client, a clean SMS outbox, and code extraction.

    Tests read the code out of the delivered message rather than out of the
    database, so the message itself stays covered -- an OTP that never reaches
    the customer is the failure that matters.
    """

    def setUp(self) -> None:
        super().setUp()
        self.client = APIClient()
        sms.outbox.clear()
        # DRF keeps throttle history in the cache, which is process-wide and
        # survives the per-test database rollback. Without this, tests run
        # earlier in the file spend the hourly allowance and every later test
        # fails with 429 for reasons that have nothing to do with what it is
        # asserting.
        cache.clear()

    # --- Reading what was sent ---------------------------------------------

    @property
    def sent_count(self) -> int:
        return len(sms.outbox)

    def latest_code(self) -> str:
        self.assertTrue(sms.outbox, "no SMS was sent")
        match = CODE_PATTERN.search(sms.outbox[-1]["message"])
        self.assertIsNotNone(match, "no code found in the delivered message")
        return match.group(1)

    # --- Assertions ---------------------------------------------------------

    def assertErrorCode(self, response, expected: str) -> None:
        self.assertIn("error", response.data, response.data)
        self.assertEqual(
            response.data["error"]["code"],
            expected,
            f"expected {expected}, got {response.data['error']}",
        )

    # --- Fixtures -----------------------------------------------------------

    def make_customer(
        self,
        phone_number: str = "712345678",
        full_name: str = "Amina Hassan",
        email: str = "amina.hassan@gmail.com",
    ) -> Customer:
        return Customer.objects.create_customer(
            phone_number=phone_number, full_name=full_name, email=email
        )

    def register(self, phone_number: str = "712000111") -> dict:
        """Runs a full registration and returns the session payload."""
        self.client.post(
            "/api/auth/register/request-otp",
            {"phone_number": phone_number},
            format="json",
        )
        response = self.client.post(
            "/api/auth/register/verify-otp",
            {
                "phone_number": phone_number,
                "code": self.latest_code(),
                "full_name": "Grace Mushi",
                "email": "grace@example.com",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)
        return response.data

    def login(self, phone_number: str = "712345678") -> dict:
        self.client.post(
            "/api/auth/login/request-otp",
            {"phone_number": phone_number},
            format="json",
        )
        response = self.client.post(
            "/api/auth/login/verify-otp",
            {"phone_number": phone_number, "code": self.latest_code()},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)
        return response.data

    def authenticate(self, tokens: dict) -> None:
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {tokens['access']}"
        )

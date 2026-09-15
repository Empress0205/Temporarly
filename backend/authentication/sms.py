"""SMS delivery.

The provider sits behind an interface for two reasons: the rest of the module
could be built and tested before any credentials existed, and swapping
providers later touches one class rather than the OTP service.

Three implementations:

- `logging` prints the code to the console and sends nothing (development)
- `memory` records into `outbox` for assertions (tests)
- `webline` is the real one
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod

import requests
from django.conf import settings

from . import phone as phone_utils
from .errors import ApiError, ErrorCode

logger = logging.getLogger(__name__)


class SmsDeliveryError(Exception):
    """The provider refused or failed to accept the message."""


class ImproperlyConfiguredProvider(Exception):
    """A deployment mistake: unknown provider, or one missing its settings.

    Deliberately not an `ApiError`. This is not something a customer did, and
    it should surface loudly at start-up rather than as a tidy message in the
    app.
    """


class SmsProvider(ABC):
    """Sends one message to one number."""

    @abstractmethod
    def send(self, *, phone_number: str, message: str) -> None:
        """`phone_number` is canonical nine digits; convert at this boundary.

        Raises `SmsDeliveryError` if the message was not accepted.
        """


class LoggingSmsProvider(SmsProvider):
    """Development provider. Prints instead of sending.

    The code is printed deliberately -- that is the point of it -- which is
    exactly why `get_provider` refuses to return this outside DEBUG.
    """

    def send(self, *, phone_number: str, message: str) -> None:
        print(
            f"\n[SMS -> {phone_utils.to_e164(phone_number)}] {message}\n",
            flush=True,
        )


#: Messages captured by `MemorySmsProvider`, in the order they were sent.
#: Mirrors `django.core.mail.outbox`. Tests clear this in setUp.
outbox: list[dict] = []


class MemorySmsProvider(SmsProvider):
    """Test provider. Records instead of sending, so assertions can read the
    code that was actually delivered rather than reaching into the database."""

    def send(self, *, phone_number: str, message: str) -> None:
        outbox.append({"phone_number": phone_number, "message": message})


class WeblineSmsProvider(SmsProvider):
    """Webline Africa Bulk SMS (https://sms.webline.africa/api/http/sms/send).

    Two things about this API are easy to get wrong:

    1. It answers **HTTP 200 even when the send failed** -- the JSON `status`
       field is the real result. Checking only the status code would report
       every rejection as a successful delivery, and the customer would sit
       waiting for a code that was never sent.
    2. Recipients are the country code *without* a leading `+`
       (`255712345678`), which is `to_msisdn`, not `to_e164`.

    Authentication is a single `api_token` in the request body. There is no
    secret.
    """

    #: Webline caps alphanumeric sender IDs at 11 characters.
    MAX_SENDER_ID = 11

    def __init__(self) -> None:
        self.url = f"{settings.SMS_BASE_URL.rstrip('/')}/sms/send"
        self.token = settings.SMS_API_TOKEN
        self.sender_id = settings.SMS_SENDER_ID

        if not self.token:
            raise ImproperlyConfiguredProvider("webline: SMS_API_TOKEN is empty")
        if not self.sender_id:
            raise ImproperlyConfiguredProvider("webline: SMS_SENDER_ID is empty")
        if len(self.sender_id) > self.MAX_SENDER_ID:
            raise ImproperlyConfiguredProvider(
                f"webline: SMS_SENDER_ID '{self.sender_id}' is "
                f"{len(self.sender_id)} characters; the maximum is "
                f"{self.MAX_SENDER_ID}"
            )

    def send(self, *, phone_number: str, message: str) -> None:
        payload = {
            "api_token": self.token,
            "recipient": phone_utils.to_msisdn(phone_number),
            "sender_id": self.sender_id,
            "type": "plain",
            "message": message,
        }

        try:
            response = requests.post(
                self.url,
                json=payload,
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
                # A hung provider must not hold an HTTP worker open. A timeout
                # counts as a failure: the customer requests a new code, and
                # any message that did slip through expires unused.
                timeout=15,
            )
        except requests.RequestException as exc:
            raise SmsDeliveryError(
                f"could not reach the SMS provider: {exc}"
            ) from exc

        try:
            body = response.json()
        except ValueError:
            raise SmsDeliveryError(
                f"provider returned non-JSON (HTTP {response.status_code})"
            ) from None

        # The `status` field decides, not the HTTP status code.
        if body.get("status") != "success":
            raise SmsDeliveryError(
                body.get("message") or f"HTTP {response.status_code}"
            )


#: Providers that must never be selected in production: one prints the code to
#: the console, the other sends nothing at all.
_DEVELOPMENT_ONLY = {"logging", "memory"}

_PROVIDERS = {
    "logging": LoggingSmsProvider,
    "memory": MemorySmsProvider,
    "webline": WeblineSmsProvider,
}


def get_provider() -> SmsProvider:
    """Resolves the provider named by `SMS_PROVIDER`.

    Refuses the development providers when `DEBUG` is off. Shipping with
    `SMS_PROVIDER=logging` would leave every customer unable to sign in while
    the server cheerfully reported success -- a failure that is invisible from
    the outside, so it is caught here instead.
    """
    name = settings.SMS_PROVIDER.lower()

    provider = _PROVIDERS.get(name)
    if provider is None:
        raise ImproperlyConfiguredProvider(
            f"Unknown SMS_PROVIDER '{name}'. "
            f"Known providers: {', '.join(sorted(_PROVIDERS))}."
        )

    permitted = settings.DEBUG or getattr(settings, "TESTING", False)
    if name in _DEVELOPMENT_ONLY and not permitted:
        raise ImproperlyConfiguredProvider(
            f"SMS_PROVIDER '{name}' does not deliver messages and cannot be "
            "used with DEBUG off. Set SMS_PROVIDER=webline."
        )

    return provider()


def send_otp(*, phone_number: str, code: str, purpose: str) -> None:
    """Sends the verification code, or fails the request.

    A code that was never dispatched must not look like a success: the customer
    would sit waiting for an SMS that is not coming (section 36). So a delivery
    failure propagates rather than being swallowed.

    Note what is *not* logged. The message body contains the code, and the
    payload contains the API token, so neither is ever passed to the logger --
    only the masked number and the provider's reason.
    """
    message = (
        f"{code} is your Jihudumie verification code. "
        f"It expires in {settings.OTP_TTL_SECONDS // 60} minutes. "
        "Do not share it with anyone."
    )

    try:
        get_provider().send(phone_number=phone_number, message=message)
    except SmsDeliveryError as exc:
        logger.error(
            "SMS delivery failed for %s (%s): %s",
            phone_utils.mask(phone_number),
            purpose,
            exc,
        )
        raise ApiError(
            ErrorCode.SMS_SEND_FAILED,
            "Could not send the verification code. Please try again.",
            http_status=502,
        ) from exc

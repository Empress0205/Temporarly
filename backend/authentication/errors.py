"""The error contract.

The mobile client branches on `code`, not on prose: a number that is already
registered offers "Log in instead" and routes to login, an unknown number
offers "Create an account". The client also carries its own English and Swahili
copy, so the human-readable `message` here is for logs and for whoever is
reading a response by hand -- never for display.

Every failure leaves the API in the same shape:

    {"error": {"code": "...", "message": "...", "details": {...}}}
"""

from __future__ import annotations

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler


class ErrorCode:
    """Machine-readable failure codes. These are API surface: renaming one is a
    breaking change for the mobile client."""

    # Phone / account state
    PHONE_ALREADY_REGISTERED = "PHONE_ALREADY_REGISTERED"
    PHONE_NOT_REGISTERED = "PHONE_NOT_REGISTERED"
    PHONE_SAME_AS_CURRENT = "PHONE_SAME_AS_CURRENT"
    PHONE_BELONGS_TO_OTHER = "PHONE_BELONGS_TO_OTHER"
    ACCOUNT_SUSPENDED = "ACCOUNT_SUSPENDED"

    # OTP lifecycle
    OTP_NOT_FOUND = "OTP_NOT_FOUND"
    OTP_INCORRECT = "OTP_INCORRECT"
    OTP_EXPIRED = "OTP_EXPIRED"
    OTP_ATTEMPTS_EXCEEDED = "OTP_ATTEMPTS_EXCEEDED"
    OTP_RESEND_TOO_SOON = "OTP_RESEND_TOO_SOON"

    # Transport and abuse
    RATE_LIMITED = "RATE_LIMITED"
    SMS_SEND_FAILED = "SMS_SEND_FAILED"

    # Session
    TOKEN_EXPIRED = "TOKEN_EXPIRED"
    TOKEN_INVALID = "TOKEN_INVALID"

    # Input
    VALIDATION_FAILED = "VALIDATION_FAILED"


class ApiError(Exception):
    """An expected, client-facing failure.

    Raised by services rather than returned, so the happy path in a view reads
    straight down without error branches interleaved.
    """

    def __init__(
        self,
        code: str,
        message: str,
        *,
        http_status: int = status.HTTP_400_BAD_REQUEST,
        details: dict | None = None,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.http_status = http_status
        self.details = details or {}

    def as_response(self) -> Response:
        return Response(
            {
                "error": {
                    "code": self.code,
                    "message": self.message,
                    "details": self.details,
                }
            },
            status=self.http_status,
        )


def exception_handler(exc, context):
    """Funnels every failure into the one envelope.

    Without this, DRF validation errors and JWT failures would each arrive in
    their own shape and the client would need three parsers.
    """
    if isinstance(exc, ApiError):
        return exc.as_response()

    response = drf_exception_handler(exc, context)
    if response is None:
        return None

    # Authentication failures carry their own codes so the client can tell
    # "refresh the token" apart from "sign the user out" (section 35).
    code = ErrorCode.VALIDATION_FAILED
    if response.status_code == status.HTTP_401_UNAUTHORIZED:
        detail = str(response.data.get("detail", "")).lower()
        code = (
            ErrorCode.TOKEN_EXPIRED
            if "expired" in detail
            else ErrorCode.TOKEN_INVALID
        )
    elif response.status_code == status.HTTP_429_TOO_MANY_REQUESTS:
        code = ErrorCode.RATE_LIMITED

    details = response.data if isinstance(response.data, dict) else {}
    message = str(details.get("detail", "")) or "Request could not be processed."

    response.data = {
        "error": {"code": code, "message": message, "details": details},
    }
    return response

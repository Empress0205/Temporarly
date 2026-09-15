"""HTTP layer.

Each view validates its input, calls one service function and shapes the
response. No business rules live here.
"""

from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from . import services
from .models import OtpPurpose
from .serializers import (
    CustomerSerializer,
    ErrorEnvelopeSerializer,
    LogoutSerializer,
    OtpChallengeSerializer,
    OtpCodeSerializer,
    PhoneSerializer,
    RegisterVerifySerializer,
    ResendSerializer,
    SessionSerializer,
)
from .throttling import OtpRequestThrottle, OtpVerifyThrottle


#: Every endpoint can fail this way, and the client handles all of them from
#: the same envelope. Listed once rather than repeated per view.
ERRORS = {
    400: ErrorEnvelopeSerializer,
    401: ErrorEnvelopeSerializer,
    403: ErrorEnvelopeSerializer,
    404: ErrorEnvelopeSerializer,
    409: ErrorEnvelopeSerializer,
    429: ErrorEnvelopeSerializer,
}


def _validated(serializer_class, request):
    serializer = serializer_class(data=request.data)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


def _session_response(customer, tokens, http_status=status.HTTP_200_OK):
    return Response(
        {"customer": CustomerSerializer(customer).data, "tokens": tokens},
        status=http_status,
    )


# --- Registration ------------------------------------------------------------


@extend_schema(
    summary="Start registration",
    description=(
        "Sends a verification code to an unregistered number. Nothing is "
        "persisted about the person until the code is verified. Fails with "
        "PHONE_ALREADY_REGISTERED (409) if the number already has an account, "
        "so no SMS is spent."
    ),
    request=PhoneSerializer,
    responses={202: OtpChallengeSerializer, **ERRORS},
)
class RegisterRequestOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [OtpRequestThrottle]

    def post(self, request):
        data = _validated(PhoneSerializer, request)
        otp_request = services.register_request_otp(data["phone_number"])
        return Response(
            OtpChallengeSerializer.from_request(otp_request),
            status=status.HTTP_202_ACCEPTED,
        )


@extend_schema(
    summary="Verify registration and create the account",
    description=(
        "Creates the customer only on a correct code. OTP_INCORRECT carries "
        "`attempts_remaining`; after the limit the request locks with "
        "OTP_ATTEMPTS_EXCEEDED until a new code is requested."
    ),
    request=RegisterVerifySerializer,
    responses={201: SessionSerializer, **ERRORS},
)
class RegisterVerifyOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [OtpVerifyThrottle]

    def post(self, request):
        data = _validated(RegisterVerifySerializer, request)
        customer, tokens = services.register_verify(
            raw_phone=data["phone_number"],
            code=data["code"],
            full_name=data["full_name"],
            email=data["email"],
        )
        return _session_response(customer, tokens, status.HTTP_201_CREATED)


# --- Login -------------------------------------------------------------------


@extend_schema(
    summary="Start login",
    description=(
        "Sends a code to a registered number. Fails with PHONE_NOT_REGISTERED "
        "(404) for an unknown number -- login never creates an account."
    ),
    request=PhoneSerializer,
    responses={202: OtpChallengeSerializer, **ERRORS},
)
class LoginRequestOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [OtpRequestThrottle]

    def post(self, request):
        data = _validated(PhoneSerializer, request)
        otp_request = services.login_request_otp(data["phone_number"])
        return Response(
            OtpChallengeSerializer.from_request(otp_request),
            status=status.HTTP_202_ACCEPTED,
        )


@extend_schema(
    summary="Verify login",
    request=OtpCodeSerializer,
    responses={200: SessionSerializer, **ERRORS},
)
class LoginVerifyOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [OtpVerifyThrottle]

    def post(self, request):
        data = _validated(OtpCodeSerializer, request)
        customer, tokens = services.login_verify(
            raw_phone=data["phone_number"], code=data["code"]
        )
        return _session_response(customer, tokens)


# --- OTP ---------------------------------------------------------------------


@extend_schema(
    summary="Resend the verification code",
    description=(
        "Issues a fresh code and invalidates the previous one. Refused with "
        "OTP_RESEND_TOO_SOON (429) while the cooldown is running; "
        "`details.retry_after_seconds` says how long is left."
    ),
    request=ResendSerializer,
    responses={202: OtpChallengeSerializer, **ERRORS},
)
class ResendOtpView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [OtpRequestThrottle]

    def post(self, request):
        data = _validated(ResendSerializer, request)
        otp_request = services.resend_code(
            raw_phone=data["phone_number"], purpose=data["purpose"]
        )
        return Response(
            OtpChallengeSerializer.from_request(otp_request),
            status=status.HTTP_202_ACCEPTED,
        )


# --- Session -----------------------------------------------------------------


@extend_schema(
    summary="The authenticated customer",
    description=(
        "Identity is taken from the access token, never from the request."
    ),
    responses={200: CustomerSerializer, **ERRORS},
)
class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Identity comes from the verified token, never from the request body
        # (section 37).
        return Response(CustomerSerializer(request.user).data)


@extend_schema(
    summary="Sign out",
    description=(
        "Revokes the refresh token. Idempotent -- signing out twice, or with "
        "an already-expired token, still returns 204. The access token stays "
        "valid until it expires, which is why its lifetime is short."
    ),
    request=LogoutSerializer,
    responses={204: None, **ERRORS},
)
class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = _validated(LogoutSerializer, request)
        services.logout(data["refresh"])
        return Response(status=status.HTTP_204_NO_CONTENT)


# --- Phone change ------------------------------------------------------------


@extend_schema(
    summary="Start a phone number change",
    description=(
        "Sends a code to the new number. Refused with PHONE_SAME_AS_CURRENT "
        "or PHONE_BELONGS_TO_OTHER (both 409). The account is unchanged."
    ),
    request=PhoneSerializer,
    responses={202: OtpChallengeSerializer, **ERRORS},
)
class PhoneChangeRequestView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [OtpRequestThrottle]

    def post(self, request):
        data = _validated(PhoneSerializer, request)
        otp_request = services.phone_change_request(
            customer=request.user, raw_phone=data["phone_number"]
        )
        return Response(
            OtpChallengeSerializer.from_request(otp_request),
            status=status.HTTP_202_ACCEPTED,
        )


@extend_schema(
    summary="Verify and apply the new phone number",
    description=(
        "Moves the account to the new number. Ownership is re-checked here, "
        "not only at request time, because the number can be claimed while "
        "the code is in flight. Pass the current `refresh` token to keep this "
        "device signed in when other devices are revoked."
    ),
    request=OtpCodeSerializer,
    responses={200: CustomerSerializer, **ERRORS},
)
class PhoneChangeVerifyView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [OtpVerifyThrottle]

    def post(self, request):
        data = _validated(OtpCodeSerializer, request)
        customer = services.phone_change_verify(
            customer=request.user,
            raw_phone=data["phone_number"],
            code=data["code"],
            # Sent by the client so the device making the change keeps its
            # session while every other device is signed out.
            current_refresh=request.data.get("refresh"),
        )
        return Response(CustomerSerializer(customer).data)


__all__ = [
    "LoginRequestOtpView",
    "LoginVerifyOtpView",
    "LogoutView",
    "MeView",
    "OtpPurpose",
    "PhoneChangeRequestView",
    "PhoneChangeVerifyView",
    "RegisterRequestOtpView",
    "RegisterVerifyOtpView",
    "ResendOtpView",
]

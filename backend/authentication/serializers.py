"""Request and response shapes.

Validation here is deliberately shallow -- format only. Anything that depends
on stored state (is this number taken? is this code correct?) belongs in
`services`, so the rules are not split across two layers.
"""

from __future__ import annotations

from django.conf import settings
from rest_framework import serializers

from .models import Customer, OtpPurpose, OtpRequest


class PhoneSerializer(serializers.Serializer):
    """Any spelling is accepted; `services.clean_phone` normalises it."""

    phone_number = serializers.CharField(max_length=20)


class OtpCodeSerializer(PhoneSerializer):
    code = serializers.CharField(min_length=4, max_length=10)


class RegisterVerifySerializer(OtpCodeSerializer):
    # Section 27: at least two non-whitespace characters.
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()

    def validate_full_name(self, value: str) -> str:
        cleaned = value.strip()
        if len(cleaned) < 2:
            raise serializers.ValidationError("Please enter your full name.")
        return cleaned


class ResendSerializer(PhoneSerializer):
    purpose = serializers.ChoiceField(choices=OtpPurpose.choices)


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()


class CustomerSerializer(serializers.ModelSerializer):
    """The authenticated customer, as the app renders it."""

    phone_number_display = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = [
            "id",
            "full_name",
            "email",
            "phone_number",
            "phone_number_display",
            "phone_verified",
            "account_status",
            "created_at",
        ]
        read_only_fields = fields

    def get_phone_number_display(self, obj: Customer) -> str:
        digits = obj.phone_number
        return f"+255 {digits[:3]} {digits[3:6]} {digits[6:]}"


class OtpChallengeSerializer(serializers.Serializer):
    """What the client needs to drive its countdown and resend button.

    The timings come from the server rather than being duplicated as constants
    in the app (section 43), so changing policy does not require a release.
    """

    expires_in = serializers.IntegerField()
    resend_available_in = serializers.IntegerField()
    otp_length = serializers.IntegerField()
    max_attempts = serializers.IntegerField()

    @classmethod
    def from_request(cls, request: OtpRequest) -> dict:
        return {
            "expires_in": request.seconds_until_expiry,
            "resend_available_in": request.seconds_until_resend,
            "otp_length": settings.OTP_LENGTH,
            "max_attempts": settings.OTP_MAX_ATTEMPTS,
        }


# --- Response documentation --------------------------------------------------
# These exist so the generated OpenAPI schema describes every body and status
# code (section 29). They are never used to build a response -- the views shape
# those directly -- but they are what the mobile team reads.


class TokenPairSerializer(serializers.Serializer):
    access = serializers.CharField()
    refresh = serializers.CharField()
    access_expires_in = serializers.IntegerField(
        help_text="Seconds until the access token expires."
    )


class SessionSerializer(serializers.Serializer):
    """Returned by both verify endpoints: who signed in, and their tokens."""

    customer = CustomerSerializer()
    tokens = TokenPairSerializer()


class ErrorBodySerializer(serializers.Serializer):
    code = serializers.CharField(
        help_text=(
            "Machine-readable failure code. Clients branch on this, never on "
            "`message`. See ErrorCode in authentication/errors.py."
        )
    )
    message = serializers.CharField(
        help_text="Human-readable text for logs and debugging. Not for display."
    )
    details = serializers.DictField(
        help_text=(
            "Extra context. `attempts_remaining` on OTP_INCORRECT, "
            "`retry_after_seconds` on rate limits, `field` on validation."
        )
    )


class ErrorEnvelopeSerializer(serializers.Serializer):
    error = ErrorBodySerializer()

"""Per-IP throttles (section 33).

These sit alongside the per-phone limits in `otp._enforce_request_limits`, and
the two answer different questions: the phone limit stops one number being
flooded, this stops one machine walking through many numbers.

Both are needed. Sections 15 and 19 require the API to say whether a number is
registered, which is account enumeration by design; per-IP throttling is what
keeps that from being a bulk-harvesting tool.
"""

from rest_framework.throttling import AnonRateThrottle, SimpleRateThrottle


class OtpRequestThrottle(SimpleRateThrottle):
    """Caps how fast one client can ask for codes, signed in or not."""

    scope = "otp_request"

    def get_cache_key(self, request, view):
        return self.cache_format % {
            "scope": self.scope,
            "ident": self.get_ident(request),
        }


class OtpVerifyThrottle(SimpleRateThrottle):
    """Caps verification attempts per client.

    The per-request attempt counter already limits guesses against one code;
    this limits guessing across many codes.
    """

    scope = "otp_verify"

    def get_cache_key(self, request, view):
        return self.cache_format % {
            "scope": self.scope,
            "ident": self.get_ident(request),
        }


__all__ = ["AnonRateThrottle", "OtpRequestThrottle", "OtpVerifyThrottle"]

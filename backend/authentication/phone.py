"""Tanzanian phone-number normalisation.

One canonical form is used everywhere: the nine significant digits, without the
country code and without the national leading zero. It is what the unique index
is built on, what OTP records are keyed by, and what the mobile client stores.

This deliberately mirrors `JhAppState.digitsOf` in
`mobile/lib/state/app_state.dart`. If the two ever disagree, the same person
can end up with two accounts -- one created via `0712...` and one via
`+255712...` -- so the same table of inputs is asserted on both sides, in
`authentication/tests/test_phone.py` here and in
`mobile/test/phone_normalisation_test.dart` there.
"""

from __future__ import annotations

import re

_NON_DIGITS = re.compile(r"\D")

# Tanzanian mobile numbers are nine digits beginning with 6 or 7. Landlines
# (2x) and short codes are not valid customer identifiers.
_VALID = re.compile(r"^[67]\d{8}$")

COUNTRY_CODE = "255"


def normalise(value: str | None) -> str:
    """Reduce any accepted spelling to the nine significant digits.

    Handles ``+255 712 345 678``, ``255712345678``, ``00255712345678``,
    ``0712345678`` and ``712 345 678`` identically. Anything that is not a
    digit is discarded first, so spaces, dashes and brackets are all fine.

    The three prefix strips are applied in sequence rather than as
    alternatives, so a malformed but common ``+255 0712...`` still resolves.
    """
    digits = _NON_DIGITS.sub("", value or "")

    if digits.startswith("00"):
        digits = digits[2:]
    if digits.startswith(COUNTRY_CODE):
        digits = digits[len(COUNTRY_CODE) :]
    if digits.startswith("0"):
        digits = digits[1:]

    return digits


def is_valid(digits: str) -> bool:
    """True when `digits` is already in canonical form and is a mobile number."""
    return bool(_VALID.match(digits))


def to_e164(digits: str) -> str:
    """`712345678` -> `+255712345678`.

    Only used at the provider boundary and for display; nothing else in the
    system stores a number in this shape.
    """
    return f"+{COUNTRY_CODE}{digits}"


def to_msisdn(digits: str) -> str:
    """`712345678` -> `255712345678`: country code, no plus.

    Distinct from `to_e164` because providers differ on the leading `+`, and
    sending the wrong one is the sort of mistake that fails silently on their
    side. Webline's examples (`31612345678`, `8801721970168`) use this form.
    """
    return f"{COUNTRY_CODE}{digits}"


def mask(digits: str) -> str:
    """`712345678` -> `+255 712 ... 678`, for logs and support tooling.

    Enough to identify a record in conversation with a customer, not enough to
    be a useful leak.
    """
    if len(digits) != 9:
        return "+255 ..."
    return f"+{COUNTRY_CODE} {digits[:3]} ... {digits[6:]}"

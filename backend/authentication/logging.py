"""Log hygiene.

Section 32 forbids complete OTP values in authentication logs, and phone
numbers are personal data that should not sit in plain text in a log
aggregator. This filter is installed on the root handler from the first commit
rather than added after an incident: the failure mode of forgetting it is
silent, and by the time anyone notices, the values are already shipped.
"""

from __future__ import annotations

import logging
import re

# Any run of 9+ digits, optionally carrying a +255 or 0 prefix.
_PHONE = re.compile(r"\+?(?:255)?0?\d{9}\b")

# A bare 4-8 digit run that follows an OTP-ish word.
_CODE = re.compile(
    r"(?i)\b(otp|code|pin)\b(\s*[:=]?\s*)(\d{4,8})\b",
)


def scrub(text: str) -> str:
    """Redact phone numbers and anything that looks like a code."""
    text = _CODE.sub(r"\1\2******", text)
    return _PHONE.sub(lambda m: _mask_phone(m.group(0)), text)


def _mask_phone(raw: str) -> str:
    digits = re.sub(r"\D", "", raw)
    tail = digits[-3:] if len(digits) >= 3 else "***"
    return f"+255 ... {tail}"


class MaskSensitiveFilter(logging.Filter):
    """Scrubs the formatted message and any string arguments."""

    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.msg, str):
            record.msg = scrub(record.msg)
        if record.args:
            if isinstance(record.args, dict):
                record.args = {
                    key: scrub(value) if isinstance(value, str) else value
                    for key, value in record.args.items()
                }
            else:
                record.args = tuple(
                    scrub(value) if isinstance(value, str) else value
                    for value in record.args
                )
        return True

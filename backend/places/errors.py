"""Places-specific error codes.

Raised as `authentication.errors.ApiError` -- that mechanism is reused as-is
rather than duplicated, same as `orders.errors`.
"""

from __future__ import annotations


class ErrorCode:
    PLACES_LOOKUP_FAILED = "PLACES_LOOKUP_FAILED"

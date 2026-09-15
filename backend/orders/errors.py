"""Order-specific error codes.

Raised as `authentication.errors.ApiError` -- that mechanism (and the
exception handler wired up in `REST_FRAMEWORK.EXCEPTION_HANDLER`) is reused
as-is rather than duplicated: nothing about it is actually authentication-
specific, it just happened to be built first.
"""

from __future__ import annotations


class ErrorCode:
    ORDER_NOT_FOUND = "ORDER_NOT_FOUND"
    ORDER_CANCEL_NOT_ALLOWED = "ORDER_CANCEL_NOT_ALLOWED"
    ORDER_NOT_COMPLETED = "ORDER_NOT_COMPLETED"
    ORDER_VEHICLE_UNAVAILABLE = "ORDER_VEHICLE_UNAVAILABLE"
    ORDER_DECLARATION_REQUIRED = "ORDER_DECLARATION_REQUIRED"

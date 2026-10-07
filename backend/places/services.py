"""Business logic for address search. Thin -- each function calls the Google
client and translates its failure into the one error envelope every endpoint
uses, same division of labour as `orders/services.py`.
"""

from __future__ import annotations

from authentication.errors import ApiError

from .errors import ErrorCode
from .google_places import GooglePlacesClient, ImproperlyConfiguredPlaces, PlacesLookupError


def _client() -> GooglePlacesClient:
    try:
        return GooglePlacesClient()
    except ImproperlyConfiguredPlaces as exc:
        # A deployment mistake, not a customer-facing failure mode -- but it
        # must not look like a transient "try again" error, so it still
        # answers through the same envelope rather than a raw 500.
        raise ApiError(
            ErrorCode.PLACES_LOOKUP_FAILED,
            "Address search is not configured.",
            http_status=503,
        ) from exc


def autocomplete(query: str, session_token: str) -> list[dict]:
    try:
        return _client().autocomplete(query, session_token)
    except PlacesLookupError as exc:
        raise ApiError(
            ErrorCode.PLACES_LOOKUP_FAILED,
            "Could not search for that address. Please try again.",
            http_status=502,
        ) from exc


def place_details(place_id: str, session_token: str) -> dict:
    try:
        return _client().place_details(place_id, session_token)
    except PlacesLookupError as exc:
        raise ApiError(
            ErrorCode.PLACES_LOOKUP_FAILED,
            "Could not look up that place. Please try again.",
            http_status=502,
        ) from exc


def reverse_geocode(lat: float, lng: float) -> str:
    try:
        return _client().reverse_geocode(lat, lng)
    except PlacesLookupError as exc:
        raise ApiError(
            ErrorCode.PLACES_LOOKUP_FAILED,
            "Could not resolve that location. Please try again.",
            http_status=502,
        ) from exc

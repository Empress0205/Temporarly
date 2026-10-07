"""Google Places API (New) + Geocoding API client.

Both are called from here only -- the API key never ships to the mobile app,
which calls our own `/api/places/*` endpoints instead (section 43's "never
guessed/embedded by the client" principle, same reasoning as the SMS provider
token).

Autocomplete and Place Details share one client-generated session token,
which is how Google bills the pair as a single session rather than per
keystroke -- the token is opaque to us, we just pass it through. Reverse
geocoding (the legacy Geocoding API) has no session concept.

Two things worth knowing about the New Places API specifically, the same
category of gotcha the Webline integration already hit once:

1. A field mask is required on every call (`X-Goog-FieldMask`) -- omitting it
   is a 400, not "give me everything".
2. Errors come back as ordinary JSON with an `error` object, at a non-200
   HTTP status this time (unlike Webline, which answers 200 even on failure)
   -- so status *and* body both matter, just not the way that integration
   needed them to.
"""

from __future__ import annotations

import requests
from django.conf import settings


class PlacesLookupError(Exception):
    """Google refused the request or returned something we can't use."""


class ImproperlyConfiguredPlaces(Exception):
    """A deployment mistake, not something a customer did -- surfaces loudly
    at construction time rather than as a tidy message in the app."""


class GooglePlacesClient:
    _AUTOCOMPLETE_URL = "https://places.googleapis.com/v1/places:autocomplete"
    _DETAILS_URL = "https://places.googleapis.com/v1/places/{place_id}"
    _GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"

    #: Biases results toward Dar es Salaam without excluding the rest of
    #: Tanzania -- a bias, not a restriction, so an exact match elsewhere
    #: still surfaces.
    _BIAS_LAT = -6.7924
    _BIAS_LNG = 39.2083
    _BIAS_RADIUS_M = 50_000.0

    _TIMEOUT = 8

    def __init__(self) -> None:
        self.api_key = settings.GOOGLE_PLACES_API_KEY
        if not self.api_key:
            raise ImproperlyConfiguredPlaces("GOOGLE_PLACES_API_KEY is empty")

    def autocomplete(self, query: str, session_token: str) -> list[dict]:
        payload = {
            "input": query,
            "sessionToken": session_token,
            "languageCode": "en",
            "regionCode": "TZ",
            "locationBias": {
                "circle": {
                    "center": {
                        "latitude": self._BIAS_LAT,
                        "longitude": self._BIAS_LNG,
                    },
                    "radius": self._BIAS_RADIUS_M,
                }
            },
        }
        body = self._post(
            self._AUTOCOMPLETE_URL,
            payload,
            field_mask="suggestions.placePrediction.placeId,"
            "suggestions.placePrediction.text",
        )

        results = []
        for item in body.get("suggestions", []):
            prediction = item.get("placePrediction")
            if not prediction:
                continue
            place_id = prediction.get("placeId")
            text = (prediction.get("text") or {}).get("text")
            if place_id and text:
                results.append({"place_id": place_id, "description": text})
        return results

    def place_details(self, place_id: str, session_token: str) -> dict:
        url = self._DETAILS_URL.format(place_id=place_id)
        body = self._get(
            url,
            params={"sessionToken": session_token},
            field_mask="location,formattedAddress",
        )

        location = body.get("location") or {}
        lat = location.get("latitude")
        lng = location.get("longitude")
        if lat is None or lng is None:
            raise PlacesLookupError("place details response had no location")

        address = body.get("formattedAddress") or f"{lat}, {lng}"
        return {"lat": lat, "lng": lng, "address": address}

    def reverse_geocode(self, lat: float, lng: float) -> str:
        try:
            response = requests.get(
                self._GEOCODE_URL,
                params={"latlng": f"{lat},{lng}", "key": self.api_key},
                timeout=self._TIMEOUT,
            )
        except requests.RequestException as exc:
            raise PlacesLookupError(f"could not reach Google: {exc}") from exc

        body = self._json(response)
        if body.get("status") != "OK":
            raise PlacesLookupError(body.get("status") or "unknown error")

        results = body.get("results") or []
        if not results:
            raise PlacesLookupError("no results")
        return results[0].get("formatted_address") or f"{lat}, {lng}"

    def _post(self, url: str, payload: dict, *, field_mask: str) -> dict:
        try:
            response = requests.post(
                url,
                json=payload,
                headers=self._headers(field_mask),
                timeout=self._TIMEOUT,
            )
        except requests.RequestException as exc:
            raise PlacesLookupError(f"could not reach Google: {exc}") from exc
        return self._parse(response)

    def _get(self, url: str, *, params: dict, field_mask: str) -> dict:
        try:
            response = requests.get(
                url,
                params=params,
                headers=self._headers(field_mask),
                timeout=self._TIMEOUT,
            )
        except requests.RequestException as exc:
            raise PlacesLookupError(f"could not reach Google: {exc}") from exc
        return self._parse(response)

    def _headers(self, field_mask: str) -> dict:
        return {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": self.api_key,
            "X-Goog-FieldMask": field_mask,
        }

    def _parse(self, response: requests.Response) -> dict:
        body = self._json(response)
        if response.status_code != 200:
            error = body.get("error", {}) if isinstance(body, dict) else {}
            raise PlacesLookupError(
                error.get("message") or f"HTTP {response.status_code}"
            )
        return body

    @staticmethod
    def _json(response: requests.Response) -> dict:
        try:
            return response.json()
        except ValueError:
            raise PlacesLookupError(
                f"Google returned non-JSON (HTTP {response.status_code})"
            ) from None

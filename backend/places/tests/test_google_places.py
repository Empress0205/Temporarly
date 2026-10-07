"""The Google Places client. Every test mocks the HTTP call -- nothing here
spends real quota, same discipline as `authentication/tests/test_sms.py`.
"""

from __future__ import annotations

from unittest.mock import patch

import requests
from django.test import SimpleTestCase, override_settings

from places.google_places import (
    GooglePlacesClient,
    ImproperlyConfiguredPlaces,
    PlacesLookupError,
)

PLACES = {"GOOGLE_PLACES_API_KEY": "test-key"}


class FakeResponse:
    def __init__(self, payload, status_code=200, valid_json=True):
        self._payload = payload
        self.status_code = status_code
        self._valid_json = valid_json

    def json(self):
        if not self._valid_json:
            raise ValueError("not json")
        return self._payload


@override_settings(**PLACES)
class AutocompleteTests(SimpleTestCase):
    def test_sends_the_documented_request(self):
        with patch("places.google_places.requests.post") as post:
            post.return_value = FakeResponse(
                {
                    "suggestions": [
                        {
                            "placePrediction": {
                                "placeId": "abc123",
                                "text": {"text": "Kariakoo, Dar es Salaam"},
                            }
                        }
                    ]
                }
            )
            results = GooglePlacesClient().autocomplete("Kariakoo", "session-1")

        args, kwargs = post.call_args
        self.assertEqual(args[0], "https://places.googleapis.com/v1/places:autocomplete")
        self.assertEqual(kwargs["json"]["input"], "Kariakoo")
        self.assertEqual(kwargs["json"]["sessionToken"], "session-1")
        self.assertEqual(kwargs["headers"]["X-Goog-Api-Key"], "test-key")
        self.assertIn("suggestions.placePrediction", kwargs["headers"]["X-Goog-FieldMask"])
        self.assertEqual(kwargs["timeout"], 8)

        self.assertEqual(
            results, [{"place_id": "abc123", "description": "Kariakoo, Dar es Salaam"}]
        )

    def test_entries_missing_a_place_id_or_text_are_skipped(self):
        with patch("places.google_places.requests.post") as post:
            post.return_value = FakeResponse(
                {
                    "suggestions": [
                        {"placePrediction": {"placeId": "ok", "text": {"text": "Goba"}}},
                        {"placePrediction": {"placeId": "no-text"}},
                        {"placePrediction": {"text": {"text": "no id"}}},
                    ]
                }
            )
            results = GooglePlacesClient().autocomplete("Goba", "session-1")

        self.assertEqual(results, [{"place_id": "ok", "description": "Goba"}])

    def test_an_error_status_with_http_200_is_still_a_failure(self):
        # The New Places API's own failure shape: a 4xx/5xx with an `error`
        # object, unlike Webline's "200 always" trap -- still worth asserting
        # explicitly, since a client this young is exactly where that
        # assumption could slip.
        with patch("places.google_places.requests.post") as post:
            post.return_value = FakeResponse(
                {"error": {"message": "API key not valid"}}, status_code=400
            )
            with self.assertRaises(PlacesLookupError) as caught:
                GooglePlacesClient().autocomplete("x", "session-1")
        self.assertIn("API key not valid", str(caught.exception))

    def test_a_timeout_is_a_failure(self):
        with patch("places.google_places.requests.post") as post:
            post.side_effect = requests.Timeout("timed out")
            with self.assertRaises(PlacesLookupError):
                GooglePlacesClient().autocomplete("x", "session-1")

    def test_non_json_response_is_a_failure(self):
        with patch("places.google_places.requests.post") as post:
            post.return_value = FakeResponse(None, status_code=502, valid_json=False)
            with self.assertRaises(PlacesLookupError):
                GooglePlacesClient().autocomplete("x", "session-1")


@override_settings(**PLACES)
class PlaceDetailsTests(SimpleTestCase):
    def test_parses_location_and_address(self):
        with patch("places.google_places.requests.get") as get:
            get.return_value = FakeResponse(
                {
                    "location": {"latitude": -6.7924, "longitude": 39.2083},
                    "formattedAddress": "Kariakoo Market, Dar es Salaam",
                }
            )
            result = GooglePlacesClient().place_details("abc123", "session-1")

        args, kwargs = get.call_args
        self.assertEqual(
            args[0], "https://places.googleapis.com/v1/places/abc123"
        )
        self.assertEqual(kwargs["params"], {"sessionToken": "session-1"})
        self.assertEqual(
            result,
            {"lat": -6.7924, "lng": 39.2083, "address": "Kariakoo Market, Dar es Salaam"},
        )

    def test_missing_location_is_a_failure(self):
        with patch("places.google_places.requests.get") as get:
            get.return_value = FakeResponse({"formattedAddress": "Nowhere"})
            with self.assertRaises(PlacesLookupError):
                GooglePlacesClient().place_details("abc123", "session-1")


@override_settings(**PLACES)
class ReverseGeocodeTests(SimpleTestCase):
    def test_returns_the_first_formatted_address(self):
        with patch("places.google_places.requests.get") as get:
            get.return_value = FakeResponse(
                {
                    "status": "OK",
                    "results": [{"formatted_address": "Morogoro Road, Dar es Salaam"}],
                }
            )
            address = GooglePlacesClient().reverse_geocode(-6.7924, 39.2083)

        kwargs = get.call_args.kwargs
        self.assertEqual(kwargs["params"]["latlng"], "-6.7924,39.2083")
        self.assertEqual(address, "Morogoro Road, Dar es Salaam")

    def test_a_non_ok_status_is_a_failure(self):
        with patch("places.google_places.requests.get") as get:
            get.return_value = FakeResponse({"status": "ZERO_RESULTS", "results": []})
            with self.assertRaises(PlacesLookupError):
                GooglePlacesClient().reverse_geocode(0, 0)


class ConfigurationTests(SimpleTestCase):
    @override_settings(GOOGLE_PLACES_API_KEY="")
    def test_missing_key_is_refused_at_construction(self):
        with self.assertRaises(ImproperlyConfiguredPlaces):
            GooglePlacesClient()

"""The `/api/places/*` endpoints: auth, validation, and the response shape.
The Google client itself is covered in `test_google_places.py`; here it's
mocked at the HTTP boundary so these stay about the view layer.
"""

from __future__ import annotations

from unittest.mock import patch

from django.test import override_settings
from rest_framework.test import APIClient

from authentication.tests.support import ApiTestCase
from places.errors import ErrorCode
from places.tests.test_google_places import FakeResponse

PLACES = {"GOOGLE_PLACES_API_KEY": "test-key", "SMS_PROVIDER": "memory"}


@override_settings(**PLACES)
class PlacesApiTestCase(ApiTestCase):
    """An authenticated customer, ready to search."""

    def setUp(self) -> None:
        super().setUp()
        session = self.register(phone_number="712000111")
        self.authenticate(session["tokens"])


class AutocompleteEndpointTests(PlacesApiTestCase):
    def test_returns_predictions(self):
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
            response = self.client.get(
                "/api/places/autocomplete",
                {"q": "Kariakoo", "session_token": "session-1"},
            )

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(
            response.data,
            [{"place_id": "abc123", "description": "Kariakoo, Dar es Salaam"}],
        )

    def test_missing_query_is_rejected_before_calling_google(self):
        with patch("places.google_places.requests.post") as post:
            response = self.client.get(
                "/api/places/autocomplete", {"session_token": "session-1"}
            )
        post.assert_not_called()
        self.assertEqual(response.status_code, 400)

    def test_a_google_failure_surfaces_as_places_lookup_failed(self):
        with patch("places.google_places.requests.post") as post:
            post.return_value = FakeResponse(
                {"error": {"message": "quota exceeded"}}, status_code=429
            )
            response = self.client.get(
                "/api/places/autocomplete",
                {"q": "Kariakoo", "session_token": "session-1"},
            )

        self.assertEqual(response.status_code, 502)
        self.assertErrorCode(response, ErrorCode.PLACES_LOOKUP_FAILED)

    def test_unauthenticated_requests_are_refused(self):
        anonymous = APIClient()
        response = anonymous.get(
            "/api/places/autocomplete",
            {"q": "Kariakoo", "session_token": "session-1"},
        )
        self.assertEqual(response.status_code, 401)


class PlaceDetailsEndpointTests(PlacesApiTestCase):
    def test_returns_the_resolved_point(self):
        with patch("places.google_places.requests.get") as get:
            get.return_value = FakeResponse(
                {
                    "location": {"latitude": -6.7924, "longitude": 39.2083},
                    "formattedAddress": "Kariakoo Market, Dar es Salaam",
                }
            )
            response = self.client.get(
                "/api/places/details",
                {"place_id": "abc123", "session_token": "session-1"},
            )

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(
            response.data,
            {
                "lat": -6.7924,
                "lng": 39.2083,
                "address": "Kariakoo Market, Dar es Salaam",
            },
        )

    def test_missing_place_id_is_rejected(self):
        response = self.client.get(
            "/api/places/details", {"session_token": "session-1"}
        )
        self.assertEqual(response.status_code, 400)


class ReverseGeocodeEndpointTests(PlacesApiTestCase):
    def test_returns_the_address_for_a_point(self):
        with patch("places.google_places.requests.get") as get:
            get.return_value = FakeResponse(
                {
                    "status": "OK",
                    "results": [{"formatted_address": "Morogoro Road, Dar es Salaam"}],
                }
            )
            response = self.client.get(
                "/api/places/reverse-geocode", {"lat": "-6.7924", "lng": "39.2083"}
            )

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(
            response.data,
            {
                "lat": -6.7924,
                "lng": 39.2083,
                "address": "Morogoro Road, Dar es Salaam",
            },
        )

    def test_non_numeric_coordinates_are_rejected(self):
        response = self.client.get(
            "/api/places/reverse-geocode", {"lat": "nowhere", "lng": "39.2083"}
        )
        self.assertEqual(response.status_code, 400)

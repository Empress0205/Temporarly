"""HTTP layer. Thin, same division of labour as `orders/views.py`: each view
validates its input, calls one service function and shapes the response.

Every endpoint requires a signed-in customer (the project default -- see
`REST_FRAMEWORK.DEFAULT_PERMISSION_CLASSES`) so an unauthenticated caller
can't run up the Google bill.
"""

from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from authentication.serializers import ErrorEnvelopeSerializer

from . import services
from .serializers import (
    AutocompleteQuerySerializer,
    PlaceDetailSerializer,
    PlaceDetailsQuerySerializer,
    PlacePredictionSerializer,
    ReverseGeocodeQuerySerializer,
)

#: Every endpoint can fail this way; listed once rather than repeated per view.
ERRORS = {400: ErrorEnvelopeSerializer, 401: ErrorEnvelopeSerializer, 502: ErrorEnvelopeSerializer}


def _validated(serializer_class, request):
    serializer = serializer_class(data=request.query_params)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


@extend_schema(
    summary="Address search suggestions",
    description=(
        "Ranked predictions for a partial address, Google-Places-backed. "
        "`session_token` is a client-generated UUID reused across every "
        "keystroke of one search and passed again to the details lookup -- "
        "that pairing is what lets Google bill it as one session rather "
        "than per request."
    ),
    responses={200: PlacePredictionSerializer(many=True), **ERRORS},
)
class PlacesAutocompleteView(APIView):
    def get(self, request):
        data = _validated(AutocompleteQuerySerializer, request)
        results = services.autocomplete(data["q"], data["session_token"])
        return Response(PlacePredictionSerializer(results, many=True).data)


@extend_schema(
    summary="Resolve a prediction to a point",
    description="`place_id` comes from an autocomplete result; reuse that search's `session_token`.",
    responses={200: PlaceDetailSerializer, **ERRORS},
)
class PlaceDetailsView(APIView):
    def get(self, request):
        data = _validated(PlaceDetailsQuerySerializer, request)
        result = services.place_details(data["place_id"], data["session_token"])
        return Response(PlaceDetailSerializer(result).data)


@extend_schema(
    summary="Reverse-geocode a dragged pin",
    responses={200: PlaceDetailSerializer, **ERRORS},
)
class ReverseGeocodeView(APIView):
    def get(self, request):
        data = _validated(ReverseGeocodeQuerySerializer, request)
        address = services.reverse_geocode(data["lat"], data["lng"])
        return Response(
            PlaceDetailSerializer(
                {"lat": data["lat"], "lng": data["lng"], "address": address}
            ).data
        )

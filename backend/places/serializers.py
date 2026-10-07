"""Request and response shapes for the places endpoints."""

from __future__ import annotations

from rest_framework import serializers


class AutocompleteQuerySerializer(serializers.Serializer):
    q = serializers.CharField(min_length=1, max_length=200)
    session_token = serializers.CharField(min_length=1, max_length=200)


class PlaceDetailsQuerySerializer(serializers.Serializer):
    place_id = serializers.CharField(min_length=1, max_length=300)
    session_token = serializers.CharField(min_length=1, max_length=200)


class ReverseGeocodeQuerySerializer(serializers.Serializer):
    lat = serializers.FloatField()
    lng = serializers.FloatField()


class PlacePredictionSerializer(serializers.Serializer):
    place_id = serializers.CharField()
    description = serializers.CharField()


class PlaceDetailSerializer(serializers.Serializer):
    lat = serializers.FloatField()
    lng = serializers.FloatField()
    address = serializers.CharField()

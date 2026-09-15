"""Request and response shapes.

As in `authentication/serializers.py`, validation here is shallow -- format
only. Anything that depends on stored state or business rules (is the
declaration accepted? is this vehicle available? is the phone number a real
Tanzanian mobile number?) belongs in `services.py`.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import (
    Driver,
    Order,
    PackageSize,
    PackageType,
    PaymentMethod,
    Vehicle,
)


class DriverSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        fields = ["id", "name", "vehicle", "plate", "rating"]
        read_only_fields = fields


class OrderSerializer(serializers.ModelSerializer):
    """The shape the client renders an order in -- list and detail alike."""

    driver = DriverSerializer(read_only=True)
    distance_km = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            "id",
            "order_number",
            "status",
            "stage",
            "vehicle",
            "price_tsh",
            "paid",
            "payment_method",
            "driver",
            "pickup_address",
            "pickup_landmark",
            "pickup_instructions",
            "pickup_lat",
            "pickup_lng",
            "dropoff_address",
            "dropoff_landmark",
            "dropoff_lat",
            "dropoff_lng",
            "delivery_instructions",
            "recipient_name",
            "recipient_phone",
            "package_type",
            "package_size",
            "quantity",
            "package_description",
            "handling_instructions",
            "photo_url",
            "distance_km",
            "my_rating",
            "created_at",
        ]
        read_only_fields = fields

    def get_distance_km(self, obj: Order) -> float:
        return round(obj.distance_km, 2)

    def get_photo_url(self, obj: Order) -> str | None:
        if not obj.package_photo:
            return None
        request = self.context.get("request")
        url = obj.package_photo.url
        return request.build_absolute_uri(url) if request else url


class OrderCreateSerializer(serializers.Serializer):
    """Mirrors `JhOrderDraft` on the mobile side field-for-field."""

    vehicle = serializers.ChoiceField(choices=Vehicle.choices)
    payment_method = serializers.ChoiceField(
        choices=PaymentMethod.choices, default=PaymentMethod.PAY_AFTER_DELIVERY
    )

    pickup_address = serializers.CharField(max_length=255)
    pickup_landmark = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default=""
    )
    pickup_instructions = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )
    pickup_lat = serializers.FloatField()
    pickup_lng = serializers.FloatField()

    dropoff_address = serializers.CharField(max_length=255)
    dropoff_landmark = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default=""
    )
    dropoff_lat = serializers.FloatField()
    dropoff_lng = serializers.FloatField()
    delivery_instructions = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )

    recipient_name = serializers.CharField(max_length=150)
    # Any spelling is accepted; `services.create_order` normalises it, same as
    # `PhoneSerializer` in the authentication app.
    recipient_phone = serializers.CharField(max_length=20)

    package_type = serializers.ChoiceField(choices=PackageType.choices)
    package_size = serializers.ChoiceField(choices=PackageSize.choices)
    quantity = serializers.IntegerField(min_value=1, max_value=20, default=1)
    package_description = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )
    handling_instructions = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )
    package_photo = serializers.ImageField(required=False, allow_null=True)

    declaration_accepted = serializers.BooleanField(default=False)

    def validate_recipient_name(self, value: str) -> str:
        cleaned = value.strip()
        if len(cleaned) < 2:
            raise serializers.ValidationError("Please enter the recipient's name.")
        return cleaned


class OrderRatingSerializer(serializers.Serializer):
    stars = serializers.IntegerField(min_value=1, max_value=5)

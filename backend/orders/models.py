"""Data model for the Orders module.

The choices below deliberately mirror the Dart enums in
`mobile/lib/orders/order_models.dart` value-for-value, so the two sides read
as one vocabulary rather than two that happen to agree today.

Driver assignment and stage/status progression are edited by hand in
`/admin/` for now -- there is no driver app yet to do it for real (see
`services.py` and `admin.py`).
"""

from __future__ import annotations

import uuid

from django.conf import settings
from django.db import models

from .geo import haversine_km


class OrderStatus(models.TextChoices):
    IN_TRANSIT = "IN_TRANSIT", "In transit"
    COMPLETED = "COMPLETED", "Completed"
    CANCELLED = "CANCELLED", "Cancelled"


class TrackingStage(models.TextChoices):
    REQUEST_CREATED = "REQUEST_CREATED", "Request created"
    DRIVER_ASSIGNED = "DRIVER_ASSIGNED", "Driver assigned"
    DRIVER_ARRIVING = "DRIVER_ARRIVING", "Driver arriving"
    PICKED_UP = "PICKED_UP", "Picked up"
    DELIVERED = "DELIVERED", "Delivered"

    @property
    def index(self) -> int:
        """Position in the sequence above -- what `cancel_order` gates on."""
        return list(TrackingStage).index(self)


class Vehicle(models.TextChoices):
    MOTORCYCLE = "MOTORCYCLE", "Motorcycle"
    BAJAJI = "BAJAJI", "Bajaji"
    CAR = "CAR", "Car"
    VAN = "VAN", "Lorry"


class PackageType(models.TextChoices):
    DOCUMENTS = "DOCUMENTS", "Documents"
    CLOTHES = "CLOTHES", "Clothes"
    FOOD = "FOOD", "Food"
    ELECTRONICS = "ELECTRONICS", "Electronics"
    HOUSEHOLD = "HOUSEHOLD", "Household item"
    OTHER = "OTHER", "Other"


class PackageSize(models.TextChoices):
    SMALL = "SMALL", "Small"
    MEDIUM = "MEDIUM", "Medium"
    LARGE = "LARGE", "Large"


class PaymentMethod(models.TextChoices):
    # The only method the mobile app offers today; the field leaves room for
    # mobile money / card later without a schema change.
    PAY_AFTER_DELIVERY = "PAY_AFTER_DELIVERY", "Pay after delivery"


class Driver(models.Model):
    """A courier. Created and assigned by hand in `/admin/` until the driver
    app (built separately) can self-register and self-assign."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=9, blank=True, default="")
    vehicle = models.CharField(max_length=16, choices=Vehicle.choices)
    plate = models.CharField(max_length=20)

    # Admin-set for now. Averaging `Order.my_rating` once real ratings exist
    # is a reasonable follow-up, not done here.
    rating = models.DecimalField(max_digits=2, decimal_places=1, default=5.0)

    # Lets admin retire a driver without deleting the orders they carried.
    active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "drivers"

    def __str__(self) -> str:
        return f"{self.name} ({self.plate})"


def _order_number(created_at) -> str:
    """`JHD-YYYYMMDD-<5-char hex>`. No sequence table or row locking needed --
    the hex suffix makes a collision astronomically unlikely without either,
    and it reads the same as the client-generated ids the app already shows."""
    return f"JHD-{created_at:%Y%m%d}-{uuid.uuid4().hex[:5].upper()}"


def _package_photo_path(instance: "Order", filename: str) -> str:
    # `timezone.now()` rather than `instance.created_at`: the auto_now_add
    # field isn't guaranteed to be populated on the instance yet at the point
    # a FileField's own pre_save (which calls this) runs during the same
    # `save()`. `instance.id` is safe -- the UUID default is set in Python at
    # construction time, well before any save.
    from django.utils import timezone

    return f"package_photos/{timezone.now():%Y/%m}/{instance.id}/{filename}"


class Order(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=32, unique=True, editable=False)

    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="orders"
    )
    driver = models.ForeignKey(
        Driver,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="orders",
    )

    status = models.CharField(
        max_length=16, choices=OrderStatus.choices, default=OrderStatus.IN_TRANSIT
    )
    stage = models.CharField(
        max_length=24,
        choices=TrackingStage.choices,
        default=TrackingStage.REQUEST_CREATED,
    )

    vehicle = models.CharField(max_length=16, choices=Vehicle.choices)
    # Computed once at creation (see `pricing.py`) and stored: a later change
    # to the rate table must never rewrite what an existing order was quoted.
    price_tsh = models.PositiveIntegerField()
    paid = models.BooleanField(default=False)
    payment_method = models.CharField(
        max_length=24,
        choices=PaymentMethod.choices,
        default=PaymentMethod.PAY_AFTER_DELIVERY,
    )

    # --- Route ----------------------------------------------------------
    pickup_address = models.CharField(max_length=255)
    pickup_landmark = models.CharField(max_length=255, blank=True, default="")
    pickup_instructions = models.CharField(max_length=500, blank=True, default="")
    pickup_lat = models.FloatField()
    pickup_lng = models.FloatField()
    dropoff_address = models.CharField(max_length=255)
    dropoff_landmark = models.CharField(max_length=255, blank=True, default="")
    dropoff_lat = models.FloatField()
    dropoff_lng = models.FloatField()
    # The drop-off note -- named to match `JhOrder.deliveryInstructions`
    # exactly, not `dropoff_instructions`, so wiring the mobile app up later
    # is a direct field-for-field mapping.
    delivery_instructions = models.CharField(max_length=500, blank=True, default="")

    # --- Recipient --------------------------------------------------------
    recipient_name = models.CharField(max_length=150)
    # Same nine-digit canonical form as `Customer.phone_number`.
    recipient_phone = models.CharField(max_length=9)

    # --- Package ------------------------------------------------------------
    package_type = models.CharField(max_length=16, choices=PackageType.choices)
    package_size = models.CharField(max_length=16, choices=PackageSize.choices)
    quantity = models.PositiveSmallIntegerField(default=1)
    package_description = models.CharField(max_length=500, blank=True, default="")
    handling_instructions = models.CharField(max_length=500, blank=True, default="")
    package_photo = models.ImageField(
        upload_to=_package_photo_path, null=True, blank=True
    )

    # Recorded at creation -- the customer's confirmation that the package
    # holds nothing prohibited. Required True server-side (see `services.py`),
    # the same "server decides" shift Sprint 1 made for every auth rule.
    declaration_accepted = models.BooleanField(default=False)

    # 1-5, set once by `rate_order`. Null until the customer rates it.
    my_rating = models.PositiveSmallIntegerField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "orders"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["customer", "status"]),
            models.Index(fields=["order_number"]),
        ]

    def __str__(self) -> str:
        return self.order_number

    def save(self, *args, **kwargs):
        if not self.order_number:
            # `created_at` (auto_now_add) is only populated by Django during
            # the insert this call is about to make, so it isn't readable yet
            # -- the current time is close enough for a display id.
            from django.utils import timezone

            self.order_number = _order_number(timezone.now())
        super().save(*args, **kwargs)

    @property
    def distance_km(self) -> float:
        return haversine_km(
            self.pickup_lat, self.pickup_lng, self.dropoff_lat, self.dropoff_lng
        )

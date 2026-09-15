"""Shared test helpers for the orders app.

Reuses `authentication.tests.support.ApiTestCase` for the customer/session
machinery rather than re-implementing it.
"""

from __future__ import annotations

from decimal import Decimal

from django.test import override_settings

from authentication.models import Customer
from authentication.tests.support import ApiTestCase
from orders.models import Driver, Order, PackageSize, PackageType, Vehicle


@override_settings(SMS_PROVIDER="memory")
class OrdersApiTestCase(ApiTestCase):
    """An authenticated customer, ready to place orders."""

    customer_phone = "712345678"

    def setUp(self) -> None:
        super().setUp()
        session = self.register(phone_number=self.customer_phone)
        self.authenticate(session["tokens"])
        self.customer = Customer.objects.get(phone_number=self.customer_phone)

    def make_driver(self, **overrides) -> Driver:
        defaults = dict(
            name="John Michael",
            phone_number="712345678",
            vehicle=Vehicle.MOTORCYCLE,
            plate="T 123 ABC",
            rating=Decimal("4.8"),
        )
        defaults.update(overrides)
        return Driver.objects.create(**defaults)

    def make_order(self, customer: Customer | None = None, **overrides) -> Order:
        defaults = dict(
            customer=customer or self.customer,
            vehicle=Vehicle.MOTORCYCLE,
            price_tsh=5000,
            pickup_address="Makongo Juu, Dar es Salaam",
            pickup_lat=-6.7723,
            pickup_lng=39.2199,
            dropoff_address="Goba, Dar es Salaam",
            dropoff_lat=-6.70,
            dropoff_lng=39.20,
            recipient_name="Juma Ally",
            recipient_phone="712345678",
            package_type=PackageType.DOCUMENTS,
            package_size=PackageSize.SMALL,
            declaration_accepted=True,
        )
        defaults.update(overrides)
        return Order.objects.create(**defaults)

    def order_payload(self, **overrides) -> dict:
        """A valid `OrderCreateSerializer` payload, ready to POST."""
        payload = {
            "vehicle": "MOTORCYCLE",
            "payment_method": "PAY_AFTER_DELIVERY",
            "pickup_address": "Makongo Juu, Dar es Salaam",
            "pickup_lat": -6.7723,
            "pickup_lng": 39.2199,
            "dropoff_address": "Goba, Dar es Salaam",
            "dropoff_lat": -6.70,
            "dropoff_lng": 39.20,
            "recipient_name": "Juma Ally",
            "recipient_phone": "712345678",
            "package_type": "DOCUMENTS",
            "package_size": "SMALL",
            "quantity": 1,
            "declaration_accepted": True,
        }
        payload.update(overrides)
        return payload

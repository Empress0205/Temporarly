"""Order flows: creation/pricing, listing, cancel and rating.

Mirrors the widget tests in `mobile/test/orders_flow_test.dart` where the
same rule exists on both sides (cancel gated on stage, rating gated on
status) -- the server is now the one actually enforcing them.
"""

from __future__ import annotations

import base64

from django.conf import settings
from django.core.files.uploadedfile import SimpleUploadedFile

from authentication.models import Customer
from orders.errors import ErrorCode
from orders.geo import haversine_km
from orders.models import Order, OrderStatus, TrackingStage

from .support import OrdersApiTestCase

# A real, decodable 1x1 PNG -- Pillow (via ImageField) rejects arbitrary bytes.
_TINY_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY"
    "42YAAAAASUVORK5CYII="
)


class CreateOrderTests(OrdersApiTestCase):
    def test_price_is_computed_server_side_from_distance(self):
        payload = self.order_payload()
        response = self.client.post("/api/orders", payload, format="json")
        self.assertEqual(response.status_code, 201, response.data)

        distance_km = haversine_km(
            payload["pickup_lat"],
            payload["pickup_lng"],
            payload["dropoff_lat"],
            payload["dropoff_lng"],
        )
        expected_price = max(
            settings.ORDER_MIN_PRICE_TSH,
            round(distance_km * settings.ORDER_RATE_PER_KM_TSH["MOTORCYCLE"]),
        )
        self.assertEqual(response.data["price_tsh"], expected_price)
        self.assertGreater(expected_price, settings.ORDER_MIN_PRICE_TSH)

        order = Order.objects.get(id=response.data["id"])
        self.assertTrue(order.order_number.startswith("JHD-"))
        self.assertEqual(order.status, OrderStatus.IN_TRANSIT)
        self.assertEqual(order.stage, TrackingStage.REQUEST_CREATED)
        self.assertEqual(order.customer, self.customer)

    def test_a_short_hop_is_floored_at_the_minimum_price(self):
        # Two points a few metres apart -- far below what any per-km rate
        # would charge, so the floor is what actually applies.
        payload = self.order_payload(dropoff_lat=-6.77235, dropoff_lng=39.21995)
        response = self.client.post("/api/orders", payload, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["price_tsh"], settings.ORDER_MIN_PRICE_TSH)

    def test_declaration_must_be_accepted(self):
        payload = self.order_payload(declaration_accepted=False)
        response = self.client.post("/api/orders", payload, format="json")
        self.assertEqual(response.status_code, 400, response.data)
        self.assertErrorCode(response, ErrorCode.ORDER_DECLARATION_REQUIRED)
        self.assertFalse(Order.objects.exists())

    def test_van_is_available_and_priced_at_its_own_rate(self):
        payload = self.order_payload(vehicle="VAN")
        response = self.client.post("/api/orders", payload, format="json")
        self.assertEqual(response.status_code, 201, response.data)

        distance_km = haversine_km(
            payload["pickup_lat"],
            payload["pickup_lng"],
            payload["dropoff_lat"],
            payload["dropoff_lng"],
        )
        expected_price = max(
            settings.ORDER_MIN_PRICE_TSH,
            round(distance_km * settings.ORDER_RATE_PER_KM_TSH["VAN"]),
        )
        self.assertEqual(response.data["price_tsh"], expected_price)

    def test_bajaji_is_available_and_priced_at_its_own_rate(self):
        payload = self.order_payload(vehicle="BAJAJI")
        response = self.client.post("/api/orders", payload, format="json")
        self.assertEqual(response.status_code, 201, response.data)

        distance_km = haversine_km(
            payload["pickup_lat"],
            payload["pickup_lng"],
            payload["dropoff_lat"],
            payload["dropoff_lng"],
        )
        expected_price = max(
            settings.ORDER_MIN_PRICE_TSH,
            round(distance_km * settings.ORDER_RATE_PER_KM_TSH["BAJAJI"]),
        )
        self.assertEqual(response.data["price_tsh"], expected_price)

    def test_an_invalid_recipient_phone_is_rejected(self):
        payload = self.order_payload(recipient_phone="12345")
        response = self.client.post("/api/orders", payload, format="json")
        self.assertEqual(response.status_code, 400, response.data)

    def test_a_photo_can_be_attached_and_comes_back_as_a_url(self):
        photo = SimpleUploadedFile("package.png", _TINY_PNG, content_type="image/png")
        payload = self.order_payload()
        payload["package_photo"] = photo
        response = self.client.post("/api/orders", payload, format="multipart")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertIsNotNone(response.data["photo_url"])
        self.assertIn("package_photos/", response.data["photo_url"])

    def test_no_photo_means_no_photo_url(self):
        response = self.client.post(
            "/api/orders", self.order_payload(), format="json"
        )
        self.assertEqual(response.status_code, 201, response.data)
        self.assertIsNone(response.data["photo_url"])


class ListAndDetailTests(OrdersApiTestCase):
    def test_listing_is_scoped_to_the_signed_in_customer(self):
        other = Customer.objects.create_customer(
            phone_number="765123456", full_name="Neema Said", email="neema@example.com"
        )
        self.make_order()
        self.make_order(customer=other)

        response = self.client.get("/api/orders")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(len(response.data), 1)

    def test_bucket_filters_by_status(self):
        self.make_order(status=OrderStatus.IN_TRANSIT)
        self.make_order(status=OrderStatus.COMPLETED)
        self.make_order(status=OrderStatus.CANCELLED)

        response = self.client.get("/api/orders", {"bucket": "completed"})
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["status"], "COMPLETED")

    def test_detail_404s_for_someone_elses_order(self):
        other = Customer.objects.create_customer(
            phone_number="765123456", full_name="Neema Said", email="neema@example.com"
        )
        order = self.make_order(customer=other)

        response = self.client.get(f"/api/orders/{order.id}")
        self.assertEqual(response.status_code, 404, response.data)
        self.assertErrorCode(response, ErrorCode.ORDER_NOT_FOUND)


class CancelOrderTests(OrdersApiTestCase):
    def test_cancel_is_allowed_before_pickup(self):
        order = self.make_order(stage=TrackingStage.DRIVER_ARRIVING)
        response = self.client.post(f"/api/orders/{order.id}/cancel")
        self.assertEqual(response.status_code, 200, response.data)
        order.refresh_from_db()
        self.assertEqual(order.status, OrderStatus.CANCELLED)

    def test_cancel_is_rejected_once_picked_up(self):
        order = self.make_order(stage=TrackingStage.PICKED_UP)
        response = self.client.post(f"/api/orders/{order.id}/cancel")
        self.assertEqual(response.status_code, 409, response.data)
        self.assertErrorCode(response, ErrorCode.ORDER_CANCEL_NOT_ALLOWED)
        order.refresh_from_db()
        self.assertEqual(order.status, OrderStatus.IN_TRANSIT)

    def test_cancelling_an_already_cancelled_order_is_rejected(self):
        order = self.make_order(status=OrderStatus.CANCELLED)
        response = self.client.post(f"/api/orders/{order.id}/cancel")
        self.assertEqual(response.status_code, 409, response.data)


class RateOrderTests(OrdersApiTestCase):
    def test_rating_a_completed_order_succeeds(self):
        order = self.make_order(
            status=OrderStatus.COMPLETED, stage=TrackingStage.DELIVERED
        )
        response = self.client.post(f"/api/orders/{order.id}/rate", {"stars": 5})
        self.assertEqual(response.status_code, 200, response.data)
        order.refresh_from_db()
        self.assertEqual(order.my_rating, 5)

    def test_rating_an_in_transit_order_is_rejected(self):
        order = self.make_order(status=OrderStatus.IN_TRANSIT)
        response = self.client.post(f"/api/orders/{order.id}/rate", {"stars": 4})
        self.assertEqual(response.status_code, 409, response.data)
        self.assertErrorCode(response, ErrorCode.ORDER_NOT_COMPLETED)

    def test_stars_outside_one_to_five_are_rejected(self):
        order = self.make_order(status=OrderStatus.COMPLETED)
        response = self.client.post(f"/api/orders/{order.id}/rate", {"stars": 6})
        self.assertEqual(response.status_code, 400, response.data)

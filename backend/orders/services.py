"""The order flows.

Views stay thin: they validate input and call one function here, same
division of labour as `authentication/services.py`.
"""

from __future__ import annotations

from authentication import phone as phone_utils
from authentication.errors import ApiError
from authentication.errors import ErrorCode as AuthErrorCode

from . import pricing
from .errors import ErrorCode
from .geo import haversine_km
from .models import Order, OrderStatus, PaymentMethod, TrackingStage

#: Bucket names as the client already knows them (`JhOrderBucket` on mobile).
_BUCKET_STATUS = {
    "active": OrderStatus.IN_TRANSIT,
    "completed": OrderStatus.COMPLETED,
    "cancelled": OrderStatus.CANCELLED,
}


def create_order(customer, data: dict) -> Order:
    if not data.get("declaration_accepted"):
        raise ApiError(
            ErrorCode.ORDER_DECLARATION_REQUIRED,
            "Please accept the package declaration.",
            details={"field": "declaration_accepted"},
        )

    vehicle = data["vehicle"]
    if not pricing.is_available(vehicle):
        raise ApiError(
            ErrorCode.ORDER_VEHICLE_UNAVAILABLE,
            "This vehicle is not available yet.",
            details={"field": "vehicle"},
        )

    recipient_digits = phone_utils.normalise(data["recipient_phone"])
    if not phone_utils.is_valid(recipient_digits):
        raise ApiError(
            AuthErrorCode.VALIDATION_FAILED,
            "Please enter a valid Tanzanian phone number for the recipient.",
            details={"field": "recipient_phone"},
        )

    distance_km = haversine_km(
        data["pickup_lat"], data["pickup_lng"], data["dropoff_lat"], data["dropoff_lng"]
    )
    price_tsh = pricing.price_for(vehicle, distance_km)

    return Order.objects.create(
        customer=customer,
        vehicle=vehicle,
        price_tsh=price_tsh,
        payment_method=data.get("payment_method", PaymentMethod.PAY_AFTER_DELIVERY),
        pickup_address=data["pickup_address"],
        pickup_landmark=data.get("pickup_landmark", ""),
        pickup_instructions=data.get("pickup_instructions", ""),
        pickup_lat=data["pickup_lat"],
        pickup_lng=data["pickup_lng"],
        dropoff_address=data["dropoff_address"],
        dropoff_landmark=data.get("dropoff_landmark", ""),
        dropoff_lat=data["dropoff_lat"],
        dropoff_lng=data["dropoff_lng"],
        delivery_instructions=data.get("delivery_instructions", ""),
        recipient_name=data["recipient_name"],
        recipient_phone=recipient_digits,
        package_type=data["package_type"],
        package_size=data["package_size"],
        quantity=data.get("quantity", 1),
        package_description=data.get("package_description", ""),
        handling_instructions=data.get("handling_instructions", ""),
        package_photo=data.get("package_photo"),
        declaration_accepted=True,
    )


def list_orders(customer, bucket: str | None = None):
    orders = Order.objects.filter(customer=customer)
    if bucket:
        status = _BUCKET_STATUS.get(bucket)
        if status is None:
            raise ApiError(
                AuthErrorCode.VALIDATION_FAILED,
                "Unknown bucket.",
                details={"field": "bucket"},
            )
        orders = orders.filter(status=status)
    return orders


def get_order(customer, order_id) -> Order:
    order = Order.objects.filter(customer=customer, id=order_id).first()
    if order is None:
        # 404, not 403: whether an id belongs to someone else is not
        # information this endpoint reveals.
        raise ApiError(
            ErrorCode.ORDER_NOT_FOUND, "Order not found.", http_status=404
        )
    return order


def cancel_order(customer, order_id) -> Order:
    order = get_order(customer, order_id)
    stage = TrackingStage(order.stage)
    if order.status != OrderStatus.IN_TRANSIT or (
        stage.index >= TrackingStage.PICKED_UP.index
    ):
        raise ApiError(
            ErrorCode.ORDER_CANCEL_NOT_ALLOWED,
            "This order can no longer be cancelled.",
            http_status=409,
        )
    order.status = OrderStatus.CANCELLED
    order.save(update_fields=["status", "updated_at"])
    return order


def rate_order(customer, order_id, stars: int) -> Order:
    order = get_order(customer, order_id)
    if order.status != OrderStatus.COMPLETED:
        raise ApiError(
            ErrorCode.ORDER_NOT_COMPLETED,
            "Only a completed delivery can be rated.",
            http_status=409,
        )
    order.my_rating = stars
    order.save(update_fields=["my_rating", "updated_at"])
    return order

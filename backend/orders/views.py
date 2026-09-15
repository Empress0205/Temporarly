"""HTTP layer. Thin, same division of labour as `authentication/views.py`:
each view validates its input, calls one service function and shapes the
response. No business rules here.
"""

from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from authentication.serializers import ErrorEnvelopeSerializer

from . import services
from .serializers import OrderCreateSerializer, OrderRatingSerializer, OrderSerializer

#: Every endpoint can fail this way; listed once rather than repeated per view.
ERRORS = {
    400: ErrorEnvelopeSerializer,
    401: ErrorEnvelopeSerializer,
    404: ErrorEnvelopeSerializer,
    409: ErrorEnvelopeSerializer,
}


def _validated(serializer_class, request):
    serializer = serializer_class(data=request.data)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


@extend_schema(
    summary="List the signed-in customer's orders",
    description="Optionally filtered by `?bucket=active|completed|cancelled`.",
    responses={200: OrderSerializer(many=True), **ERRORS},
)
class OrderListCreateView(APIView):
    def get(self, request):
        bucket = request.query_params.get("bucket")
        orders = services.list_orders(request.user, bucket)
        return Response(
            OrderSerializer(orders, many=True, context={"request": request}).data
        )

    @extend_schema(
        summary="Create an order",
        description=(
            "Price is computed server-side from the pickup/drop-off distance -- "
            "never trusted from the client. `multipart/form-data` when a "
            "package photo is attached, otherwise plain JSON."
        ),
        request=OrderCreateSerializer,
        responses={201: OrderSerializer, **ERRORS},
    )
    def post(self, request):
        data = _validated(OrderCreateSerializer, request)
        order = services.create_order(request.user, data)
        return Response(
            OrderSerializer(order, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


@extend_schema(
    summary="Order detail",
    responses={200: OrderSerializer, **ERRORS},
)
class OrderDetailView(APIView):
    def get(self, request, order_id):
        order = services.get_order(request.user, order_id)
        return Response(OrderSerializer(order, context={"request": request}).data)


@extend_schema(
    summary="Cancel an order",
    description=(
        "Only while the courier has not yet picked the package up -- "
        "ORDER_CANCEL_NOT_ALLOWED (409) afterwards."
    ),
    request=None,
    responses={200: OrderSerializer, **ERRORS},
)
class OrderCancelView(APIView):
    def post(self, request, order_id):
        order = services.cancel_order(request.user, order_id)
        return Response(OrderSerializer(order, context={"request": request}).data)


@extend_schema(
    summary="Rate a completed delivery",
    description="ORDER_NOT_COMPLETED (409) for any order that isn't COMPLETED yet.",
    request=OrderRatingSerializer,
    responses={200: OrderSerializer, **ERRORS},
)
class OrderRateView(APIView):
    def post(self, request, order_id):
        data = _validated(OrderRatingSerializer, request)
        order = services.rate_order(request.user, order_id, data["stars"])
        return Response(OrderSerializer(order, context={"request": request}).data)

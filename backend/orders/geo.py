"""Great-circle distance.

Deliberately kept parallel to `haversineKm` in
`mobile/lib/orders/order_models.dart` -- same formula, same shape, on both
sides of the wire, so a price computed here is never a mystery when compared
against what the app itself would have estimated.
"""

from __future__ import annotations

import math

_EARTH_RADIUS_KM = 6371.0


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lng / 2) ** 2
    )
    return _EARTH_RADIUS_KM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

"""Distance-based delivery pricing.

    price = max(ORDER_MIN_PRICE_TSH, round(distance_km * rate_per_km[vehicle]))

Both the floor and the per-km rates are settings (`config/settings.py`), never
constants here -- same reason the OTP policy lives in settings: this is a
number the client sets, not one a developer should have to redeploy to change.

`ORDER_RATE_PER_KM_TSH` currently holds placeholder figures. There is no real
per-km rate from the client yet; these were chosen only to preserve the same
*relative* pricing the mobile app's flat table already showed (a car costs
more per km than a motorcycle, roughly in the ratio of the old 5000/8000/15000
figures). Replace them in `.env` the moment real numbers exist -- nothing else
needs to change.
"""

from __future__ import annotations

from django.conf import settings


def price_for(vehicle: str, distance_km: float) -> int:
    rate = settings.ORDER_RATE_PER_KM_TSH[vehicle]
    return max(settings.ORDER_MIN_PRICE_TSH, round(distance_km * rate))


def is_available(vehicle: str) -> bool:
    """All four vehicle types (motorcycle, bajaji, car, lorry) now have fleet
    cover -- mirrors `JhVehicle.available` on the mobile side, which is also
    unconditionally true. Kept as a function rather than inlined `True` so a
    future type still without coverage has somewhere to gate on."""
    return True

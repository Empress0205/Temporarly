# Jihudumie Logistics — Customer Platform

**Customer authentication, plus an Orders module.** The mobile app's Orders
screens shipped first against local sample data; the backend and the wiring
between the two came after, and the app now creates, lists, cancels and rates
real orders against it.

Two deployables, one repository:

| Directory | What it is | Stack |
| --- | --- | --- |
| [mobile/](mobile/) | Customer mobile app | Flutter (Android, iOS, web) |
| [backend/](backend/) | Authentication + Orders API | Django REST Framework, PostgreSQL |

Each has its own README covering how to run it and the decisions behind it.

## Getting both running

```bash
# API — Postgres in Docker, then migrate and serve on :8000
cd backend
docker compose up -d
.venv/Scripts/python manage.py migrate
.venv/Scripts/python manage.py runserver

# App — in a second terminal
cd mobile
flutter run
```

The API's development SMS provider prints the verification code to the console
instead of sending it, so the whole flow works without a provider or
credentials.

## Tests

```bash
cd backend && .venv/Scripts/python manage.py test authentication orders   # 78
cd mobile  && flutter test                                         # 103 (+1 skipped)
```

The mobile suite's live-wiring test, `test/live_wiring_test.dart`, is tagged `live`
and skipped by default — it opens a real socket to a running backend rather
than using a fake, and is how the wiring between the two codebases actually
gets proven rather than assumed. Run it with the backend up:

```bash
cd mobile && flutter test test/live_wiring_test.dart --run-skipped \
  --dart-define=JH_API_BASE_URL=http://127.0.0.1:8000
```

## The seam between them

The app is wired to the real API (`mobile/lib/api/`, `mobile/lib/orders/`) —
there are no fixtures left. Several things span both sides and must stay in
step:

**Phone normalisation.** `mobile/lib/state/app_state.dart` (`digitsOf`) and
`backend/authentication/phone.py` (`normalise`) must agree exactly. If they
drift, one person typing `0712…` and `+255712…` becomes two accounts. The same
table of cases is asserted on each side —
`mobile/test/phone_normalisation_test.dart` and
`backend/authentication/tests/test_phone.py`.

**Error codes.** The API returns `error.code`; the app branches on it and
renders its own English and Swahili copy. The `message` field is for logs, not
for display. The codes are listed in `backend/authentication/errors.py` and
`backend/orders/errors.py`, and described in `backend/openapi.yaml`.

**OTP policy.** Code length, validity, attempt limit and resend cooldown are
server configuration (spec §43), returned by the request-OTP endpoints. The
app's `JhOtpConfig` exists to receive them rather than to define them.

**Orders enum values and field names.** `mobile/lib/orders/order_models.dart`'s
enums (`JhOrderStatus`, `JhTrackingStage`, `JhVehicle`, `JhPackageType`,
`JhPackageSize`, `JhPaymentMethod`) send/parse the exact UPPER_SNAKE strings
`backend/orders/models.py` defines, and `JhOrder`'s field names match
`OrderCreateSerializer`/`OrderSerializer` one for one — including
`deliveryInstructions`/`delivery_instructions` naming the drop-off note
specifically, not the recipient step's (a mismatch the mobile app itself hit
and fixed before the backend existed).

**Pricing.** The backend computes `price = max(ORDER_MIN_PRICE_TSH,
distance_km × rate[vehicle])` and the app never recomputes or second-guesses
it — whatever `price_tsh` comes back on an order is what's shown, full stop.

**Vehicle types.** Both sides offer the same four — motorcycle, bajaji, car,
lorry (`VAN` on the wire) — matching the driver app being built alongside
this one; all four are bookable on both sides now.

**Brand palette.** The client fixed the visual identity: Primary Orange
`#F7941D`, Charcoal `#2D2D2D`, Operations Green `#2D8B4E`, Warm Accent
`#FDB95B`, matching the driver app's own look. It lives at the token level in
`mobile/lib/theme/tokens.dart` (see that file's role comments) — nothing
downstream inlines a colour literal, so this is the one place a further brand
change would happen.

## Specification

The source of truth is `sprint1-requirements.txt` in the design handoff.
Section numbers referenced throughout both codebases point at it.

# Jihudumie — Backend

Django REST Framework backend for the Jihudumie customer app. Three modules so
far: **Authentication** (specification §29–§30, §8–§13, §20–§25, §32–§37),
**Orders** — a distance-priced delivery request API, built after the mobile
app's Orders module had already shipped against local sample data — and
**Places**, a thin proxy in front of Google's Places API (New) and Geocoding
API for address search.

## Running

```bash
docker compose up -d                      # Postgres 16 on :5432
.venv/Scripts/python manage.py migrate
.venv/Scripts/python manage.py runserver
.venv/Scripts/python manage.py test       # 96 tests
```

Interactive contract at `/api/docs`, machine-readable at `/api/schema`
(checked in as `openapi.yaml`).

In development `SMS_PROVIDER=logging` prints the code to the console instead of
sending it, so every flow is exercisable with no provider and no credentials.
Real delivery (`SMS_PROVIDER=webline`) is configured and has been used for live
testing — `logging` is simply what's active in `.env` while OTP-gated flows are
being tested repeatedly, to avoid spending SMS credit on every run. Flip it back
before testing anything that depends on a real code actually arriving.

`GOOGLE_PLACES_API_KEY` must be set for the `places` endpoints to work; without
it they fail with `PLACES_LOOKUP_FAILED` (503) rather than crash. The key is
never sent to the mobile app — see "Places decisions worth knowing" below.

## Layout

| File | Contents |
| --- | --- |
| `config/settings.py` | Every §43 parameter, read from the environment |
| `authentication/phone.py` | Canonical normalisation. **Mirrors `JhAppState.digitsOf` in the Flutter app** |
| `authentication/models.py` | `Customer`, `OtpRequest` |
| `authentication/otp.py` | Issue, resend, verify. All OTP rules live here |
| `authentication/services.py` | The five journeys |
| `authentication/errors.py` | Error codes and the one response envelope |
| `authentication/sms.py` | Provider interface; logging and memory implementations |
| `authentication/throttling.py` | Per-IP limits (per-phone limits are in `otp.py`) |
| `authentication/logging.py` | Redacts codes and phone numbers from logs |
| `orders/models.py` | `Order`, `Driver`. Enums mirror the Dart ones in `mobile/lib/orders/order_models.dart` value-for-value |
| `orders/pricing.py` | `price = max(ORDER_MIN_PRICE_TSH, distance_km * rate[vehicle])` |
| `orders/geo.py` | Haversine distance — kept parallel to `haversineKm` in the Flutter app |
| `orders/services.py` | Create/list/cancel/rate, same thin-view/fat-service split as `authentication` |
| `orders/admin.py` | Where driver assignment and stage/status actually happen right now (see below) |
| `places/google_places.py` | The Google HTTP client — autocomplete, place details, reverse-geocode |
| `places/services.py` | Translates `PlacesLookupError` into the one response envelope, same pattern as `authentication.sms.send_otp` |
| `places/views.py` | `/api/places/autocomplete`, `/details`, `/reverse-geocode` — all auth-required |

## Decisions worth knowing

**Identity is the phone number.** `AUTH_USER_MODEL` is a custom `Customer`
with no usable password — passwords are not in the MVP (§37). This had to be
set before the first migration; changing it later is painful.

**One canonical phone format.** Nine digits, no country code, no leading zero.
`+255712345678`, `0712345678`, `00255712345678` and `712345678` are the same
number, and the unique index is built on that form. If this ever disagrees with
the app's normalisation, one person typing their number two ways becomes two
accounts — so the same table of cases is asserted on both sides, here in
`authentication/tests/test_phone.py` and in the app's
`mobile/test/phone_normalisation_test.dart`.

**The profile arrives at verification, not before.** `register/request-otp`
takes only the phone; name and email come with `register/verify-otp`, which
creates the account in one step. An abandoned registration therefore leaves
nothing behind but an expiring OTP row. (The specification did not settle this;
§31's schema has nowhere to park an unverified profile.)

**Codes are never stored.** `otp_hash` is an HMAC-SHA256 of the code with a
server-side pepper, bound to the phone number *and* the purpose — so a
registration code is inert against the login endpoint even if the digits match.
Six digits is a small space, so what actually protects it is the attempt limit
and the rate limits, not the hash.

**Attempts are committed before the error is raised.** `otp.verify` records the
attempt in its own transaction and returns an outcome, which the caller then
turns into an error. Raising from inside the transaction would roll back the
counter increment, so a wrong code would cost nothing and the three-attempt
lockout would never fire. For the same reason callers must not wrap `verify` in
an outer atomic block. There is a test for this.

**Uniqueness is settled by the database.** Two devices registering the same
number at the same moment both pass a check-then-insert, so the unique index is
the arbiter and `IntegrityError` is translated to `PHONE_ALREADY_REGISTERED`.

**Phone-change ownership is re-checked at verification.** The number can be
claimed by someone else while the code is in flight.

**Errors are codes, not prose.** The app branches on `error.code` and renders
its own English and Swahili copy; `message` is for logs. `OTP_INCORRECT`
carries `attempts_remaining`, rate limits carry `retry_after_seconds`.

**Timings come from the server.** `request-otp` returns `expires_in`,
`resend_available_in`, `otp_length` and `max_attempts`, so §43's parameters are
configuration rather than constants duplicated in the client.

**Revocation despite JWT.** Access tokens are short (15 min) and refresh tokens
are stored, rotated and blacklisted, which is what makes logout (§22) and
cross-device sign-out on a phone change (§25) real. A stateless JWT alone
cannot be withdrawn. Note the consequence: after logout the access token stays
valid until it expires. Its lifetime is the size of that window.

## Orders decisions worth knowing

**Driver assignment and stage progression are manual, on purpose.** There is
no driver app yet — a separate project, in progress elsewhere — to self-assign
or report its own status, so `orders/admin.py` makes both a couple of clicks
from the `/admin/` order list (`driver`, `status`, `stage` are `list_editable`)
rather than building assignment logic that would just be thrown away once the
driver app exists.

**Price is computed server-side and stored, never trusted from the client.**
`price = max(ORDER_MIN_PRICE_TSH, distance_km * ORDER_RATE_PER_KM_TSH[vehicle])`,
snapshotted onto the order at creation so a later rate-table change can't
rewrite what a customer already agreed to pay. **The per-km rates are
placeholders** (`.env.example`'s `ORDER_RATE_PER_KM_*_TSH`) — there is no real
figure from the client yet; they only preserve the ratio the mobile app's old
flat table implied. The 2,000 TSh minimum is the client's real number.

**Four vehicle types, all available.** `Vehicle` is `MOTORCYCLE`, `BAJAJI`,
`CAR`, `VAN` (shown to the customer as "Lorry") — matching the driver app's
own four options. `pricing.is_available` returns `True` unconditionally now
(it used to reject `VAN`); it stays a function rather than an inlined
constant so a future type still without fleet cover has somewhere to gate on,
and `ORDER_VEHICLE_UNAVAILABLE` stays a real error code for that day.

**Cancel is gated on `stage`, not `status`.** Once a courier has picked the
package up (`stage >= PICKED_UP`), cancelling 409s with
`ORDER_CANCEL_NOT_ALLOWED` — the same rule the mobile app enforces locally
today, now the server-enforced version of it.

**Package photos are local disk, dev only.** `MEDIA_ROOT`/`MEDIA_URL`, served
by Django itself while `DEBUG=True`. Production needs real object storage
(S3 or similar) and a real web server in front of it before launch.

**`Driver.rating` is admin-set, not computed.** `Order.my_rating` exists per
order, but nothing averages it back onto the driver yet — a reasonable
follow-up once there's real rating volume, not built pre-emptively here.

## Places decisions worth knowing

**The API key never reaches the mobile app.** It lives in this backend's
`.env` only; the app calls our own `/api/places/*` endpoints, which call
Google. This also means every call is already behind the app's own JWT auth,
so an unauthenticated caller can't run up the Google bill.

**Session tokens are generated client-side, not here.** Google bills
autocomplete + the details call that follows it as one session when they
share a token — the backend just passes whatever token the app sends straight
through to Google. See `mobile/lib/orders/google_places_location_service.dart`.

**The resolved address prefers the autocomplete suggestion's own label over
Google's `formattedAddress`.** The latter can fall back to a Plus Code
(`"65QP+CG9, Dar es Salaam"`) for a point with no conventional street
address — a real Google answer, but a worse one than the name the customer
actually read and picked. That preference lives on the mobile side, not here;
this backend still returns `formattedAddress` as `address`, since reverse-geocode
(dragging the map pin) has no suggestion label to prefer and genuinely needs it.

**Not yet switched: map tiles.** The map itself still renders free
OpenStreetMap tiles (`flutter_map`); only address search is Google-backed. A
full switch to Google Maps tiles would add a second, separate billing
category (per map load) and a larger mobile-side rewrite — deliberately not
done, see the mobile README.

## Accepted risk

§15 and §19 require the API to say whether a number is registered, which is
account enumeration by design. Per-IP throttling limits bulk harvesting, but
the behaviour is mandated by the specification and should be recorded as a
known trade-off rather than discovered in a security review.

## Still to do

- Flip `SMS_PROVIDER` back to `webline` (credentials are already configured
  in `.env`) before testing anything that depends on a real code arriving —
  it's set to `logging` right now to avoid spending SMS credit while
  OTP-gated flows are being tested repeatedly.
- Reported SMS delivery delay on the live Webline account, cause not yet
  confirmed (carrier/gateway-side, most likely) — nothing to fix here until
  there's more information from Webline.
- Schedule `otp.purge_expired`.
- Production settings: `DEBUG=False`, real `SECRET_KEY` and `OTP_PEPPER`,
  HTTPS, a shared cache so throttling holds across processes.
- Real per-km pricing figures from the client, replacing the placeholder
  `ORDER_RATE_PER_KM_*_TSH` values.
- Real object storage for package photos before launch (currently local disk).
- A driver app to replace manual admin assignment/stage-progression, and the
  live-location feed that unlocks real-time tracking on the mobile side.

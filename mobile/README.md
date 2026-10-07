# Jihudumie — Customer Mobile App

Flutter implementation of **Sprint 1: Authentication** for the Jihudumie
logistics platform.

The flows come from `design_handoff_sprint1_auth`. The visual language has
moved twice since: a second-pass direction (illustrated mint welcome, flat
green headers) agreed after that handoff, and now the client's own brand —
Primary Orange, Charcoal, Operations Green and a Warm Accent, matching the
driver app being built alongside this one. A photographic (placeholder, for
now) rotating hero replaces the illustration, headers are flat charcoal
instead of green, and orange carries every brand/action moment; green is kept
strictly for genuine success states (a delivery marked Completed). All three
are described below, because none of them agree with each other.

Scope is the screens and the flows between them. The app talks to the real
authentication API in `../backend` — see [Talking to the backend](#talking-to-the-backend)
below for how the two are wired.

## Running

```bash
# the backend, first (see ../backend/README.md)
cd ../backend && docker compose up -d && python manage.py runserver

# then the app, pointed at it
cd mobile
flutter run --dart-define=JH_API_BASE_URL=http://127.0.0.1:8000   # a physical device
flutter run                                                        # emulator/simulator/web: picks the right localhost automatically
flutter test                                # 103 flow + unit + golden tests
flutter test --update-goldens test/golden_test.dart   # after a visual change
```

Targets: Android, iOS, web. The app is locked to portrait ([lib/main.dart](lib/main.dart)) —
there is no landscape design, and sideways the header alone is taller than the
screen. On web and desktop, windows wider than 460px centre the app at phone
width rather than stretching it.

## Layout of the code

| Path | What lives there |
| --- | --- |
| `lib/theme/tokens.dart` | Colours, radii, shadows, type ramp, motion. Screens reference these; none inline literals. |
| `lib/theme/icons.dart` | Every icon, named for meaning rather than appearance. Swapping icon sets is an edit to this one file. |
| `lib/l10n/dict.dart` | English and Swahili copy. A class rather than a map, so the analyser enforces that both languages carry identical keys. |
| `lib/state/app_state.dart` | The whole state machine: screens, tabs, form fields, errors, OTP lifecycle, session, Orders. |
| `lib/widgets/` | Shared pieces — headers, buttons, fields, OTP input, tab bar, toast, hero illustration, scaffolds. |
| `lib/screens/` | One file per screen. |
| `lib/app.dart` | Renders the screen the machine is on, plus the floating chrome. |
| `lib/api/api_client.dart` | `JhApiClient` — the transport every module shares: bearer header, refresh-on-401, timeouts, the error envelope. |
| `lib/orders/order_models.dart` | `JhOrder`/`JhOrderDraft`/enums, mirroring `backend/orders/models.py` value-for-value. |
| `lib/orders/orders_api.dart` | `JhOrdersApi`/`JhHttpOrdersApi` — create/list/cancel/rate against the real backend. |
| `lib/widgets/jh_hero_carousel.dart` | The Welcome screen's rotating hero — painted placeholder scenes crossfading on a timer, standing in for the client's real photography. |

Navigation is the handoff's `screen` value rather than Flutter's `Navigator`,
because the flows are not a stack: the OTP screen returns to whichever of three
screens sent the user there, and a successful verification replaces the history
rather than pushing onto it. Android's back gesture maps onto the same `back()`
the header button calls.

State is one `ChangeNotifier` behind an `InheritedNotifier` (`JhScope`). The
module has a single state object and no async data, so there is nothing a state
management package would do better here.

## Screens

| Screen | Notes |
| --- | --- |
| Splash | Session check (spec §34). Gradient field, stacked lockup. |
| Welcome | Full-bleed rotating hero (`JhHeroCarousel`, placeholder scenes) with a location badge, a region pill and the four vehicle types overlaid, then a white sheet: headline, Log in, Create account, and the legal line. |
| Register | Single page — name, email and phone together. |
| Login | Phone only, no password. |
| OTP | Shared by registration, login and phone change. |
| Home | Greeting and search in the header; quick actions and recent orders below. |
| Shop | Sprint 2. A real screen stating what is not built yet, rather than a tab that only raises a toast. |
| Orders | My Orders (Active / Completed / Cancelled) plus the five-step Send a Package wizard (Route — pickup then drop-off in one step — then Recipient, Package, Delivery mode, Review), an order-created confirmation, and a Track Package screen. **Wired to the real backend** (`../backend`'s `orders` app, via `lib/orders/orders_api.dart`) — My Orders fetches the signed-in customer's actual orders on every visit (a spinner while it's in flight), and create/cancel/rate are genuine round trips: price is computed server-side from distance, cancel 409s once a courier has picked up, and a failure of any of the three leaves the screen exactly as it was and flashes a toast rather than pretending it worked. Both halves of the Route step are search-first: type an address and get ranked suggestions as you type, the same way for pickup as for drop-off — "Use Current Location" and dragging the pin are shortcuts on the same screen, not a separate gated flow. Search, place resolution and reverse-geocoding (dragging the pin) are all Google-Places-backed, proxied through `../backend`'s `places` app (`lib/orders/google_places_location_service.dart`) — the API key never ships to the app. The map *tiles* themselves are unchanged: still free OpenStreetMap (`flutter_map`), only address search moved to Google; a fuller switch to Google Maps tiles too is a deliberately separate, bigger decision (see the backend README). The Route step also offers up to 5 recent pickup/drop-off points (remembered from past orders, client-side only) so a repeat sender can tap instead of retyping. The Package step can attach a photo of the parcel (`image_picker`, uploaded as part of creation), shown on Review (as bytes, before it exists) and on Track Package (as the server's URL, once it does). The Pickup and Destination steps use device location (`geolocator`) for "Use Current Location"; tests and goldens swap the live map in for a placeholder via `state.liveMap = false`. **Known gap:** Track Package's stage rail/timeline reflects whatever `stage` the order was fetched with, not a moving position — real live tracking (a driver icon moving on the map in real time, like Bolt) needs a driver-side location feed and a real-time push channel that don't exist yet, so it stays parked until that backend/driver-app work starts. |
| Account | Identity, full name / phone / member-since, and settings grouped as Account settings, Support, Session. Rows Sprint 1 doesn't build (email, notifications, help, privacy) acknowledge the tap via a toast rather than doing nothing. |
| Logout sheet | Confirmation before the session is cleared. |
| Delete account sheet | Confirmation UI only — there is no delete-account endpoint yet, so confirming acknowledges the request rather than performing it. |

## Where this departs from the handoff

The handoff declared its design final, so every difference below is a
deliberate consequence of the second-pass mockups, not drift:

- **Welcome is rebuilt.** The "Deliveries across Tanzania" headline and the
  three value lines are gone, replaced by the illustrated hero, "Your services,
  delivered.", and the legal line. Log in now leads; Create account is second.
- **Home is rebuilt.** The send-a-parcel hero card, active-delivery card and
  recent-deliveries list are replaced by quick actions and an empty
  recent-orders state. Nothing on Home invents data any more.
- **Four tabs, not three.** Home, Shop, Orders, Account. Profile became Account.
- **Headers are flat.** The 158° gradient and the two decorative circles remain
  only on the splash screen; everywhere else the band is a single flat field
  — charcoal now, not green, per the client's brand palette.
- **The Welcome and auth headers no longer match.** Welcome's header sits over
  the photographic hero (dark badges); Register/Login/OTP/Change phone now use
  a plain white header (`JhAuthHeader`) with dark text and a small brand
  lockup, matching the driver app's own Register screen — not the filled
  colour band the second pass used.
- **Flatter controls.** 12px radii, hairline card borders, no coloured lift
  under buttons, no inner shadow on fields.
- **Button copy is the handoff's.** The mockups read "Login" and "Create
  Account"; the app keeps "Log in" and "Create account", which differ only in
  case and are the handoff's final copy. Say the word and it is a two-string
  change.
- **The hero is drawn, not an asset.** [lib/widgets/jh_hero_carousel.dart](lib/widgets/jh_hero_carousel.dart)
  paints a small set of captioned scenes and crossfades between them on a
  timer, so it needs no files, recolours with the tokens, and never depends on
  a network fetch. It is explicitly a placeholder for the client's real
  photography — swapping that in is a change to this one file.
- **Four vehicle types, not three.** Motorcycle, Bajaji, Car and Lorry (`VAN`
  on the wire, relabelled) — matching the driver app; all four are bookable,
  none is disabled the way `VAN` used to be.
- **Icons are Material Icons**, mapped through `JhIcons`. No emoji anywhere.
- **A language toggle was added** (the `SW`/`EN` pill in each header). The
  prototype took its language from the review harness, which is not ported.
  Switching rebuilds copy only — screen and form values survive it.
- **Safe areas.** The design's paddings were drawn at 402×874 with the status
  bar included; where a device reports a deeper inset, the header grows.

The Swahili for all new copy is mine and should be reviewed by a native speaker
before release. Everything carried over from the handoff is its original
wording.

## Talking to the backend

The app is wired to the real API — there are no fixtures left. `lib/api/`
holds the client:

| File | Contents |
| --- | --- |
| `api_config.dart` | Base URL per platform (an Android emulator's `10.0.2.2` is not `localhost`), overridable with `--dart-define=JH_API_BASE_URL=...` |
| `api_models.dart` | Response shapes, and `JhErrorCode` — the same codes as `backend/authentication/errors.py` **and** `backend/orders/errors.py`, kept as strings rather than an enum so an unrecognised code from a newer server degrades instead of crashing |
| `token_store.dart` | Session credentials in the platform keystore (`flutter_secure_storage`), per spec §37 |
| `api_client.dart` | `JhApiClient` — the shared transport: bearer header, one retry through a token refresh on a 401, request timeouts, `multipart/form-data` support (Orders' package photo), and turning every failure into a `JhApiException`. Nothing here is authentication-specific; it's just where it was built first. |
| `auth_api.dart` | `JhHttpAuthApi` — the nine auth calls, a thin wrapper over `JhApiClient` |
| `../orders/orders_api.dart` | `JhHttpOrdersApi` — create/list/cancel/rate, the same way |

Both `JhHttpAuthApi` and `JhHttpOrdersApi` talk to the same server with the
same JWT; a customer's Orders requests are authenticated exactly like their
auth ones, no separate login step.

`JhAppState` no longer decides any authentication rule — it renders whatever
the server said. `_applyError` is the one place that turns a `JhErrorCode`
into the copy and screen state a customer sees, and `TOKEN_EXPIRED` /
`TOKEN_INVALID` there end the session and return to Welcome rather than
leaving an authenticated-looking screen behind (spec §35).

`JhOtpConfig` no longer holds constants — `JhOtpConfig.fromChallenge` builds it
from the server's response to each `request-otp` call, since spec §43 requires
those values to be backend configuration.

## Tests

`test/auth_flow_test.dart` drives the state machine against `FakeAuthApi`
(`test/support/`), scripted per test to return what the server would for that
case — covering the spec §40 acceptance criteria: registration creating an
account only after verification, a taken number offering login, an unknown
number refusing to auto-register, an exhausted attempt count locking the
input, code expiry, phone change leaving the stored number untouched until it
verifies, logout clearing the session even when the server call fails, a
network failure preserving what was typed, a rejected token ending the
session mid-flow, and duplicate submissions being blocked while one is in
flight.

`test/orders_flow_test.dart` does the same for Orders, against
`FakeOrdersApi` (`test/support/`) — including three tests that deliberately
script a server failure (a bad create, a bad cancel, a load that comes back
empty-handed) and check the screen is left exactly as it was, not silently
broken.

`test/live_wiring_test.dart` is different: it points the **real**
`JhHttpAuthApi`/`JhHttpOrdersApi` at a running backend — sharing one token
store, the way `JhAppState` does — and reads the verification code out of
the server's own log, so it proves the two codebases actually agree on the
wire format — JSON shapes, error envelope, header names — rather than on
what a test double assumes they do. It registers a customer, then creates,
lists and cancels a real order against the live database. Tagged `live` and
skipped by default (`dart_test.yaml`) so `flutter test` never opens a socket;
run it deliberately:

```bash
# terminal 1
cd ../backend && docker compose up -d && python manage.py runserver

# terminal 2, with SMS_PROVIDER=logging in backend/.env
cd mobile
flutter test test/live_wiring_test.dart --run-skipped \
  --dart-define=JH_API_BASE_URL=http://127.0.0.1:8000
```

`test/golden_test.dart` renders thirty screen states to `test/goldens/`
against `FakeAuthApi` with `checkSessionOnStart: false`, so a golden shows a
fixed, chosen state rather than whatever a real session check returns. It
registers the bundled text fonts **and the Material icon font** by hand —
without that the test binding substitutes placeholders and every icon would
render as an empty box, hiding exactly the regressions the goldens exist to
catch.

## Not in this sprint

Search, the quick actions, the two legal documents, and the Shop tab are
still unbuilt — each acknowledges the tap rather than failing silently.
Orders is built and wired to the real backend (above); what it still doesn't
do (live tracking, chiefly) is called out on its own row in
[Screens](#screens).

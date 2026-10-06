@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jihudumie_app/app.dart';
import 'package:jihudumie_app/l10n/dict.dart';
import 'package:jihudumie_app/orders/location_service.dart';
import 'package:jihudumie_app/orders/order_models.dart';
import 'package:jihudumie_app/state/app_state.dart';

import 'support/fake_auth_api.dart';
import 'support/sample_orders.dart';

// A real, decodable 1x1 PNG -- `Image.memory` decodes whatever it's given.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY'
  '42YAAAAASUVORK5CYII=',
);

/// Renders every screen at the iOS artboard size so layout regressions show up
/// as an image diff rather than as a bug report.
///
/// Regenerate with `flutter test --update-goldens test/golden_test.dart`.
/// The bundled fonts have to be registered by hand: the test binding ships a
/// placeholder font, and without this the goldens would say nothing about how
/// the type actually sets.
Future<void> loadBundledFonts() async {
  const families = {
    'Manrope': [
      'Manrope_400Regular',
      'Manrope_500Medium',
      'Manrope_600SemiBold',
      'Manrope_700Bold',
      'Manrope_800ExtraBold',
    ],
    'JetBrainsMono': ['JetBrainsMono_500Medium', 'JetBrainsMono_700Bold'],
  };

  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final name in files) {
      final bytes = await File('assets/fonts/$name.ttf').readAsBytes();
      loader.addFont(
        Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
      );
    }
    await loader.load();
  }

  await _loadMaterialIcons();
}

/// Registers the Material icon font from the SDK cache.
///
/// The test binding does not bundle it, so without this every icon renders as
/// an empty box and the goldens would quietly hide missing or wrong glyphs.
/// The app itself always has the font, so this is a test-only gap.
Future<void> _loadMaterialIcons() async {
  // The Dart running the tests lives somewhere under the Flutter cache, but at
  // a depth that varies by platform and channel. Walking up until the fonts
  // directory appears is steadier than counting parents.
  const relative = 'artifacts/material_fonts/materialicons-regular.otf';
  File? font;
  for (
    var dir = File(Platform.resolvedExecutable).parent;
    dir.parent.path != dir.path;
    dir = dir.parent
  ) {
    final candidate = File('${dir.path}/$relative');
    if (candidate.existsSync()) {
      font = candidate;
      break;
    }
  }
  if (font == null) {
    // ignore: avoid_print
    print('MaterialIcons font not found; icons will be blank in goldens.');
    return;
  }
  final bytes = await font.readAsBytes();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer))))
      .load();
}

void main() {
  setUpAll(loadBundledFonts);

  /// Pumps the app with [prepare] applied to the machine's initial state.
  Future<void> capture(
    WidgetTester tester,
    String name,
    void Function(JhAppState state) prepare, {
    double scrollBy = 0,
  }) async {
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // A fake API and no start-up session check: these render fixed states,
    // and a real client would reach for the platform keystore.
    final state = JhAppState(
      api: FakeAuthApi(),
      checkSessionOnStart: false,
    );
    prepare(state);
    await tester.pumpWidget(JihudumieApp(state: state));
    // One frame past any entry animation, but short of the splash handover.
    await tester.pump(const Duration(milliseconds: 400));

    // Some screens carry more than fits one frame; a few goldens scroll down
    // first so the part they exist to show isn't cut off by the fold.
    if (scrollBy != 0) {
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        Offset(0, -scrollBy),
      );
      // A drag release can leave the scrollable with residual velocity, and
      // one pump can land mid-fling -- part of the content still animating
      // toward its resting position renders in the wrong place for that one
      // frame (visible as a stray line bleeding above the tracking sheet, for
      // instance). A few more pumps drain that animation before the capture.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
    }

    // The package-photo goldens decode a real PNG (`Image.memory`); that
    // decode needs genuine asynchronous work the FakeAsync test zone won't
    // resolve on its own, so it's pre-warmed here via `runAsync` before every
    // capture. Harmless (a fast no-op) for goldens that never use the image.
    await tester.runAsync(
      () => precacheImage(
        MemoryImage(tinyPng),
        tester.element(find.byType(JihudumieApp)),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(JihudumieApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  /// The dashboard greeting changes with the hour, so the goldens pin the
  /// clock. Without this the images regenerate differently before and after
  /// midday and the suite fails purely on when it happened to run.
  DateTime pinnedClock() => DateTime(2026, 9, 9, 9, 41);

  const customer = JhUser(
    name: 'Amina Hassan',
    email: 'amina.hassan@gmail.com',
    phone: '712345678',
  );

  testWidgets('splash', (t) => capture(t, 'splash', (s) {}));

  testWidgets(
    'welcome',
    (t) => capture(t, 'welcome', (s) => s.screen = JhScreen.welcome),
  );

  testWidgets(
    'register',
    (t) => capture(t, 'register', (s) {
      s
        ..screen = JhScreen.register
        ..mode = JhMode.register
        ..name = 'Grace Mushi'
        ..email = 'grace@example.com'
        ..phone = '712000111';
    }),
  );

  testWidgets(
    'register_error',
    (t) => capture(t, 'register_error', (s) {
      s
        ..screen = JhScreen.register
        ..mode = JhMode.register
        ..name = 'G'
        ..nameErr = s.t.errName
        ..email = 'grace@'
        ..emailErr = s.t.errEmail
        ..phone = '712345678'
        ..err = s.t.errTaken
        ..errKind = JhErrKind.toLogin;
    }),
  );

  testWidgets(
    'login',
    (t) => capture(t, 'login', (s) {
      s
        ..screen = JhScreen.phone
        ..mode = JhMode.login
        ..phone = '712345678';
    }),
  );

  testWidgets(
    'otp',
    (t) => capture(t, 'otp', (s) {
      s
        ..screen = JhScreen.otp
        ..mode = JhMode.login
        ..phone = '712345678'
        ..otp = '1234'
        ..ttl = 74
        ..cooldown = 14;
    }),
  );

  testWidgets(
    'otp_error',
    (t) => capture(t, 'otp_error', (s) {
      s
        ..screen = JhScreen.otp
        ..mode = JhMode.login
        ..phone = '712345678'
        ..ttl = 0
        ..cooldown = 0
        ..attempts = 3
        ..blocked = true
        ..err = s.t.errAttempts;
    }),
  );

  testWidgets(
    'home',
    (t) => capture(t, 'home', (s) {
      s
        ..screen = JhScreen.home
        ..tab = JhTab.home
        ..clock = pinnedClock
        ..user = customer;
    }),
  );

  testWidgets(
    'profile',
    (t) => capture(t, 'profile', (s) {
      s
        ..screen = JhScreen.profile
        ..tab = JhTab.account
        ..user = customer;
    }),
  );

  testWidgets(
    'change_phone',
    (t) => capture(t, 'change_phone', (s) {
      s
        ..screen = JhScreen.changePhone
        ..mode = JhMode.change
        ..user = customer
        ..phone = '754111222';
    }),
  );

  testWidgets(
    'logout_sheet',
    (t) => capture(t, 'logout_sheet', (s) {
      s
        ..screen = JhScreen.profile
        ..tab = JhTab.account
        ..user = customer
        ..logoutOpen = true;
    }),
  );

  testWidgets(
    'delete_account_sheet',
    (t) => capture(t, 'delete_account_sheet', (s) {
      s
        ..screen = JhScreen.profile
        ..tab = JhTab.account
        ..user = customer
        ..deleteAccountOpen = true;
    }),
  );

  testWidgets(
    'shop_tab',
    (t) => capture(t, 'shop_tab', (s) {
      s
        ..screen = JhScreen.shop
        ..tab = JhTab.shop
        ..user = customer;
    }),
  );

  testWidgets(
    'home_swahili_with_toast',
    (t) => capture(t, 'home_swahili_with_toast', (s) {
      s
        ..screen = JhScreen.home
        ..tab = JhTab.home
        ..clock = pinnedClock
        ..user = customer
        ..lang = JhLang.sw
        ..toast = JhStrings.sw.toastWelcome;
    }),
  );

  // --- Sprint 2: Orders. `liveMap = false` swaps the real flutter_map tile
  // layer for a deterministic placeholder, the same idea as pinning `clock`.

  void onOrders(JhAppState s) => s
    ..screen = JhScreen.orders
    ..tab = JhTab.orders
    ..clock = pinnedClock
    ..liveMap = false
    ..user = customer
    ..orders.addAll(buildSampleOrders());

  testWidgets(
    'my_orders_active',
    (t) => capture(t, 'my_orders_active', onOrders),
  );

  testWidgets(
    'my_orders_completed',
    (t) => capture(t, 'my_orders_completed', (s) {
      onOrders(s);
      s.ordersBucket = JhOrderBucket.completed;
    }),
  );

  testWidgets(
    'my_orders_empty',
    (t) => capture(t, 'my_orders_empty', (s) {
      onOrders(s);
      s.orders.clear();
    }),
  );

  testWidgets(
    'my_orders_swahili',
    (t) => capture(t, 'my_orders_swahili', (s) {
      onOrders(s);
      s.lang = JhLang.sw;
    }),
  );

  testWidgets(
    'new_order_pickup_with_recents',
    (t) => capture(t, 'new_order_pickup_with_recents', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 1
        ..pickupMode = JhPickupMode.manual
        ..recentPlaces.addAll(const [
          JhPlace(lat: -6.77, lng: 39.22, address: 'Makongo, Dar es Salaam'),
          JhPlace(lat: -6.70, lng: 39.20, address: 'Goba, Dar es Salaam'),
        ]);
    }),
  );

  testWidgets(
    'new_order_pickup_filled',
    (t) => capture(t, 'new_order_pickup_filled', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 1
        ..pickupMode = JhPickupMode.manual;
      s.draft
        ..pickupLat = -6.7723
        ..pickupLng = 39.2199
        ..pickupAddress = 'Makongo Juu, Dar es Salaam';
    }),
  );

  testWidgets(
    'new_order_pickup_manual',
    (t) => capture(t, 'new_order_pickup_manual', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 1
        ..pickupMode = JhPickupMode.manual;
    }),
  );

  testWidgets(
    'new_order_recipient',
    (t) => capture(t, 'new_order_recipient', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 2;
    }),
  );

  testWidgets(
    'new_order_recipient_error',
    (t) => capture(t, 'new_order_recipient_error', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 2
        ..recipientNameErr = s.t.errRecipientName
        ..recipientPhoneErr = s.t.errPhone;
      s.draft.recipientName = 'J';
    }),
  );

  testWidgets(
    'new_order_package',
    (t) => capture(t, 'new_order_package', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 3;
      s.draft
        ..packageType = JhPackageType.clothes
        ..packageSize = JhPackageSize.medium
        ..quantity = 2;
    }),
  );

  testWidgets(
    'new_order_package_with_photo',
    (t) => capture(t, 'new_order_package_with_photo', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 3;
      s.draft
        ..packageType = JhPackageType.electronics
        ..packageSize = JhPackageSize.medium
        ..quantity = 1
        ..packagePhoto = tinyPng;
    }, scrollBy: 480),
  );

  void seedDraft(JhAppState s) {
    s.draft
      ..pickupLat = -6.7723
      ..pickupLng = 39.2199
      ..pickupAddress = 'Makongo, Dar es Salaam'
      ..pickupLandmark = 'Near XYZ Shop'
      ..pickupInstructions = 'Call me when you arrive'
      ..recipientName = 'John Michael'
      ..recipientPhone = '712345678'
      ..packageType = JhPackageType.clothes
      ..packageSize = JhPackageSize.medium
      ..quantity = 1
      ..declarationAccepted = true
      ..packagePhoto = tinyPng
      ..dropoffLat = -6.7000
      ..dropoffLng = 39.1950
      ..dropoffAddress = 'Goba, Dar es Salaam'
      ..dropoffLandmark = 'Near ABC Petrol Station';
  }

  testWidgets(
    'new_order_destination',
    (t) => capture(t, 'new_order_destination', (s) {
      onOrders(s);
      seedDraft(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 1
        ..routePhase = JhRoutePhase.dropoff;
    }),
  );

  testWidgets(
    'new_order_delivery_mode',
    (t) => capture(t, 'new_order_delivery_mode', (s) {
      onOrders(s);
      seedDraft(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 4;
      s.draft.deliveryMode = JhVehicle.motorcycle;
    }),
  );

  testWidgets(
    'new_order_review',
    (t) => capture(t, 'new_order_review', (s) {
      onOrders(s);
      seedDraft(s);
      s
        ..screen = JhScreen.newOrder
        ..orderStep = 5;
      s.draft.deliveryMode = JhVehicle.motorcycle;
    }),
  );

  testWidgets(
    'order_created',
    (t) => capture(t, 'order_created', (s) {
      onOrders(s);
      seedDraft(s);
      s.draft.deliveryMode = JhVehicle.motorcycle;
      final order = JhOrder.fromDraft(
        s.draft,
        id: 'JHD-20260909-00126',
        createdAt: pinnedClock(),
      );
      s.orders.insert(0, order);
      s
        ..selectedOrder = order
        ..screen = JhScreen.orderCreated;
    }),
  );

  testWidgets(
    'order_tracking',
    (t) => capture(t, 'order_tracking', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.orderDetail
        ..selectedOrder = s.orders.first; // already pickedUp -> Contact Support
    }),
  );

  testWidgets(
    'order_tracking_cancellable',
    (t) => capture(t, 'order_tracking_cancellable', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.orderDetail
        ..selectedOrder = s.orders[1]; // driverArriving -> Cancel Order
    }, scrollBy: 420),
  );

  testWidgets(
    'order_tracking_completed',
    (t) => capture(t, 'order_tracking_completed', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.orderDetail
        ..selectedOrder = s.orders[2]; // delivered, unrated
    }, scrollBy: 620),
  );

  testWidgets(
    'order_tracking_rated',
    (t) => capture(t, 'order_tracking_rated', (s) {
      onOrders(s);
      s.rateOrder(s.orders[3], 5);
      s
        ..screen = JhScreen.orderDetail
        ..selectedOrder = s.orders[3];
    }, scrollBy: 620),
  );

  testWidgets(
    'cancel_order_sheet',
    (t) => capture(t, 'cancel_order_sheet', (s) {
      onOrders(s);
      s
        ..screen = JhScreen.orderDetail
        ..selectedOrder = s.orders[1]
        ..cancelOrderOpen = true;
    }),
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jihudumie_app/api/api_models.dart';
import 'package:jihudumie_app/app.dart';
import 'package:jihudumie_app/l10n/dict.dart';
import 'package:jihudumie_app/orders/location_service.dart';
import 'package:jihudumie_app/orders/order_models.dart';
import 'package:jihudumie_app/state/app_state.dart';
import 'package:jihudumie_app/theme/icons.dart';

import 'support/fake_auth_api.dart';
import 'support/fake_location_service.dart';
import 'support/fake_orders_api.dart';
import 'support/fake_photo_service.dart';
import 'support/sample_orders.dart';

const t = JhStrings.en;

// A real, decodable 1x1 PNG -- `Image.memory` in the photo-attach widgets
// tries to decode whatever bytes it is given, so arbitrary bytes throw.
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY'
  '42YAAAAASUVORK5CYII=',
);

const _customer = JhUser(
  name: 'Amina Hassan',
  email: 'amina@example.com',
  phone: '712345678',
);

extension _Pump on WidgetTester {
  Future<(JhAppState, FakeLocationService)> boot({
    JhOrderBucket bucket = JhOrderBucket.active,
  }) async {
    view.physicalSize = const Size(402 * 3, 900 * 3);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);

    final location = FakeLocationService();
    // Both lists start from the same sample data, so a reload triggered
    // mid-test (most Orders actions cause one) stays consistent with what
    // the test already sees, instead of quietly reverting to empty.
    final sample = buildSampleOrders();
    final ordersApi = FakeOrdersApi()..ordersToReturn = List.of(sample);
    final state = JhAppState(
      api: FakeAuthApi(),
      location: location,
      photos: FakePhotoService(),
      ordersApi: ordersApi,
      checkSessionOnStart: false,
    )
      ..clock = (() => DateTime(2026, 9, 11, 9, 41))
      ..liveMap = false
      ..user = _customer
      ..screen = JhScreen.orders
      ..tab = JhTab.orders
      ..ordersBucket = bucket
      ..orders.addAll(sample);

    await pumpWidget(JihudumieApp(state: state));
    await pump();
    return (state, location);
  }

  Future<void> tapText(String label) async {
    final finder = find.text(label).first;
    await ensureVisible(finder);
    await tap(finder);
    await pump();
  }

  Future<void> settle() async {
    await pump();
    await pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('my orders', () {
    testWidgets('the tab shows a real screen with the sample orders', (
      tester,
    ) async {
      await tester.boot();
      expect(find.text(t.myOrders), findsOneWidget);
      expect(find.text('JHD-20260910-00125'), findsOneWidget);
      expect(find.text('Makongo → Goba'), findsOneWidget);
    });

    testWidgets('the segmented control filters by bucket', (tester) async {
      final (state, _) = await tester.boot();

      expect(find.text('Sinza → Mikocheni'), findsNothing);
      await tester.tapText(t.ordersCompleted);
      expect(state.ordersBucket, JhOrderBucket.completed);
      expect(find.text('Sinza → Mikocheni'), findsOneWidget);
      expect(find.text('Makongo → Goba'), findsNothing);

      await tester.tapText(t.ordersCancelled);
      expect(find.text('Tabata → Ukonga'), findsOneWidget);
    });

    testWidgets('an empty bucket shows its own copy', (tester) async {
      final (state, _) = await tester.boot();
      state.orders.clear();
      await tester.pump();
      await tester.tapText(t.ordersActive);
      expect(find.text(t.ordersEmptyActive), findsOneWidget);
    });

    testWidgets('tapping an order opens the tracking screen', (tester) async {
      final (state, _) = await tester.boot();
      await tester.tapText('Makongo → Goba');
      await tester.settle();
      expect(state.screen, JhScreen.orderDetail);
      expect(find.text(t.trackPackageTitle), findsWidgets);
      expect(find.text(t.deliveryTimelineTitle), findsOneWidget);
      // The sample order carries a driver.
      expect(find.text('John Michael'), findsOneWidget);

      state.back();
      await tester.settle();
      expect(state.screen, JhScreen.orders);
    });
  });

  group('send a package', () {
    Future<void> toWizard(WidgetTester tester, JhAppState state) async {
      state.startNewOrder();
      await tester.pump();
    }

    /// Route step: pickup half then drop-off half -> lands on step 2.
    Future<void> doRoute(WidgetTester tester, JhAppState state) async {
      await tester.tapText(t.pickupUseCurrentLocation);
      await tester.settle();
      await tester.tapText(t.pickupConfirm);
      await tester.settle();
      // Drop-off half — drive the map pick through state.
      state.dropoffSelectPlace(
        const JhPlace(lat: -6.70, lng: 39.20, address: 'Goba, Dar es Salaam'),
      );
      await tester.pump();
      await tester.tapText(t.destinationConfirm);
      await tester.settle();
    }

    Future<void> doRecipient(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(0), 'Juma Ally');
      await tester.enterText(find.byType(TextField).at(1), '765123456');
      await tester.pump();
      await tester.tapText(t.continueLabel);
      await tester.settle();
    }

    Future<void> doPackage(WidgetTester tester) async {
      await tester.tapText(t.pkgClothes);
      await tester.tapText(t.declarationAgree);
      await tester.tapText(t.continueLabel);
      await tester.settle();
    }

    testWidgets('the hero card starts the wizard directly', (tester) async {
      final (state, _) = await tester.boot();

      await tester.tapText(t.sendPackageCard);
      await tester.settle();
      expect(state.screen, JhScreen.newOrder);
      expect(state.orderStep, 1);
      expect(state.routePhase, JhRoutePhase.pickup);
      expect(state.pickupMode, JhPickupMode.manual);
      expect(find.text(t.pickupUseCurrentLocation), findsOneWidget);
    });

    testWidgets('the Route step goes pickup -> drop-off without leaving step 1',
        (tester) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);

      await tester.tapText(t.pickupUseCurrentLocation);
      await tester.settle();
      expect(state.pickupMode, JhPickupMode.manual);
      expect(state.draft.pickupAddress, loc.place.address);

      await tester.tapText(t.pickupConfirm);
      await tester.settle();
      expect(state.orderStep, 1);
      expect(state.routePhase, JhRoutePhase.dropoff);
      expect(find.text(t.destinationTitle), findsOneWidget);

      state.dropoffSelectPlace(
        const JhPlace(lat: -6.70, lng: 39.20, address: 'Goba, Dar es Salaam'),
      );
      await tester.pump();
      await tester.tapText(t.destinationConfirm);
      await tester.settle();
      expect(state.orderStep, 2);
    });

    testWidgets('typing a destination searches without pressing Enter', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      loc.searchResults = const [
        JhPlace(lat: -6.70, lng: 39.20, address: 'Goba, Dar es Salaam'),
      ];
      await toWizard(tester, state);
      await tester.tapText(t.pickupUseCurrentLocation);
      await tester.settle();
      await tester.tapText(t.pickupConfirm);
      await tester.settle();
      expect(state.routePhase, JhRoutePhase.dropoff);

      await tester.enterText(find.byType(TextField).first, 'Goba');
      await tester.pump(); // onChanged fires, debounce starts
      expect(find.text('Goba, Dar es Salaam'), findsNothing);

      await tester.pump(const Duration(milliseconds: 450)); // past the debounce
      await tester.pump();
      expect(find.text('Goba, Dar es Salaam'), findsOneWidget);
    });

    testWidgets('declining location drops to manual with a message', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      loc.denial = const JhLocationException(JhLocationDenial.deniedForever);
      await toWizard(tester, state);

      await tester.tapText(t.pickupUseCurrentLocation);
      await tester.settle();

      expect(state.pickupMode, JhPickupMode.manual);
      expect(find.text(t.pickupDenied), findsOneWidget);
    });

    testWidgets('manual search selects a pickup place', (tester) async {
      final (state, loc) = await tester.boot();
      loc.searchResults = const [
        JhPlace(lat: -6.8, lng: 39.28, address: 'Mbezi Beach, Dar es Salaam'),
      ];
      await toWizard(tester, state);

      await tester.enterText(find.byType(TextField).first, 'Mbezi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.settle();

      await tester.tapText('Mbezi Beach, Dar es Salaam');
      await tester.settle();
      expect(state.draft.pickupAddress, 'Mbezi Beach, Dar es Salaam');
    });

    testWidgets('typing a pickup place searches without pressing Enter', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      loc.searchResults = const [
        JhPlace(lat: -6.8, lng: 39.28, address: 'Mbezi Beach, Dar es Salaam'),
      ];
      await toWizard(tester, state);

      await tester.enterText(find.byType(TextField).first, 'Mbezi');
      await tester.pump(); // onChanged fires, debounce starts
      expect(find.text('Mbezi Beach, Dar es Salaam'), findsNothing);

      await tester.pump(const Duration(milliseconds: 450)); // past the debounce
      await tester.pump();
      expect(find.text('Mbezi Beach, Dar es Salaam'), findsOneWidget);
    });

    testWidgets('recipient step validates before advancing', (tester) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await doRoute(tester, state);
      expect(state.orderStep, 2);

      await tester.tapText(t.continueLabel);
      await tester.settle();
      expect(state.orderStep, 2);
      expect(find.text(t.errRecipientName), findsOneWidget);
      expect(find.text(t.errPhone), findsOneWidget);

      await doRecipient(tester);
      expect(state.orderStep, 3);
    });

    testWidgets('package step: choices, quantity and the declaration gate', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await doRoute(tester, state);
      await doRecipient(tester);

      await tester.tapText(t.pkgClothes);
      await tester.tapText(t.sizeMedium);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(state.draft.quantity, 3);
      expect(state.draft.packageType, JhPackageType.clothes);
      expect(state.draft.packageSize, JhPackageSize.medium);

      await tester.tapText(t.continueLabel);
      await tester.settle();
      expect(state.orderStep, 3);
      expect(find.text(t.errDeclaration), findsOneWidget);

      await tester.tapText(t.declarationAgree);
      await tester.tapText(t.continueLabel);
      await tester.settle();
      expect(state.orderStep, 4);
    });

    testWidgets('the full wizard commits an order and confirms it', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await doRoute(tester, state);
      await doRecipient(tester);
      await doPackage(tester);
      expect(state.orderStep, 4);

      // 4 Delivery mode
      await tester.tapText(t.vehicleCar);
      expect(state.draft.deliveryMode, JhVehicle.car);
      await tester.tapText(t.continueLabel);
      await tester.settle();
      expect(state.orderStep, 5);

      // 5 Review
      expect(find.text(t.reviewTitle), findsOneWidget);
      await tester.tapText(t.sendPackageButton);
      await tester.settle();

      expect(state.screen, JhScreen.orderCreated);
      final placed = state.orders.first;
      // The id is server-generated now, not a locally predictable counter --
      // just check the shape the app renders.
      expect(placed.id, startsWith('JHD-'));
      expect(placed.dropoffArea, 'Goba');
      expect(placed.vehicle, JhVehicle.car);
      expect(placed.priceTsh, JhVehicle.car.priceTsh);
      expect(find.text(t.orderCreatedTitle), findsOneWidget);

      await tester.tapText(t.trackPackageButton);
      await tester.settle();
      expect(state.screen, JhScreen.orderDetail);
    });

    testWidgets('editing a section from Review returns to Review', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      state
        ..draft.pickupAddress = 'Makongo, Dar es Salaam'
        ..draft.pickupLat = -6.77
        ..draft.pickupLng = 39.22
        ..draft.recipientName = 'Juma'
        ..draft.recipientPhone = '765123456'
        ..draft.packageType = JhPackageType.food
        ..draft.declarationAccepted = true
        ..draft.dropoffAddress = 'Goba'
        ..draft.dropoffLat = -6.70
        ..draft.dropoffLng = 39.20
        ..draft.deliveryMode = JhVehicle.motorcycle
        ..editOrderStep(5); // onto Review directly
      await tester.pump();

      // Edit the Recipient section (2nd on the page).
      await tester.tap(find.text(t.reviewEdit).at(1));
      await tester.settle();
      expect(state.orderStep, 2);

      await tester.enterText(find.byType(TextField).at(0), 'Neema Said');
      await tester.pump();
      await tester.tapText(t.continueLabel);
      await tester.settle();

      // Back on Review, not walked forward to Package.
      expect(state.orderStep, 5);
      expect(state.draft.recipientName, 'Neema Said');
      expect(find.text(t.reviewTitle), findsOneWidget);
    });

    testWidgets('editing Pickup from Review opens the Route step, pickup half', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      state
        ..draft.pickupAddress = 'Makongo'
        ..draft.pickupLat = -6.77
        ..draft.pickupLng = 39.22
        ..draft.dropoffAddress = 'Goba'
        ..draft.dropoffLat = -6.70
        ..draft.dropoffLng = 39.20
        ..editOrderStep(5);
      await tester.pump();

      await tester.tap(find.text(t.reviewEdit).first); // Pickup section
      await tester.settle();
      expect(state.orderStep, 1);
      expect(state.routePhase, JhRoutePhase.pickup);
    });

    testWidgets('back exits the wizard from the very start of the Route step', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await tester.tapText(t.pickupUseCurrentLocation);
      await tester.settle();
      expect(state.pickupMode, JhPickupMode.manual);

      // Back out of the pickup half with nothing more to collapse to -> the
      // order list, in one step.
      state.back();
      await tester.pump();
      expect(state.screen, JhScreen.orders);
    });

    testWidgets('back from the drop-off half returns to the pickup half', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await tester.tapText(t.pickupUseCurrentLocation);
      await tester.settle();
      await tester.tapText(t.pickupConfirm);
      await tester.settle();
      expect(state.routePhase, JhRoutePhase.dropoff);

      state.back();
      await tester.pump();
      expect(state.orderStep, 1);
      expect(state.routePhase, JhRoutePhase.pickup);
    });

    testWidgets('re-entering the wizard starts from a clean draft', (
      tester,
    ) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await doRoute(tester, state);
      await tester.enterText(find.byType(TextField).at(0), 'Someone');
      await tester.pump();

      state.openMyOrders();
      await tester.pump();
      state.startNewOrder();
      await tester.pump();
      expect(state.draft.recipientName, '');
      expect(state.orderStep, 1);
      expect(state.routePhase, JhRoutePhase.pickup);
    });

    testWidgets('a language switch keeps the wizard where it is', (tester) async {
      final (state, loc) = await tester.boot();
      await toWizard(tester, state);
      await doRoute(tester, state);
      expect(state.orderStep, 2);

      state.toggleLang();
      await tester.pump();
      expect(state.orderStep, 2);
      expect(state.screen, JhScreen.newOrder);
    });
  });

  group('order actions', () {
    testWidgets('cancel is offered before pickup, and dismissible', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final order = state.orders[1]; // driverArriving -- not picked up yet
      state.openOrderDetail(order);
      await tester.pump();

      expect(find.text(t.cancelOrderCta), findsOneWidget);
      expect(find.text(t.contactSupport), findsNothing);

      await tester.tapText(t.cancelOrderCta);
      await tester.pump(const Duration(milliseconds: 250)); // sheet slide-in
      expect(state.cancelOrderOpen, isTrue);
      expect(find.text(t.cancelOrderTitle), findsOneWidget);

      await tester.tapText(t.keepOrder);
      await tester.settle();
      expect(state.cancelOrderOpen, isFalse);
      expect(state.orders[1].status, JhOrderStatus.inTransit);
    });

    testWidgets('confirming cancel moves the order to Cancelled', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final order = state.orders[1];
      state.openOrderDetail(order);
      await tester.pump();

      await tester.tapText(t.cancelOrderCta);
      await tester.pump(const Duration(milliseconds: 250)); // sheet slide-in
      await tester.tap(find.text(t.cancelOrderConfirm).last);
      await tester.settle();

      expect(state.screen, JhScreen.orders);
      expect(state.ordersBucket, JhOrderBucket.cancelled);
      final cancelled = state.orders.firstWhere((o) => o.id == order.id);
      expect(cancelled.status, JhOrderStatus.cancelled);
    });

    testWidgets(
      'a courier already carrying the package offers support, not cancel',
      (tester) async {
        final (state, _) = await tester.boot();
        state.openOrderDetail(state.orders[0]); // already pickedUp
        await tester.pump();

        expect(find.text(t.cancelOrderCta), findsNothing);
        expect(find.text(t.contactSupport), findsOneWidget);
      },
    );

    testWidgets('rating a completed delivery replaces the prompt with stars', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final order = state.orders[2]; // completed, unrated
      expect(order.myRating, isNull);
      state.openOrderDetail(order);
      await tester.pump();

      expect(find.text(t.rateDriverTitle), findsOneWidget);
      expect(find.text(t.youRatedThisDelivery), findsNothing);

      final star4 = find.byKey(const ValueKey('rateStar4'));
      await tester.ensureVisible(star4);
      await tester.tap(star4);
      await tester.settle();

      expect(state.orders[2].myRating, 4);
      expect(find.text(t.youRatedThisDelivery), findsOneWidget);
      expect(find.text(t.rateDriverTitle), findsNothing);
    });

    testWidgets('reorder prefills a fresh draft on Review, ready to send', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final order = state.orders[2];
      state.openOrderDetail(order);
      await tester.pump();

      await tester.tapText(t.reorder);
      await tester.settle();

      expect(state.screen, JhScreen.newOrder);
      expect(state.orderStep, JhAppState.orderStepMax);
      expect(state.draft.recipientName, order.recipientName);
      expect(state.draft.dropoffAddress, order.dropoffAddress);
      expect(state.draft.declarationAccepted, isTrue);
      expect(find.text(t.reviewTitle), findsOneWidget);
    });

    testWidgets(
      'a freshly placed order can be cancelled straight from Order Created',
      (tester) async {
        final (state, _) = await tester.boot();
        state.startNewOrder();
        await tester.pump();

        await tester.tapText(t.pickupUseCurrentLocation);
        await tester.settle();
        await tester.tapText(t.pickupConfirm);
        await tester.settle();
        state.dropoffSelectPlace(
          const JhPlace(lat: -6.70, lng: 39.20, address: 'Goba, Dar es Salaam'),
        );
        await tester.pump();
        await tester.tapText(t.destinationConfirm);
        await tester.settle();

        await tester.enterText(find.byType(TextField).at(0), 'Juma Ally');
        await tester.enterText(find.byType(TextField).at(1), '765123456');
        await tester.pump();
        await tester.tapText(t.continueLabel);
        await tester.settle();

        await tester.tapText(t.pkgClothes);
        await tester.tapText(t.declarationAgree);
        await tester.tapText(t.continueLabel);
        await tester.settle();

        await tester.tapText(t.vehicleCar);
        await tester.tapText(t.continueLabel);
        await tester.settle();
        await tester.tapText(t.sendPackageButton);
        await tester.settle();
        expect(state.screen, JhScreen.orderCreated);

        expect(find.text(t.backToHome), findsOneWidget);
        await tester.tapText(t.cancelOrderCta);
        await tester.pump(const Duration(milliseconds: 250)); // sheet slide-in
        await tester.tap(find.text(t.cancelOrderConfirm).last);
        await tester.settle();

        expect(state.screen, JhScreen.orders);
        expect(state.ordersBucket, JhOrderBucket.cancelled);
        expect(state.orders.first.status, JhOrderStatus.cancelled);
      },
    );
  });

  group('recent places', () {
    Future<void> completeAnOrder(WidgetTester tester, JhAppState state) async {
      state.startNewOrder();
      await tester.pump();
      state
        ..draft.pickupAddress = 'Makongo, Dar es Salaam'
        ..draft.pickupLat = -6.77
        ..draft.pickupLng = 39.22
        ..draft.recipientName = 'Juma'
        ..draft.recipientPhone = '765123456'
        ..draft.packageType = JhPackageType.food
        ..draft.declarationAccepted = true
        ..draft.dropoffAddress = 'Goba, Dar es Salaam'
        ..draft.dropoffLat = -6.70
        ..draft.dropoffLng = 39.20
        ..draft.deliveryMode = JhVehicle.motorcycle
        ..orderStep = JhAppState.orderStepMax; // ready to commit, not "editing"
      state.nextOrderStep();
      await tester.settle(); // the commit is a real (fake) request now
      expect(state.screen, JhScreen.orderCreated);
    }

    testWidgets('a placed order is remembered for next time', (tester) async {
      final (state, _) = await tester.boot();
      expect(state.recentPlaces, isEmpty);

      await completeAnOrder(tester, state);

      expect(state.recentPlaces.map((p) => p.address), [
        'Goba, Dar es Salaam', // most recent first: drop-off remembered after pickup
        'Makongo, Dar es Salaam',
      ]);
    });

    testWidgets(
      'a recent pickup fills the field on the search-first form',
      (tester) async {
        final (state, _) = await tester.boot();
        await completeAnOrder(tester, state);

        state.startNewOrder();
        await tester.pump();
        expect(find.text(t.recentPlacesTitle.toUpperCase()), findsOneWidget);

        await tester.tapText('Makongo, Dar es Salaam');
        await tester.settle();
        expect(state.draft.pickupAddress, 'Makongo, Dar es Salaam');
        expect(state.pickupMode, JhPickupMode.manual);
      },
    );

    testWidgets('a recent drop-off fills the destination field', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      await completeAnOrder(tester, state);

      state.startNewOrder();
      await tester.pump();
      await tester.tapText('Makongo, Dar es Salaam'); // pickup, from recents
      await tester.tapText(t.pickupConfirm);
      await tester.settle();
      expect(state.routePhase, JhRoutePhase.dropoff);
      expect(find.text(t.recentPlacesTitle.toUpperCase()), findsOneWidget);

      await tester.tapText('Goba, Dar es Salaam');
      await tester.settle();
      expect(state.draft.dropoffAddress, 'Goba, Dar es Salaam');
    });

    testWidgets('signing out clears what was remembered', (tester) async {
      final (state, _) = await tester.boot();
      await completeAnOrder(tester, state);
      expect(state.recentPlaces, isNotEmpty);

      await state.doLogout();
      await tester.pump();
      expect(state.recentPlaces, isEmpty);
    });
  });

  group('photo attach', () {
    testWidgets('a photo taken at the Package step can be removed', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final photos = state.photos as FakePhotoService;
      photos.cameraResult = _tinyPng;

      state.startNewOrder();
      await tester.pump();
      state.editOrderStep(3); // straight to Package -- Route/Recipient untested here
      await tester.pump();

      expect(state.draft.packagePhoto, isNull);
      await tester.tapText(t.takePhoto);
      await tester.settle();

      expect(state.draft.packagePhoto, isNotNull);
      expect(photos.calls, ['camera']);
      expect(find.text(t.takePhoto), findsNothing, reason: 'thumbnail replaces the pick buttons');

      final removeButton = find.byIcon(JhIcons.removePhoto);
      await tester.ensureVisible(removeButton);
      await tester.tap(removeButton);
      await tester.settle();
      expect(state.draft.packagePhoto, isNull);
      expect(find.text(t.takePhoto), findsOneWidget);
    });

    testWidgets('cancelling the picker leaves nothing attached', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final photos = state.photos as FakePhotoService; // galleryResult null

      state.startNewOrder();
      await tester.pump();
      state.editOrderStep(3);
      await tester.pump();

      await tester.tapText(t.chooseFromGallery);
      await tester.settle();
      expect(state.draft.packagePhoto, isNull);
      expect(photos.calls, ['gallery']);
    });

    testWidgets('an attached photo is carried through to the committed order', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final ordersApi = state.ordersApi as FakeOrdersApi;
      const photoUrl = 'http://127.0.0.1:8000/media/package_photos/x.jpg';
      // What the real server would send back -- a URL, not the bytes the
      // client uploaded. `createOrder`'s own default echo has no way to
      // produce that, so this shapes the reply explicitly.
      ordersApi.result = JhOrder.fromJson({
        'id': 'srv-photo',
        'order_number': 'JHD-20260911-PHOTO',
        'status': 'IN_TRANSIT',
        'stage': 'REQUEST_CREATED',
        'vehicle': 'MOTORCYCLE',
        'price_tsh': 5000,
        'paid': false,
        'payment_method': 'PAY_AFTER_DELIVERY',
        'created_at': '2026-09-11T09:41:00Z',
        'recipient_name': 'Juma',
        'recipient_phone': '765123456',
        'package_type': 'FOOD',
        'package_size': 'SMALL',
        'quantity': 1,
        'pickup_address': 'Makongo, Dar es Salaam',
        'pickup_landmark': '',
        'pickup_instructions': '',
        'pickup_lat': -6.77,
        'pickup_lng': 39.22,
        'dropoff_address': 'Goba, Dar es Salaam',
        'dropoff_landmark': '',
        'dropoff_lat': -6.70,
        'dropoff_lng': 39.20,
        'delivery_instructions': '',
        'package_description': '',
        'handling_instructions': '',
        'photo_url': photoUrl,
      });

      final bytes = _tinyPng;
      state.startNewOrder();
      await tester.pump();
      state
        ..draft.pickupAddress = 'Makongo, Dar es Salaam'
        ..draft.pickupLat = -6.77
        ..draft.pickupLng = 39.22
        ..draft.recipientName = 'Juma'
        ..draft.recipientPhone = '765123456'
        ..draft.packageType = JhPackageType.food
        ..draft.declarationAccepted = true
        ..draft.packagePhoto = bytes
        ..draft.dropoffAddress = 'Goba, Dar es Salaam'
        ..draft.dropoffLat = -6.70
        ..draft.dropoffLng = 39.20
        ..draft.deliveryMode = JhVehicle.motorcycle
        ..orderStep = JhAppState.orderStepMax;
      state.nextOrderStep();
      await tester.settle();

      // The bytes reached the API layer...
      expect(ordersApi.lastPhotoSent, bytes);
      // ...and the server's URL is what the app actually renders.
      expect(state.orders.first.packagePhotoUrl, photoUrl);
    });
  });

  group('orders wiring', () {
    testWidgets('loadOrders populates the list and toggles the loading flag', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final ordersApi = state.ordersApi as FakeOrdersApi;
      state.orders.clear();
      expect(state.ordersLoading, isFalse);

      final future = state.loadOrders();
      expect(state.ordersLoading, isTrue);
      await future;

      expect(state.ordersLoading, isFalse);
      expect(state.orders, hasLength(ordersApi.ordersToReturn.length));
    });

    testWidgets('a failed list load keeps whatever was already showing', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final ordersApi = state.ordersApi as FakeOrdersApi;
      ordersApi.failure = const JhApiException.network();

      await state.loadOrders();
      await tester.pump();

      expect(state.ordersLoading, isFalse);
      expect(state.orders, isNotEmpty); // the boot()-seeded list, untouched
      expect(state.toast, contains(t.errNet));
    });

    testWidgets('a failed create stays on Review and flashes a toast', (
      tester,
    ) async {
      final (state, _) = await tester.boot();
      final ordersApi = state.ordersApi as FakeOrdersApi;
      ordersApi.failure = const JhApiException.network();
      final before = state.orders.length;

      state.startNewOrder();
      await tester.pump();
      state
        ..draft.pickupAddress = 'Makongo, Dar es Salaam'
        ..draft.pickupLat = -6.77
        ..draft.pickupLng = 39.22
        ..draft.recipientName = 'Juma'
        ..draft.recipientPhone = '765123456'
        ..draft.packageType = JhPackageType.food
        ..draft.declarationAccepted = true
        ..draft.dropoffAddress = 'Goba, Dar es Salaam'
        ..draft.dropoffLat = -6.70
        ..draft.dropoffLng = 39.20
        ..draft.deliveryMode = JhVehicle.motorcycle
        ..orderStep = JhAppState.orderStepMax;

      state.nextOrderStep();
      await tester.settle();

      expect(state.screen, JhScreen.newOrder); // never left Review
      expect(state.orderStep, JhAppState.orderStepMax);
      expect(state.orderSubmitting, isFalse);
      expect(state.orders, hasLength(before)); // nothing inserted
      expect(state.toast, contains(t.errNet));
    });

    testWidgets('a failed cancel leaves the order untouched', (tester) async {
      final (state, _) = await tester.boot();
      final ordersApi = state.ordersApi as FakeOrdersApi;
      final order = state.orders[1]; // driverArriving -- cancellable
      state.openOrderDetail(order);
      await tester.pump();
      ordersApi.failure = const JhApiException.network();

      await tester.tapText(t.cancelOrderCta);
      await tester.pump(const Duration(milliseconds: 250)); // sheet slide-in
      await tester.tap(find.text(t.cancelOrderConfirm).last);
      await tester.settle();

      expect(state.screen, JhScreen.orderDetail); // never navigated away
      expect(state.orders[1].status, JhOrderStatus.inTransit);
      expect(state.toast, contains(t.errNet));
    });
  });

  group('order model', () {
    test('fromDraft maps fields, route and mode-based price', () {
      final draft = JhOrderDraft()
        ..pickupAddress = 'Kariakoo, Dar es Salaam'
        ..pickupLat = -6.82
        ..pickupLng = 39.27
        ..dropoffAddress = 'Kawe, Dar es Salaam'
        ..dropoffLat = -6.71
        ..dropoffLng = 39.23
        ..recipientName = '  Juma  '
        ..recipientPhone = '765 123 456'
        ..packageSize = JhPackageSize.large
        ..quantity = 2
        ..deliveryMode = JhVehicle.car;

      final order = JhOrder.fromDraft(
        draft,
        id: 'JHD-20260911-00126',
        createdAt: DateTime(2026, 9, 11),
      );

      expect(order.pickupArea, 'Kariakoo');
      expect(order.dropoffArea, 'Kawe');
      expect(order.hasRoute, isTrue);
      expect(order.routeKm, greaterThan(0));
      expect(order.recipientName, 'Juma');
      expect(order.priceTsh, JhVehicle.car.priceTsh);
      expect(order.vehicle, JhVehicle.car);
      expect(order.stage, JhTrackingStage.requestCreated);
      expect(order.status, JhOrderStatus.inTransit);
    });

    test('status maps to a bucket', () {
      expect(JhOrderStatus.inTransit.bucket, JhOrderBucket.active);
      expect(JhOrderStatus.completed.bucket, JhOrderBucket.completed);
      expect(JhOrderStatus.cancelled.bucket, JhOrderBucket.cancelled);
    });
  });
}

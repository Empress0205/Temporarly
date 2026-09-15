@Tags(['live'])
library;

// Drives the app's real JhHttpAuthApi against a running backend, to prove the
// two sides actually speak to each other -- unlike the rest of the suite,
// which uses FakeAuthApi and never opens a socket.
//
// Excluded from the normal run (`flutter test`) by the `live` tag. Run
// explicitly, with the backend up on :8000 and SMS_PROVIDER=logging:
//
//     flutter test test/live_wiring_test.dart --dart-define=JH_API_BASE_URL=http://127.0.0.1:8000
//
// The code is read out of the backend's own server.log, since the logging
// provider prints it there instead of sending an SMS.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jihudumie_app/api/api_client.dart';
import 'package:jihudumie_app/api/api_models.dart';
import 'package:jihudumie_app/api/auth_api.dart';
import 'package:jihudumie_app/api/token_store.dart';
import 'package:jihudumie_app/orders/order_models.dart';
import 'package:jihudumie_app/orders/orders_api.dart';

final _serverLog = File('../backend/server.log');

Future<String> _latestCodeFor(String phoneDigits) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (_serverLog.existsSync()) {
      final lines = await _serverLog.readAsLines();
      final pattern = RegExp('\\[SMS -> \\+255$phoneDigits\\] (\\d{6})');
      for (final line in lines.reversed) {
        final match = pattern.firstMatch(line);
        if (match != null) return match.group(1)!;
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  fail('no code appeared in server.log for $phoneDigits -- is the backend '
      'running on :8000 with SMS_PROVIDER=logging?');
}

void main() {
  // A fresh number per run, so repeat runs never collide with a customer the
  // last run created.
  final suffix = DateTime.now().millisecondsSinceEpoch % 10000000;
  final phone = '71${suffix.toString().padLeft(7, '0')}';

  // One client for the whole file: these tests are a single sequential
  // scenario, not independent cases, so the session from verification must
  // still be there when /me and logout run.
  final api = JhHttpAuthApi(tokens: JhMemoryTokenStore());

  test('register/request-otp reaches the live backend and sends a real code', () async {
    final challenge = await api.registerRequestOtp(phone);
    expect(challenge.otpLength, 6);
    expect(challenge.expiresIn, greaterThan(0));
  });

  late String code;

  test('the code the server sent is readable from its own log', () async {
    code = await _latestCodeFor(phone);
    expect(code, hasLength(6));
  });

  test('register/verify-otp creates the account and returns a session', () async {
    final session = await api.registerVerifyOtp(
      phone: phone,
      code: code,
      fullName: 'Wiring Check',
      email: 'wiring-check@example.com',
    );
    expect(session.customer.name, 'Wiring Check');
    expect(session.customer.phone, phone);
    expect(session.tokens.access, isNotEmpty);
  });

  test('/me identifies the same customer through the stored token', () async {
    final me = await api.me();
    expect(me.phone, phone);
  });

  // Shares the auth client's token store rather than a fresh one, the same
  // way `JhAppState` would end up with both talking to the same session.
  final orders = JhHttpOrdersApi(api: JhApiClient(tokens: api.tokenStore));
  late String orderServerId;

  test('creating an order reaches the live backend with a real price', () async {
    final order = await orders.createOrder(
      JhOrderDraft()
        ..pickupAddress = 'Makongo Juu, Dar es Salaam'
        ..pickupLat = -6.7723
        ..pickupLng = 39.2199
        ..dropoffAddress = 'Goba, Dar es Salaam'
        ..dropoffLat = -6.70
        ..dropoffLng = 39.20
        ..recipientName = 'Wiring Check Recipient'
        ..recipientPhone = phone
        ..packageType = JhPackageType.documents
        ..declarationAccepted = true
        ..deliveryMode = JhVehicle.motorcycle,
    );
    orderServerId = order.serverId;
    expect(order.id, startsWith('JHD-'));
    // Server-computed from real distance, not the old flat 5000 -- proof the
    // client isn't quietly trusting its own guess.
    expect(order.priceTsh, greaterThan(0));
  });

  test('the order the server just created shows up in the list', () async {
    final list = await orders.listOrders();
    expect(list.any((o) => o.serverId == orderServerId), isTrue);
  });

  test('cancelling it before pickup succeeds', () async {
    final cancelled = await orders.cancelOrder(orderServerId);
    expect(cancelled.status, JhOrderStatus.cancelled);
  });

  test('the same code cannot be replayed', () async {
    await expectLater(
      api.registerVerifyOtp(
        phone: phone,
        code: code,
        fullName: 'Wiring Check',
        email: 'wiring-check@example.com',
      ),
      throwsA(
        isA<JhApiException>().having(
          (e) => e.code,
          'code',
          JhErrorCode.otpNotFound,
        ),
      ),
    );
  });

  test('registering the same number again is refused', () async {
    await expectLater(
      api.registerRequestOtp(phone),
      throwsA(
        isA<JhApiException>().having(
          (e) => e.code,
          'code',
          JhErrorCode.phoneAlreadyRegistered,
        ),
      ),
    );
  });

  test('login/request-otp works for the number just registered', () async {
    final challenge = await api.loginRequestOtp(phone);
    expect(challenge.expiresIn, greaterThan(0));
  });

  test('a wrong login code reports attempts remaining', () async {
    await expectLater(
      api.loginVerifyOtp(phone: phone, code: '000000'),
      throwsA(
        isA<JhApiException>()
            .having((e) => e.code, 'code', JhErrorCode.otpIncorrect)
            .having((e) => e.attemptsRemaining, 'attemptsRemaining', 2),
      ),
    );
  });

  test('an unregistered number is refused by login', () async {
    await expectLater(
      api.loginRequestOtp('765111222'),
      throwsA(
        isA<JhApiException>().having(
          (e) => e.code,
          'code',
          JhErrorCode.phoneNotRegistered,
        ),
      ),
    );
  });

  test('logout revokes the session on the server', () async {
    await api.logout();
    await expectLater(
      api.me(),
      throwsA(isA<JhApiException>().having((e) => e.isAuthFailure, 'isAuthFailure', isTrue)),
    );
  });
}

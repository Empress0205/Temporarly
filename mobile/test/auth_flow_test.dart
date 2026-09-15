import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jihudumie_app/api/api_models.dart';
import 'package:jihudumie_app/app.dart';
import 'package:jihudumie_app/l10n/dict.dart';
import 'package:jihudumie_app/state/app_state.dart';

import 'support/fake_auth_api.dart';

const t = JhStrings.en;

/// The OTP screen holds a repeating timer and buttons show spinners, so these
/// tests advance the clock explicitly rather than using `pumpAndSettle`, which
/// would never settle.
extension _Pump on WidgetTester {
  /// The artboard size the screens were drawn at. The default 800x600 test
  /// surface is the wrong shape and pushes pinned actions out of reach.
  void usePhoneSurface() {
    view.physicalSize = const Size(402 * 3, 874 * 3);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);
  }

  /// Boots the app against [api] and clears the splash handover.
  Future<JhAppState> boot(FakeAuthApi api) async {
    usePhoneSurface();
    final state = JhAppState(api: api);
    await pumpWidget(JihudumieApp(state: state));
    await pump();
    await pump();
    return state;
  }

  Future<void> tapText(String label) async {
    // Account grew taller than one screen once its settings rows were added,
    // so a label lower on the page needs scrolling into view before it can
    // be hit-tested.
    final finder = find.text(label).first;
    await ensureVisible(finder);
    await tap(finder);
    await pump();
  }

  /// Lets the pending API future resolve and the UI rebuild.
  Future<void> settle() async {
    await pump();
    await pump(const Duration(milliseconds: 50));
  }
}

Future<void> fillRegistration(
  WidgetTester tester, {
  String phone = '712000111',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Grace Mushi');
  await tester.pump();
  await tester.enterText(fields.at(1), 'grace@example.com');
  await tester.pump();
  await tester.enterText(fields.at(2), phone);
  await tester.pump();
}

/// Registration up to the OTP screen.
Future<JhAppState> toOtpViaRegister(
  WidgetTester tester,
  FakeAuthApi api,
) async {
  final state = await tester.boot(api);
  await tester.tapText(t.continueLabel);
  await fillRegistration(tester);
  await tester.tapText(t.createAccount);
  await tester.settle();
  return state;
}

void main() {
  group('session at start-up', () {
    testWidgets('no stored session hands over to welcome', (tester) async {
      final api = FakeAuthApi()..signedIn = false;
      final state = await tester.boot(api);

      expect(state.screen, JhScreen.welcome);
      expect(find.text(t.continueLabel), findsOneWidget);
      // Authenticated data is never rendered on an unconfirmed session.
      expect(state.user, isNull);
    });

    testWidgets('a session the server honours goes straight to home', (
      tester,
    ) async {
      final api = FakeAuthApi()..signedIn = true;
      final state = await tester.boot(api);

      expect(state.screen, JhScreen.home);
      expect(state.user?.name, 'Amina Hassan');
      // The server was asked; the presence of a token alone is not enough.
      expect(api.calls, contains('hasValidSession'));
      expect(api.calls, contains('me'));
    });
  });

  group('registration', () {
    testWidgets('the account is created by the verification, not before', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await toOtpViaRegister(tester, api);

      expect(state.screen, JhScreen.otp);
      expect(state.user, isNull, reason: 'nothing exists until the code is in');
      expect(api.calls, contains('registerRequestOtp:712000111'));

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tapText(t.verify);
      await tester.settle();

      expect(state.screen, JhScreen.home);
      expect(state.user?.name, 'Grace Mushi');
      expect(
        api.calls,
        contains('registerVerifyOtp:712000111:123456:Grace Mushi:grace@example.com'),
      );
    });

    testWidgets('a taken number offers login and follows through', (
      tester,
    ) async {
      final api = FakeAuthApi()
        ..failure = const JhApiException(
          code: JhErrorCode.phoneAlreadyRegistered,
        );
      final state = await tester.boot(api);
      await tester.tapText(t.continueLabel);
      await fillRegistration(tester, phone: '712345678');
      await tester.tapText(t.createAccount);
      await tester.settle();

      expect(state.screen, JhScreen.register);
      expect(find.text(t.errTaken), findsOneWidget);

      await tester.tapText(t.errTakenCta);
      expect(state.screen, JhScreen.phone);
      expect(state.mode, JhMode.login);
    });

    testWidgets('local field validation runs before any request', (
      tester,
    ) async {
      final api = FakeAuthApi();
      await tester.boot(api);
      await tester.tapText(t.continueLabel);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'G');
      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.enterText(fields.at(2), '712000111');
      await tester.pump();
      await tester.tapText(t.createAccount);
      await tester.settle();

      expect(find.text(t.errName), findsOneWidget);
      expect(find.text(t.errEmail), findsOneWidget);
      expect(
        api.calls.where((c) => c.startsWith('register')),
        isEmpty,
        reason: 'no round trip for an obvious typo',
      );
    });
  });

  group('login', () {
    testWidgets('an unregistered number offers registration', (tester) async {
      final api = FakeAuthApi()
        ..failure = const JhApiException(code: JhErrorCode.phoneNotRegistered);
      final state = await tester.boot(api);
      await tester.tapText(t.continueLabel);
      await tester.tapText(t.login);

      await tester.enterText(find.byType(TextField).first, '799999999');
      await tester.pump();
      await tester.tapText(t.sendOtp);
      await tester.settle();

      expect(find.text(t.errUnknown), findsOneWidget);
      expect(state.user, isNull);
      expect(state.screen, JhScreen.phone);

      await tester.tapText(t.errUnknownCta);
      expect(state.screen, JhScreen.register);
    });

    testWidgets('a suspended account cannot sign in', (tester) async {
      final api = FakeAuthApi()
        ..failure = const JhApiException(code: JhErrorCode.accountSuspended);
      final state = await tester.boot(api);
      await tester.tapText(t.continueLabel);
      await tester.tapText(t.login);
      await tester.enterText(find.byType(TextField).first, '712345678');
      await tester.pump();
      await tester.tapText(t.sendOtp);
      await tester.settle();

      expect(find.text(t.errSuspended), findsOneWidget);
      expect(state.user, isNull);
    });
  });

  group('the OTP screen renders what the server reports', () {
    testWidgets('timings come from the challenge, not from constants', (
      tester,
    ) async {
      final api = FakeAuthApi()
        ..challenge = const JhOtpChallenge(
          expiresIn: 120,
          resendAvailableIn: 45,
          otpLength: 4,
          maxAttempts: 5,
        );
      final state = await toOtpViaRegister(tester, api);

      expect(state.ttl, 120);
      expect(state.cooldown, 45);
      expect(state.otpConfig.length, 4);
      expect(state.otpConfig.maxAttempts, 5);
    });

    testWidgets('a wrong code shows the attempts the server has left', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await toOtpViaRegister(tester, api);

      api.failure = const JhApiException(
        code: JhErrorCode.otpIncorrect,
        details: {'attempts_remaining': 2},
      );
      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.pump();
      await tester.tapText(t.verify);
      await tester.settle();

      expect(find.text('${t.errOtp} (2 ${t.attemptsLeft})'), findsOneWidget);
      expect(state.blocked, isFalse);
      expect(state.otp, isEmpty, reason: 'the cells clear for a fresh attempt');
    });

    testWidgets('the attempt limit locks the input', (tester) async {
      final api = FakeAuthApi();
      final state = await toOtpViaRegister(tester, api);

      api.failure = const JhApiException(
        code: JhErrorCode.otpAttemptsExceeded,
      );
      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.pump();
      await tester.tapText(t.verify);
      await tester.settle();

      expect(state.blocked, isTrue);
      expect(find.text(t.errAttempts), findsOneWidget);
      expect(state.user, isNull);
    });

    testWidgets('an expired code is reported and clears the countdown', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await toOtpViaRegister(tester, api);

      api.failure = const JhApiException(code: JhErrorCode.otpExpired);
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tapText(t.verify);
      await tester.settle();

      expect(find.text(t.errOtpExpired), findsOneWidget);
      expect(state.ttl, 0);
      expect(state.user, isNull);
    });

    testWidgets('resend asks for the right purpose and resets the counters', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await toOtpViaRegister(tester, api);

      // Direct field mutation would not rebuild the widget, so the cooldown
      // is run down through the real timer instead – that is what the
      // customer actually waits through.
      await tester.pump(const Duration(seconds: 61));
      await tester.tapText(t.resend);
      await tester.settle();

      expect(api.calls, contains('resendOtp:712000111:REGISTRATION'));
      expect(state.attempts, 0);
      expect(state.blocked, isFalse);
      expect(state.ttl, 300);
    });
  });

  group('changing the phone number', () {
    Future<JhAppState> signedInOnProfile(
      WidgetTester tester,
      FakeAuthApi api,
    ) async {
      api.signedIn = true;
      final state = await tester.boot(api);
      await tester.tapText(t.account);
      return state;
    }

    testWidgets('the stored number moves only after verification', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await signedInOnProfile(tester, api);

      await tester.tapText(t.changePhone);
      await tester.enterText(find.byType(TextField).first, '754111222');
      await tester.pump();
      await tester.tapText(t.sendOtp);
      await tester.settle();

      expect(state.screen, JhScreen.otp);
      expect(state.account.phone, '712345678', reason: 'unverified, unchanged');

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      await tester.tapText(t.verify);
      await tester.settle();

      expect(state.account.phone, '754111222');
      expect(state.screen, JhScreen.profile);
    });

    testWidgets('a rejected number leaves the account untouched', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await signedInOnProfile(tester, api);

      await tester.tapText(t.changePhone);
      api.failure = const JhApiException(
        code: JhErrorCode.phoneBelongsToOther,
      );
      await tester.enterText(find.byType(TextField).first, '765000000');
      await tester.pump();
      await tester.tapText(t.sendOtp);
      await tester.settle();

      expect(find.text(t.errOther), findsOneWidget);
      expect(state.account.phone, '712345678');
      expect(state.screen, JhScreen.changePhone);
    });
  });

  group('account settings', () {
    Future<JhAppState> signedInOnProfile(
      WidgetTester tester,
      FakeAuthApi api,
    ) async {
      api.signedIn = true;
      final state = await tester.boot(api);
      await tester.tapText(t.account);
      return state;
    }

    testWidgets('rows not built yet acknowledge the tap rather than doing nothing', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await signedInOnProfile(tester, api);

      await tester.tapText(t.updateEmail);
      await tester.pump();

      expect(state.toast, contains(t.updateEmail));
      expect(state.screen, JhScreen.profile, reason: 'acknowledged, not navigated');
    });

    testWidgets('delete account asks for confirmation before doing anything', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await signedInOnProfile(tester, api);

      await tester.tapText(t.deleteAccount);
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.deleteAccountOpen, isTrue);
      expect(find.text(t.deleteAccountConfirm), findsOneWidget);
      expect(state.user, isNotNull, reason: 'nothing happened to the account yet');

      await tester.tap(find.text(t.deleteAccountCta));
      await tester.settle();

      expect(state.deleteAccountOpen, isFalse);
      expect(state.user, isNotNull, reason: 'there is no deletion to perform yet');
      expect(state.toast, contains(t.deleteAccount));
    });

    testWidgets('cancelling delete account leaves the session untouched', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await signedInOnProfile(tester, api);

      await tester.tapText(t.deleteAccount);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapText(t.cancel);
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.deleteAccountOpen, isFalse);
      expect(state.user, isNotNull);
    });
  });

  group('session ending', () {
    testWidgets('logout revokes on the server and returns to welcome', (
      tester,
    ) async {
      final api = FakeAuthApi();
      api.signedIn = true;
      final state = await tester.boot(api);
      await tester.tapText(t.account);

      await tester.tapText(t.logout);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(t.logoutConfirm), findsOneWidget);

      // Both the Profile row and the sheet say "Log out"; the sheet's is on top.
      await tester.tap(find.text(t.logout).last);
      await tester.settle();

      expect(api.calls, contains('logout'));
      expect(state.user, isNull);
      expect(state.screen, JhScreen.welcome);
    });

    testWidgets('logging out still works when the server refuses', (
      tester,
    ) async {
      // A customer who asked to sign out must not be stranded on an
      // authenticated screen because a request failed.
      final api = FakeAuthApi();
      api.signedIn = true;
      final state = await tester.boot(api);
      await tester.tapText(t.account);

      await tester.tapText(t.logout);
      await tester.pump(const Duration(milliseconds: 300));
      api.failure = const JhApiException.network();
      await tester.tap(find.text(t.logout).last);
      await tester.settle();

      expect(state.user, isNull);
      expect(state.screen, JhScreen.welcome);
    });

    testWidgets('a rejected token ends the session mid-flow', (tester) async {
      final api = FakeAuthApi();
      api.signedIn = true;
      final state = await tester.boot(api);
      await tester.tapText(t.account);
      await tester.tapText(t.changePhone);

      api.failure = const JhApiException(code: JhErrorCode.tokenInvalid);
      await tester.enterText(find.byType(TextField).first, '754111222');
      await tester.pump();
      await tester.tapText(t.sendOtp);
      await tester.settle();

      // Spec 35: stop looking authenticated rather than leaving the customer
      // on a screen whose every request fails.
      expect(state.user, isNull);
      expect(state.screen, JhScreen.welcome);
    });
  });

  group('resilience', () {
    testWidgets('a network failure preserves what was typed', (tester) async {
      final api = FakeAuthApi()..failure = const JhApiException.network();
      final state = await tester.boot(api);
      await tester.tapText(t.continueLabel);
      await fillRegistration(tester);
      await tester.tapText(t.createAccount);
      await tester.settle();

      expect(find.text(t.errNet), findsOneWidget);
      expect(state.screen, JhScreen.register);
      expect(state.user, isNull);
      expect(state.name, 'Grace Mushi');
      expect(state.phone, '712000111');
    });

    testWidgets('a second submission cannot fire while one is in flight', (
      tester,
    ) async {
      final gate = Completer<void>();
      final api = FakeAuthApi()..gate = gate.future;
      final state = await tester.boot(api);
      await tester.tapText(t.continueLabel);
      await tester.tapText(t.login);
      await tester.enterText(find.byType(TextField).first, '712345678');
      await tester.pump();

      await tester.tapText(t.sendOtp);
      expect(state.loading, JhLoading.phone);

      await tester.tapText(t.sending);
      expect(
        api.calls.where((c) => c.startsWith('loginRequestOtp')).length,
        1,
        reason: 'the guard must stop a duplicate request, not just the button',
      );

      gate.complete();
      await tester.settle();
      expect(state.screen, JhScreen.otp);
    });

    testWidgets('switching language keeps the screen and the form intact', (
      tester,
    ) async {
      final api = FakeAuthApi();
      final state = await tester.boot(api);
      await tester.tapText(t.continueLabel);
      await fillRegistration(tester);

      await tester.tapText('SW');

      expect(state.screen, JhScreen.register);
      expect(state.name, 'Grace Mushi');
      expect(state.phone, '712000111');
      expect(find.text(JhStrings.sw.registerTitle), findsOneWidget);
    });
  });

  group('phone helpers', () {
    test('reduces any accepted form to nine significant digits', () {
      expect(JhAppState.digitsOf('0712 345 678'), '712345678');
      expect(JhAppState.digitsOf('+255 712 345 678'), '712345678');
      expect(JhAppState.digitsOf('255712345678'), '712345678');
    });

    test('accepts Tanzanian mobile prefixes only', () {
      expect(JhAppState.isValidPhone('712345678'), isTrue);
      expect(JhAppState.isValidPhone('654321098'), isTrue);
      expect(JhAppState.isValidPhone('812345678'), isFalse);
      expect(JhAppState.isValidPhone('71234567'), isFalse);
    });

    test('formats for display', () {
      expect(JhAppState.prettyPhone('712345678'), '+255 712 345 678');
      expect(JhAppState.prettyPhone('712'), '+255 712');
    });
  });
}

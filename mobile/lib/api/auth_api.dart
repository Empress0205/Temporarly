import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'token_store.dart';

/// The nine authentication operations, as the app needs them.
///
/// An interface rather than a concrete class so tests can substitute a fake and
/// drive every branch -- including the ones that are awkward to provoke against
/// a real server, like an expired code or an exhausted attempt limit.
abstract class JhAuthApi {
  Future<JhOtpChallenge> registerRequestOtp(String phone);

  Future<JhSession> registerVerifyOtp({
    required String phone,
    required String code,
    required String fullName,
    required String email,
  });

  Future<JhOtpChallenge> loginRequestOtp(String phone);

  Future<JhSession> loginVerifyOtp({
    required String phone,
    required String code,
  });

  Future<JhOtpChallenge> resendOtp({
    required String phone,
    required String purpose,
  });

  /// The signed-in customer, from the stored session.
  Future<JhUser> me();

  Future<void> logout();

  Future<JhOtpChallenge> phoneChangeRequest(String newPhone);

  Future<JhUser> phoneChangeVerify({
    required String phone,
    required String code,
  });

  /// True when a stored session exists and the server still honours it.
  Future<bool> hasValidSession();
}

/// Purpose values understood by `resend-otp`. They must match
/// `OtpPurpose` in `backend/authentication/models.py`.
class JhOtpPurpose {
  const JhOtpPurpose._();

  static const registration = 'REGISTRATION';
  static const login = 'LOGIN';
  static const phoneChange = 'PHONE_CHANGE';
}

/// Talks to the Django backend, via the shared [JhApiClient] transport
/// (bearer header, refresh-on-401, the error envelope -- see
/// `lib/api/api_client.dart`).
class JhHttpAuthApi implements JhAuthApi {
  JhHttpAuthApi({http.Client? client, JhTokenStore? tokens, String? baseUrl})
    : _api = JhApiClient(client: client, tokens: tokens, baseUrl: baseUrl);

  final JhApiClient _api;

  JhTokenStore get tokenStore => _api.tokenStore;

  @override
  Future<JhOtpChallenge> registerRequestOtp(String phone) async {
    final body = await _api.post('/api/auth/register/request-otp', {
      'phone_number': phone,
    });
    return JhOtpChallenge.fromJson(body);
  }

  @override
  Future<JhSession> registerVerifyOtp({
    required String phone,
    required String code,
    required String fullName,
    required String email,
  }) async {
    final body = await _api.post('/api/auth/register/verify-otp', {
      'phone_number': phone,
      'code': code,
      'full_name': fullName,
      'email': email,
    });
    final session = JhSession.fromJson(body);
    await _api.tokenStore.write(session.tokens);
    return session;
  }

  @override
  Future<JhOtpChallenge> loginRequestOtp(String phone) async {
    final body = await _api.post('/api/auth/login/request-otp', {
      'phone_number': phone,
    });
    return JhOtpChallenge.fromJson(body);
  }

  @override
  Future<JhSession> loginVerifyOtp({
    required String phone,
    required String code,
  }) async {
    final body = await _api.post('/api/auth/login/verify-otp', {
      'phone_number': phone,
      'code': code,
    });
    final session = JhSession.fromJson(body);
    await _api.tokenStore.write(session.tokens);
    return session;
  }

  @override
  Future<JhOtpChallenge> resendOtp({
    required String phone,
    required String purpose,
  }) async {
    final body = await _api.post('/api/auth/resend-otp', {
      'phone_number': phone,
      'purpose': purpose,
    });
    return JhOtpChallenge.fromJson(body);
  }

  @override
  Future<JhUser> me() async {
    final body = await _api.get('/api/auth/me', authenticated: true);
    return customerFromJson(body);
  }

  @override
  Future<void> logout() async {
    final stored = await _api.tokenStore.read();
    try {
      if (stored != null) {
        await _api.post(
          '/api/auth/logout',
          {'refresh': stored.refresh},
          authenticated: true,
        );
      }
    } on JhApiException {
      // The session is being abandoned either way. A server that refuses the
      // call -- because the token already expired, say -- must not strand the
      // customer on an authenticated screen (spec §22).
    } finally {
      await _api.tokenStore.clear();
    }
  }

  @override
  Future<JhOtpChallenge> phoneChangeRequest(String newPhone) async {
    final body = await _api.post('/api/customer/phone/request-change', {
      'phone_number': newPhone,
    }, authenticated: true);
    return JhOtpChallenge.fromJson(body);
  }

  @override
  Future<JhUser> phoneChangeVerify({
    required String phone,
    required String code,
  }) async {
    final stored = await _api.tokenStore.read();
    final body = await _api.post('/api/customer/phone/verify-change', {
      'phone_number': phone,
      'code': code,
      // Keeps this device signed in while the server revokes the others.
      if (stored != null) 'refresh': stored.refresh,
    }, authenticated: true);
    return customerFromJson(body);
  }

  @override
  Future<bool> hasValidSession() async {
    if (await _api.tokenStore.read() == null) return false;
    try {
      await me();
      return true;
    } on JhApiException catch (error) {
      // A rejected session is cleared rather than kept: the app must never
      // show authenticated screens on credentials the server has refused
      // (spec §34, §35).
      if (error.isAuthFailure) {
        await _api.tokenStore.clear();
        return false;
      }
      // A network failure is not proof the session is bad, so it is left
      // alone and reported as "not signed in" for this launch only.
      return false;
    }
  }
}

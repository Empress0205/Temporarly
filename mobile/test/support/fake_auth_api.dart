import 'package:jihudumie_app/api/api_models.dart';
import 'package:jihudumie_app/api/auth_api.dart';
import 'package:jihudumie_app/state/app_state.dart';

/// A scriptable stand-in for the backend.
///
/// The rules themselves -- whether a number is registered, whether a code is
/// correct, how many attempts remain -- now live on the server and are tested
/// there. What these tests check is different: given a particular answer from
/// the server, does the app render the right thing and end up in the right
/// state. So this fake does not re-implement the rules; it lets each test say
/// what the server replied.
class FakeAuthApi implements JhAuthApi {
  /// Thrown by the next call, then cleared. Set it to drive a failure path.
  JhApiException? failure;

  /// What `request-otp` and `resend-otp` return when they succeed.
  JhOtpChallenge challenge = const JhOtpChallenge(
    expiresIn: 300,
    resendAvailableIn: 60,
    otpLength: 6,
    maxAttempts: 3,
  );

  /// The customer handed back on a successful verification.
  JhUser customer = const JhUser(
    name: 'Amina Hassan',
    email: 'amina.hassan@gmail.com',
    phone: '712345678',
  );

  /// Whether a stored session exists and the server honours it.
  bool signedIn = false;

  /// Every call made, in order, for assertions about what was sent.
  final List<String> calls = <String>[];

  /// Completes when the caller chooses, so tests can inspect the in-flight
  /// loading state. Left null for immediate returns.
  Future<void>? gate;

  Future<void> _enter(String call) async {
    calls.add(call);
    if (gate != null) await gate;
    final pending = failure;
    if (pending != null) {
      failure = null;
      throw pending;
    }
  }

  @override
  Future<JhOtpChallenge> registerRequestOtp(String phone) async {
    await _enter('registerRequestOtp:$phone');
    return challenge;
  }

  @override
  Future<JhSession> registerVerifyOtp({
    required String phone,
    required String code,
    required String fullName,
    required String email,
  }) async {
    await _enter('registerVerifyOtp:$phone:$code:$fullName:$email');
    return JhSession(
      customer: JhUser(name: fullName, email: email, phone: phone),
      tokens: const JhTokens(access: 'access', refresh: 'refresh'),
    );
  }

  @override
  Future<JhOtpChallenge> loginRequestOtp(String phone) async {
    await _enter('loginRequestOtp:$phone');
    return challenge;
  }

  @override
  Future<JhSession> loginVerifyOtp({
    required String phone,
    required String code,
  }) async {
    await _enter('loginVerifyOtp:$phone:$code');
    return JhSession(
      customer: customer,
      tokens: const JhTokens(access: 'access', refresh: 'refresh'),
    );
  }

  @override
  Future<JhOtpChallenge> resendOtp({
    required String phone,
    required String purpose,
  }) async {
    await _enter('resendOtp:$phone:$purpose');
    return challenge;
  }

  @override
  Future<JhUser> me() async {
    await _enter('me');
    return customer;
  }

  @override
  Future<void> logout() async {
    await _enter('logout');
    signedIn = false;
  }

  @override
  Future<JhOtpChallenge> phoneChangeRequest(String newPhone) async {
    await _enter('phoneChangeRequest:$newPhone');
    return challenge;
  }

  @override
  Future<JhUser> phoneChangeVerify({
    required String phone,
    required String code,
  }) async {
    await _enter('phoneChangeVerify:$phone:$code');
    customer = customer.copyWith(phone: phone);
    return customer;
  }

  @override
  Future<bool> hasValidSession() async {
    calls.add('hasValidSession');
    return signedIn;
  }
}

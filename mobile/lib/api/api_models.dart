import '../state/app_state.dart';

/// The failure codes the API returns.
///
/// The app branches on these, never on the message text: the server's prose is
/// English-only and meant for logs, while the app renders its own copy in the
/// customer's language. Kept as constants rather than an enum so an unknown
/// code from a newer server can still be carried and reported instead of
/// crashing the parse.
class JhErrorCode {
  const JhErrorCode._();

  static const phoneAlreadyRegistered = 'PHONE_ALREADY_REGISTERED';
  static const phoneNotRegistered = 'PHONE_NOT_REGISTERED';
  static const phoneSameAsCurrent = 'PHONE_SAME_AS_CURRENT';
  static const phoneBelongsToOther = 'PHONE_BELONGS_TO_OTHER';
  static const accountSuspended = 'ACCOUNT_SUSPENDED';

  static const otpNotFound = 'OTP_NOT_FOUND';
  static const otpIncorrect = 'OTP_INCORRECT';
  static const otpExpired = 'OTP_EXPIRED';
  static const otpAttemptsExceeded = 'OTP_ATTEMPTS_EXCEEDED';
  static const otpResendTooSoon = 'OTP_RESEND_TOO_SOON';

  static const rateLimited = 'RATE_LIMITED';
  static const smsSendFailed = 'SMS_SEND_FAILED';

  static const tokenExpired = 'TOKEN_EXPIRED';
  static const tokenInvalid = 'TOKEN_INVALID';

  static const validationFailed = 'VALIDATION_FAILED';

  /// Not a server code: raised when the request never completed.
  static const network = 'NETWORK_UNAVAILABLE';

  // Orders (`backend/orders/errors.py`)
  static const orderNotFound = 'ORDER_NOT_FOUND';
  static const orderCancelNotAllowed = 'ORDER_CANCEL_NOT_ALLOWED';
  static const orderNotCompleted = 'ORDER_NOT_COMPLETED';
  static const orderVehicleUnavailable = 'ORDER_VEHICLE_UNAVAILABLE';
  static const orderDeclarationRequired = 'ORDER_DECLARATION_REQUIRED';
}

/// A failed API call, carrying the machine-readable code the app branches on.
class JhApiException implements Exception {
  const JhApiException({
    required this.code,
    this.message = '',
    this.details = const {},
    this.statusCode,
  });

  /// The request did not reach the server, or the reply was unusable.
  const JhApiException.network([this.message = ''])
    : code = JhErrorCode.network,
      details = const {},
      statusCode = null;

  final String code;

  /// The server's English text. For logs and debugging, never for display.
  final String message;

  final Map<String, dynamic> details;
  final int? statusCode;

  /// Attempts left on the current code, when the server reported one.
  int? get attemptsRemaining {
    final value = details['attempts_remaining'];
    return value is int ? value : null;
  }

  /// Seconds before the customer may try again, on a rate limit.
  int? get retryAfterSeconds {
    final value = details['retry_after_seconds'];
    return value is int ? value : null;
  }

  /// True for the two codes that mean the session is no longer usable.
  bool get isAuthFailure =>
      code == JhErrorCode.tokenExpired || code == JhErrorCode.tokenInvalid;

  @override
  String toString() => 'JhApiException($code${message.isEmpty ? '' : ': $message'})';
}

/// What the server tells the client after issuing a code.
///
/// These values are policy (spec §43) and belong to the server, so the app
/// takes them from the response rather than holding constants of its own.
class JhOtpChallenge {
  const JhOtpChallenge({
    required this.expiresIn,
    required this.resendAvailableIn,
    required this.otpLength,
    required this.maxAttempts,
  });

  factory JhOtpChallenge.fromJson(Map<String, dynamic> json) => JhOtpChallenge(
    expiresIn: json['expires_in'] as int? ?? 0,
    resendAvailableIn: json['resend_available_in'] as int? ?? 0,
    otpLength: json['otp_length'] as int? ?? 6,
    maxAttempts: json['max_attempts'] as int? ?? 3,
  );

  final int expiresIn;
  final int resendAvailableIn;
  final int otpLength;
  final int maxAttempts;
}

/// The credentials that authorise protected requests.
class JhTokens {
  const JhTokens({
    required this.access,
    required this.refresh,
    this.accessExpiresIn = 0,
  });

  factory JhTokens.fromJson(Map<String, dynamic> json) => JhTokens(
    access: json['access'] as String? ?? '',
    refresh: json['refresh'] as String? ?? '',
    accessExpiresIn: json['access_expires_in'] as int? ?? 0,
  );

  final String access;
  final String refresh;
  final int accessExpiresIn;
}

/// A verified customer plus the session that was just opened for them.
class JhSession {
  const JhSession({required this.customer, required this.tokens});

  factory JhSession.fromJson(Map<String, dynamic> json) => JhSession(
    customer: customerFromJson(json['customer'] as Map<String, dynamic>),
    tokens: JhTokens.fromJson(json['tokens'] as Map<String, dynamic>),
  );

  final JhUser customer;
  final JhTokens tokens;
}

/// The server stores the canonical nine digits, which is exactly what
/// [JhUser.phone] holds, so no conversion is needed here.
JhUser customerFromJson(Map<String, dynamic> json) => JhUser(
  name: json['full_name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phone: json['phone_number'] as String? ?? '',
  createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
);

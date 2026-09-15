import 'package:flutter/foundation.dart';

/// Where the authentication API lives.
///
/// The default differs per platform because "localhost" means something
/// different inside an emulator: an Android emulator's own loopback is the
/// emulated device, and the host machine is reachable at 10.0.2.2 instead. An
/// iOS simulator and a desktop browser share the host's loopback.
///
/// Override for a real device or a deployed environment with:
///
///     flutter run --dart-define=JH_API_BASE_URL=https://api.jihudumie.co.tz
class JhApiConfig {
  const JhApiConfig._();

  static const _override = String.fromEnvironment('JH_API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  /// How long to wait on a request before treating it as a network failure.
  ///
  /// Deliberately longer than the server's own 15s SMS-provider timeout, so a
  /// slow provider surfaces as the server's error rather than as a client
  /// timeout that leaves the customer guessing.
  static const timeout = Duration(seconds: 25);
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_models.dart';

/// Where the session credentials live between launches.
///
/// Spec §37 requires authentication credentials on the device to be protected,
/// so these go to the platform keystore -- Keychain on iOS, EncryptedSharedPrefs
/// on Android -- rather than to plain preferences.
abstract class JhTokenStore {
  Future<JhTokens?> read();
  Future<void> write(JhTokens tokens);
  Future<void> clear();
}

class JhSecureTokenStore implements JhTokenStore {
  /// The package's defaults are already the strong ones in v11 -- AES-GCM for
  /// the data with RSA-OAEP key wrapping on Android, Keychain on iOS -- so no
  /// options are passed.
  JhSecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'jh_access_token';
  static const _refreshKey = 'jh_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<JhTokens?> read() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return JhTokens(access: access, refresh: refresh);
  }

  @override
  Future<void> write(JhTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.access);
    await _storage.write(key: _refreshKey, value: tokens.refresh);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// In-memory store for tests and for the web preview, where a keystore either
/// does not exist or is not worth provisioning.
class JhMemoryTokenStore implements JhTokenStore {
  JhTokens? _tokens;

  @override
  Future<JhTokens?> read() async => _tokens;

  @override
  Future<void> write(JhTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}

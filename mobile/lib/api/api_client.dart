import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_models.dart';
import 'token_store.dart';

/// Shared transport for every module that talks to the Django backend.
///
/// Extracted out of what was originally `JhHttpAuthApi`'s own private
/// methods: none of this -- the bearer header, the retry-once-after-refresh
/// on a 401, the timeout, the `{"error": {...}}` envelope -- is actually
/// authentication-specific, it just happened to be built there first. Orders
/// (and anything that follows it) hits the same server with the same JWT and
/// the same envelope, so this is genuinely shared infrastructure rather than
/// something to copy per module.
class JhApiClient {
  JhApiClient({http.Client? client, JhTokenStore? tokens, String? baseUrl})
    : _client = client ?? http.Client(),
      _tokens = tokens ?? JhSecureTokenStore(),
      _baseUrl = baseUrl ?? JhApiConfig.baseUrl;

  final http.Client _client;
  final JhTokenStore _tokens;
  final String _baseUrl;

  JhTokenStore get tokenStore => _tokens;

  Future<Map<String, dynamic>> get(String path, {bool authenticated = false}) async {
    final body = await _send(() async {
      final headers = await _headers(authenticated);
      return _client.get(Uri.parse('$_baseUrl$path'), headers: headers);
    }, authenticated: authenticated);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  /// Like [get], for an endpoint whose success body is a bare JSON array
  /// rather than an object (Orders' unpaginated list).
  Future<List<dynamic>> getList(
    String path, {
    bool authenticated = false,
  }) async {
    final body = await _send(() async {
      final headers = await _headers(authenticated);
      return _client.get(Uri.parse('$_baseUrl$path'), headers: headers);
    }, authenticated: authenticated);
    return body is List ? body : const [];
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> payload, {
    bool authenticated = false,
  }) async {
    final body = await _send(() async {
      final headers = await _headers(authenticated);
      return _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: jsonEncode(payload),
      );
    }, authenticated: authenticated);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  /// `multipart/form-data` -- for anything that rides alongside a file
  /// (Orders' package photo). [fields] are sent as plain form fields;
  /// [files] as file parts.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    Map<String, http.MultipartFile> files = const {},
    bool authenticated = true,
  }) async {
    final body = await _send(() async {
      final headers = await _headers(authenticated, contentType: false);
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
        ..headers.addAll(headers)
        ..fields.addAll(fields);
      for (final entry in files.entries) {
        request.files.add(entry.value);
      }
      final streamed = await _client.send(request).timeout(JhApiConfig.timeout);
      return http.Response.fromStream(streamed);
    }, authenticated: authenticated);
    return body is Map<String, dynamic> ? body : <String, dynamic>{};
  }

  Future<Map<String, String>> _headers(
    bool authenticated, {
    bool contentType = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (contentType) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final stored = await _tokens.read();
      if (stored != null) headers['Authorization'] = 'Bearer ${stored.access}';
    }
    return headers;
  }

  /// Sends a request, and on an expired access token refreshes once and
  /// retries.
  ///
  /// Access tokens live fifteen minutes, so this fires routinely during
  /// normal use. Without it the customer would be signed out mid-session for
  /// no reason they could see.
  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    required bool authenticated,
  }) async {
    var response = await _perform(request);

    if (authenticated && response.statusCode == 401) {
      if (await _refresh()) {
        response = await _perform(request);
      }
    }

    return _decode(response);
  }

  Future<http.Response> _perform(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(JhApiConfig.timeout);
    } on TimeoutException {
      throw const JhApiException.network('request timed out');
    } catch (error) {
      // Socket errors, DNS failures, a refused connection: from the
      // customer's point of view these are all "no connection" (spec §36).
      throw JhApiException.network(error.toString());
    }
  }

  /// Exchanges the refresh token for a new pair. Returns false when the
  /// session is genuinely finished.
  Future<bool> _refresh() async {
    final stored = await _tokens.read();
    if (stored == null) return false;

    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/api/auth/token/refresh'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh': stored.refresh}),
          )
          .timeout(JhApiConfig.timeout);
    } catch (_) {
      return false;
    }

    if (response.statusCode != 200) {
      // The refresh token is spent, revoked or reused. Nothing is
      // recoverable from here.
      await _tokens.clear();
      return false;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await _tokens.write(
      JhTokens(
        access: body['access'] as String? ?? '',
        // Rotation is on, so a new refresh token comes back with it. Falling
        // back to the old one would leave a blacklisted token in storage.
        refresh: body['refresh'] as String? ?? stored.refresh,
      ),
    );
    return true;
  }

  /// Turns a response into its parsed body (an object or, for a list
  /// endpoint, an array), or into the error the app branches on.
  dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      return const <String, dynamic>{};
    }

    late final dynamic parsed;
    try {
      parsed = jsonDecode(response.body);
    } on FormatException {
      throw JhApiException(
        code: JhErrorCode.network,
        message: 'server returned non-JSON (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return parsed;

    final body = parsed is Map<String, dynamic> ? parsed : <String, dynamic>{};
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      return throw JhApiException(
        code: error['code'] as String? ?? JhErrorCode.validationFailed,
        message: error['message'] as String? ?? '',
        details: (error['details'] as Map?)?.cast<String, dynamic>() ?? const {},
        statusCode: response.statusCode,
      );
    }

    throw JhApiException(
      code: JhErrorCode.validationFailed,
      message: 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }
}

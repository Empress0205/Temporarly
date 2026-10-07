import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../api/api_client.dart';
import '../api/api_models.dart';
import 'location_service.dart';

/// The real [JhLocationService]. The only file in the app that reaches for
/// device GPS, so the rest of the module — and every test — stays free of
/// platform channels.
///
/// Search, place resolution and reverse-geocoding all go through our own
/// backend (`/api/places/*`), which in turn calls Google's Places API (New)
/// and Geocoding API — the key stays server-side (section 43). This replaces
/// the Photon stopgap now that the client has approved the Google budget.
class JhGooglePlacesLocationService implements JhLocationService {
  JhGooglePlacesLocationService({JhApiClient? api}) : _api = api ?? JhApiClient();

  final JhApiClient _api;

  /// One token spans every keystroke of a single search plus the details
  /// call that follows picking a suggestion -- that pairing is what lets
  /// Google bill the whole thing as one session instead of per request.
  /// `null` means "no search in progress"; a fresh one is minted on the next
  /// [search] call and spent (cleared) the moment [resolve] uses it.
  String? _sessionToken;

  @override
  Future<JhPlace> currentPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const JhLocationException(JhLocationDenial.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const JhLocationException(JhLocationDenial.deniedForever);
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const JhLocationException(JhLocationDenial.denied);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return JhPlace(
      lat: position.latitude,
      lng: position.longitude,
      address: await addressOf(position.latitude, position.longitude),
    );
  }

  @override
  Future<String> addressOf(double lat, double lng) async {
    try {
      final body = await _api.get(
        '/api/places/reverse-geocode?lat=$lat&lng=$lng',
        authenticated: true,
      );
      final address = body['address'] as String?;
      return (address == null || address.trim().isEmpty) ? _coords(lat, lng) : address;
    } on JhApiException {
      // No network, or Google couldn't resolve it -- never blocks the
      // customer from placing an order over a reverse-geocode hiccup.
      return _coords(lat, lng);
    }
  }

  @override
  Future<List<JhPlacePrediction>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final token = _sessionToken ??= _newSessionToken();
    try {
      final body = await _api.getList(
        '/api/places/autocomplete'
        '?q=${Uri.encodeQueryComponent(trimmed)}'
        '&session_token=${Uri.encodeQueryComponent(token)}',
        authenticated: true,
      );
      final predictions = <JhPlacePrediction>[];
      for (final item in body) {
        if (item is! Map<String, dynamic>) continue;
        final placeId = item['place_id'] as String?;
        final description = item['description'] as String?;
        if (placeId != null && description != null) {
          predictions.add(JhPlacePrediction(placeId: placeId, description: description));
        }
      }
      return predictions;
    } on JhApiException {
      return const [];
    }
  }

  @override
  Future<JhPlace> resolve(JhPlacePrediction prediction) async {
    // The session the prediction came from, even if a stray call elsewhere
    // already started a new one -- falling back to a fresh token still works
    // (Google just bills it as its own session), it just loses the discount.
    final token = _sessionToken ?? _newSessionToken();
    _sessionToken = null; // spent either way

    final body = await _api.get(
      '/api/places/details'
      '?place_id=${Uri.encodeQueryComponent(prediction.placeId)}'
      '&session_token=${Uri.encodeQueryComponent(token)}',
      authenticated: true,
    );
    final lat = (body['lat'] as num).toDouble();
    final lng = (body['lng'] as num).toDouble();

    // The suggestion's own label, not Place Details' `formattedAddress` --
    // that label is what the customer actually read and picked, and Google
    // already built it well. `formattedAddress` can fall back to a plus code
    // ("65QP+CG9, Dar es Salaam") for a point with no conventional street
    // address, which reads as a bug even though it's a real answer. Place
    // Details is only needed here for the coordinates.
    final description = prediction.description.trim();
    final fallback = body['address'] as String?;
    return JhPlace(
      lat: lat,
      lng: lng,
      address: description.isNotEmpty ? description : (fallback ?? _coords(lat, lng)),
    );
  }

  static final _random = Random.secure();

  /// Not an RFC 4122 UUID -- Google only needs an opaque, sufficiently
  /// unique string per session, and this avoids a dependency for it.
  static String _newSessionToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _coords(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

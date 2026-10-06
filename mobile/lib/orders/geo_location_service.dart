import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'location_service.dart';

/// The real [JhLocationService]. The only file in the app that reaches for
/// device GPS or the network geocoder, so the rest of the module — and every
/// test — stays free of platform channels and live requests.
///
/// Search and reverse-geocoding go through Photon (photon.komoot.io), a free
/// autocomplete API built on OpenStreetMap data — no key, no billing. This is
/// a stopgap: it is a real step up from the bare native geocoder this
/// replaced (proper prefix-matching, ranked results), but it is not
/// Google-Places quality. Swap this file for a Google-backed implementation
/// once that budget is approved — [JhLocationService] is the seam, so
/// nothing else in the app needs to change.
class JhGeoLocationService implements JhLocationService {
  JhGeoLocationService();

  static const _searchUrl = 'https://photon.komoot.io/api/';
  static const _reverseUrl = 'https://photon.komoot.io/reverse';

  // Biases results toward Dar es Salaam -- Photon ranks nearby matches
  // higher rather than restricting to the area, so an exact match elsewhere
  // in Tanzania still surfaces.
  static const _biasLat = -6.7924;
  static const _biasLng = 39.2083;

  static const _timeout = Duration(seconds: 8);

  // Public instances ask callers to identify themselves, the same courtesy
  // the OSM tile usage policy already follows.
  static const _headers = {'User-Agent': 'JihudumieApp/1.0'};

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
      final uri = Uri.parse(_reverseUrl).replace(
        queryParameters: {'lon': lng.toString(), 'lat': lat.toString()},
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return _coords(lat, lng);

      final features = _featuresOf(response.body);
      if (features.isEmpty) return _coords(lat, lng);
      return _label(features.first) ?? _coords(lat, lng);
    } catch (_) {
      // No network, a timeout, or a malformed response -- never blocks the
      // customer from placing an order over a search hiccup.
      return _coords(lat, lng);
    }
  }

  @override
  Future<List<JhPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    try {
      final uri = Uri.parse(_searchUrl).replace(
        queryParameters: {
          'q': trimmed,
          'limit': '5',
          'lat': _biasLat.toString(),
          'lon': _biasLng.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) return const [];

      final places = <JhPlace>[];
      for (final feature in _featuresOf(response.body)) {
        final place = _place(feature);
        if (place != null) places.add(place);
      }
      return places;
    } catch (_) {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _featuresOf(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final features = decoded['features'] as List?;
    return [for (final f in features ?? const []) f as Map<String, dynamic>];
  }

  static JhPlace? _place(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coords = geometry?['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;

    // GeoJSON order is [lon, lat], the opposite of how the rest of this app
    // takes coordinates.
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    return JhPlace(lat: lat, lng: lng, address: _label(feature) ?? _coords(lat, lng));
  }

  /// Builds a short, human address from Photon's structured fields --
  /// "Kariakoo Market, Kariakoo, Dar es Salaam" rather than a raw dump of
  /// every field it returns.
  static String? _label(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>?;
    if (props == null) return null;

    final parts = <String>[];
    for (final key in ['name', 'street', 'suburb', 'city', 'state']) {
      final value = props[key];
      final last = parts.isEmpty ? null : parts.last;
      if (value is String && value.trim().isNotEmpty && value != last) {
        parts.add(value);
      }
    }
    return parts.isEmpty ? null : parts.take(3).join(', ');
  }

  static String _coords(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// The real [JhLocationService]. The only file in the app that imports
/// `geolocator` / `geocoding`, so the rest of the module — and every test —
/// stays free of the platform channels.
class JhGeoLocationService implements JhLocationService {
  JhGeoLocationService();

  /// Lazy: constructing `Geocoding()` reaches for a platform factory that is
  /// absent under `flutter test`. Deferring it means a bare `JhAppState()` in
  /// a test that never opens the Pickup step stays hermetic.
  late final Geocoding _geocoding = Geocoding();

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
      final marks = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return _coords(lat, lng);
      final m = marks.first;
      final parts = <String?>[
        m.name,
        m.subLocality,
        m.locality,
      ].where((s) => s != null && s.trim().isNotEmpty).cast<String>();
      return parts.isEmpty ? _coords(lat, lng) : parts.join(', ');
    } catch (_) {
      // No platform geocoder (GMS-less emulator, desktop) or no match.
      return _coords(lat, lng);
    }
  }

  @override
  Future<List<JhPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final locations = await _geocoding.locationFromAddress(trimmed);
      return [
        for (final l in locations.take(5))
          JhPlace(
            lat: l.latitude,
            lng: l.longitude,
            address: await addressOf(l.latitude, l.longitude),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String _coords(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

import 'package:flutter/widgets.dart' show immutable;

/// A resolved point with a human-readable address.
@immutable
class JhPlace {
  const JhPlace({
    required this.lat,
    required this.lng,
    required this.address,
  });

  final double lat;
  final double lng;

  /// Reverse-geocoded, or a `"lat, lng"` string where geocoding failed.
  final String address;
}

/// One autocomplete suggestion -- a label the customer can recognise, not yet
/// a point. Google's Places API (and most real autocomplete APIs) only
/// resolves coordinates on request, as a second call, because computing them
/// for every prediction on every keystroke would be wasteful: [search]
/// returns these cheaply, [JhLocationService.resolve] spends the one the
/// customer actually picks.
@immutable
class JhPlacePrediction {
  const JhPlacePrediction({required this.placeId, required this.description});

  /// Opaque, provider-specific. Round-tripped back into [resolve] unchanged.
  final String placeId;

  /// What the customer sees in the suggestion list.
  final String description;
}

enum JhLocationDenial { denied, deniedForever, serviceDisabled }

class JhLocationException implements Exception {
  const JhLocationException(this.reason);
  final JhLocationDenial reason;

  @override
  String toString() => 'JhLocationException(${reason.name})';
}

/// The location work the Pickup step needs. Injected into [JhAppState] the same
/// way `clock` is, so tests supply fixed coordinates and never touch a real
/// GPS or a network geocoder.
abstract class JhLocationService {
  /// Requests permission, reads the device position, and reverse-geocodes it.
  /// Throws [JhLocationException] if permission or the location service is
  /// unavailable.
  Future<JhPlace> currentPlace();

  /// The address for a point the user dragged the map pin to. Never throws —
  /// falls back to a `"lat, lng"` string.
  Future<String> addressOf(double lat, double lng);

  /// Ranked suggestions for the manual search field. Returns an empty list
  /// rather than throwing when nothing matches.
  Future<List<JhPlacePrediction>> search(String query);

  /// Resolves one suggestion from [search] to an actual point. Can throw --
  /// unlike [search] and [addressOf], there is no reasonable fallback value
  /// for "a place the customer explicitly chose, but we can't locate".
  Future<JhPlace> resolve(JhPlacePrediction prediction);
}

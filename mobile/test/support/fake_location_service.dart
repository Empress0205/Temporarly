import 'package:jihudumie_app/orders/location_service.dart';

/// Scriptable [JhLocationService] for tests — mirrors `FakeAuthApi`.
///
/// Default place is a point in Dar es Salaam so the Pickup step has something
/// deterministic to render.
class FakeLocationService implements JhLocationService {
  JhPlace place = const JhPlace(
    lat: -6.7723,
    lng: 39.2199,
    address: 'Makongo Juu, Dar es Salaam',
  );

  /// Set to make [currentPlace] throw instead of resolving.
  JhLocationException? denial;

  /// What [search] returns.
  List<JhPlacePrediction> searchResults = const [];

  /// What [resolve] returns for any prediction -- real Google calls resolve
  /// by `placeId`, but a test only ever has one scripted outcome in flight at
  /// once, so matching on which prediction was passed buys nothing.
  JhPlace resolvedPlace = const JhPlace(
    lat: -6.7723,
    lng: 39.2199,
    address: 'Makongo Juu, Dar es Salaam',
  );

  /// Set to make [resolve] throw instead of resolving.
  Object? resolveError;

  final List<String> calls = [];

  @override
  Future<JhPlace> currentPlace() async {
    calls.add('currentPlace');
    if (denial != null) throw denial!;
    return place;
  }

  @override
  Future<String> addressOf(double lat, double lng) async {
    calls.add('addressOf:$lat,$lng');
    return place.address;
  }

  @override
  Future<List<JhPlacePrediction>> search(String query) async {
    calls.add('search:$query');
    return searchResults;
  }

  @override
  Future<JhPlace> resolve(JhPlacePrediction prediction) async {
    calls.add('resolve:${prediction.placeId}');
    if (resolveError != null) throw resolveError!;
    return resolvedPlace;
  }
}

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
  List<JhPlace> searchResults = const [];

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
  Future<List<JhPlace>> search(String query) async {
    calls.add('search:$query');
    return searchResults;
  }
}

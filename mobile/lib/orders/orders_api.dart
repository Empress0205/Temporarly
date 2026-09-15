import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import 'order_models.dart';

/// The four order operations the app needs. An interface, same reason as
/// `JhAuthApi`: tests inject a fake and drive every branch, including
/// failures that are awkward to provoke against a real server.
abstract class JhOrdersApi {
  Future<List<JhOrder>> listOrders();

  Future<JhOrder> createOrder(JhOrderDraft draft);

  Future<JhOrder> cancelOrder(String serverId);

  Future<JhOrder> rateOrder(String serverId, int stars);
}

/// Talks to `orders/views.py` on the backend, via the shared [JhApiClient]
/// transport (bearer header, refresh-on-401, the error envelope).
class JhHttpOrdersApi implements JhOrdersApi {
  JhHttpOrdersApi({JhApiClient? api}) : _api = api ?? JhApiClient();

  final JhApiClient _api;

  @override
  Future<List<JhOrder>> listOrders() async {
    final body = await _api.getList('/api/orders', authenticated: true);
    return body
        .whereType<Map<String, dynamic>>()
        .map(JhOrder.fromJson)
        .toList();
  }

  @override
  Future<JhOrder> createOrder(JhOrderDraft draft) async {
    final fields = _payloadFor(draft);
    final photo = draft.packagePhoto;

    final body = photo == null
        ? await _api.post('/api/orders', fields, authenticated: true)
        : await _api.postMultipart(
            '/api/orders',
            fields: fields.map((key, value) => MapEntry(key, '$value')),
            files: {
              'package_photo': http.MultipartFile.fromBytes(
                'package_photo',
                photo,
                filename: 'package.jpg',
              ),
            },
          );
    return JhOrder.fromJson(body);
  }

  @override
  Future<JhOrder> cancelOrder(String serverId) async {
    final body = await _api.post(
      '/api/orders/$serverId/cancel',
      const {},
      authenticated: true,
    );
    return JhOrder.fromJson(body);
  }

  @override
  Future<JhOrder> rateOrder(String serverId, int stars) async {
    final body = await _api.post(
      '/api/orders/$serverId/rate',
      {'stars': stars},
      authenticated: true,
    );
    return JhOrder.fromJson(body);
  }

  /// Mirrors `orders/serializers.py`'s `OrderCreateSerializer` field-for-field.
  Map<String, dynamic> _payloadFor(JhOrderDraft d) => {
    'vehicle': (d.deliveryMode ?? JhVehicle.motorcycle).apiValue,
    'payment_method': d.paymentMethod.apiValue,
    'pickup_address': d.pickupAddress.trim(),
    'pickup_landmark': d.pickupLandmark.trim(),
    'pickup_instructions': d.pickupInstructions.trim(),
    'pickup_lat': d.pickupLat,
    'pickup_lng': d.pickupLng,
    'dropoff_address': d.dropoffAddress.trim(),
    'dropoff_landmark': d.dropoffLandmark.trim(),
    'dropoff_lat': d.dropoffLat,
    'dropoff_lng': d.dropoffLng,
    'delivery_instructions': d.dropoffInstructions.trim(),
    'recipient_name': d.recipientName.trim(),
    'recipient_phone': d.recipientPhone,
    'package_type': (d.packageType ?? JhPackageType.other).apiValue,
    'package_size': d.packageSize.apiValue,
    'quantity': d.quantity,
    'package_description': d.packageDescription.trim(),
    'handling_instructions': d.handlingInstructions.trim(),
    'declaration_accepted': d.declarationAccepted,
  };
}

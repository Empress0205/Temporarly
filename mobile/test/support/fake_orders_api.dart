import 'dart:typed_data';

import 'package:jihudumie_app/api/api_models.dart';
import 'package:jihudumie_app/orders/order_models.dart';
import 'package:jihudumie_app/orders/orders_api.dart';

/// A scriptable stand-in for the Orders backend, mirroring `FakeAuthApi`.
///
/// The rules -- pricing, cancel/rate eligibility -- now live on the server
/// and are tested there (`backend/orders/tests/test_orders.py`). What this
/// fake checks is different: given a particular server reply, does the app
/// render the right thing and end up in the right state.
///
/// Create/cancel/rate all update [ordersToReturn] in place, the same way a
/// real backend would persist the change -- so a `listOrders()` that follows
/// (the app reloads after most Orders actions) reflects it instead of
/// silently reverting to whatever the test first seeded.
class FakeOrdersApi implements JhOrdersApi {
  /// What `listOrders` returns, and what create/cancel/rate look an order up
  /// in and then update.
  List<JhOrder> ordersToReturn = [];

  /// Overrides what create/cancel/rate return, instead of the default
  /// behaviour above. Useful for shaping exactly one server reply (e.g. a
  /// `photo_url` a fake `Uint8List` echo can't produce on its own).
  JhOrder? result;

  /// Thrown by the next call, then cleared. Set it to drive a failure path.
  JhApiException? failure;

  /// The draft's photo bytes from the last `createOrder` call, if any --
  /// lets a test assert the bytes actually reached the API layer.
  Uint8List? lastPhotoSent;

  /// Every call made, in order, for assertions about what was sent.
  final List<String> calls = <String>[];

  Future<void> _maybeFail() async {
    final pending = failure;
    if (pending != null) {
      failure = null;
      throw pending;
    }
  }

  @override
  Future<List<JhOrder>> listOrders() async {
    calls.add('listOrders');
    await _maybeFail();
    return ordersToReturn;
  }

  @override
  Future<JhOrder> createOrder(JhOrderDraft draft) async {
    calls.add('createOrder');
    await _maybeFail();
    lastPhotoSent = draft.packagePhoto;
    final order = result ??
        JhOrder.fromDraft(
          draft,
          id: 'JHD-20260911-A1B2C',
          serverId: 'srv-new',
          createdAt: DateTime(2026, 9, 11, 9, 41),
        );
    ordersToReturn = [order, ...ordersToReturn];
    return order;
  }

  @override
  Future<JhOrder> cancelOrder(String serverId) async {
    calls.add('cancelOrder:$serverId');
    await _maybeFail();
    final updated = result ??
        ordersToReturn
            .firstWhere((o) => o.serverId == serverId)
            .copyWith(status: JhOrderStatus.cancelled);
    ordersToReturn = [
      for (final o in ordersToReturn)
        if (o.serverId == serverId) updated else o,
    ];
    return updated;
  }

  @override
  Future<JhOrder> rateOrder(String serverId, int stars) async {
    calls.add('rateOrder:$serverId:$stars');
    await _maybeFail();
    final updated = result ??
        ordersToReturn
            .firstWhere((o) => o.serverId == serverId)
            .copyWith(myRating: stars);
    ordersToReturn = [
      for (final o in ordersToReturn)
        if (o.serverId == serverId) updated else o,
    ];
    return updated;
  }
}

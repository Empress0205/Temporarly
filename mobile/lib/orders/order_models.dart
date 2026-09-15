import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show IconData, immutable;

import '../l10n/dict.dart';
import '../theme/icons.dart';

/// The three tabs on My Orders.
enum JhOrderBucket { active, completed, cancelled }

enum JhOrderStatus { inTransit, completed, cancelled }

extension JhOrderStatusX on JhOrderStatus {
  JhOrderBucket get bucket => switch (this) {
    JhOrderStatus.inTransit => JhOrderBucket.active,
    JhOrderStatus.completed => JhOrderBucket.completed,
    JhOrderStatus.cancelled => JhOrderBucket.cancelled,
  };

  String label(JhStrings t) => switch (this) {
    JhOrderStatus.inTransit => t.inTransit,
    JhOrderStatus.completed => t.statusCompleted,
    JhOrderStatus.cancelled => t.statusCancelled,
  };

  /// Matches `OrderStatus` in `backend/orders/models.py`.
  String get apiValue => switch (this) {
    JhOrderStatus.inTransit => 'IN_TRANSIT',
    JhOrderStatus.completed => 'COMPLETED',
    JhOrderStatus.cancelled => 'CANCELLED',
  };

  static JhOrderStatus fromApi(String value) => switch (value) {
    'COMPLETED' => JhOrderStatus.completed,
    'CANCELLED' => JhOrderStatus.cancelled,
    _ => JhOrderStatus.inTransit,
  };
}

enum JhVehicle { motorcycle, bajaji, car, van }

extension JhVehicleX on JhVehicle {
  String label(JhStrings t) => switch (this) {
    JhVehicle.motorcycle => t.vehicleMotorcycle,
    JhVehicle.bajaji => t.vehicleBajaji,
    JhVehicle.car => t.vehicleCar,
    JhVehicle.van => t.vehicleVan,
  };

  String spec(JhStrings t) => switch (this) {
    JhVehicle.motorcycle => t.modeMotoSpec,
    JhVehicle.bajaji => t.modeBajajiSpec,
    JhVehicle.car => t.modeCarSpec,
    JhVehicle.van => t.modeVanSpec,
  };

  String eta(JhStrings t) => switch (this) {
    JhVehicle.motorcycle => t.modeMotoEta,
    JhVehicle.bajaji => t.modeBajajiEta,
    JhVehicle.car => t.modeCarEta,
    JhVehicle.van => t.modeVanEta,
  };

  int get priceTsh => switch (this) {
    JhVehicle.motorcycle => 5000,
    JhVehicle.bajaji => 6500,
    JhVehicle.car => 8000,
    JhVehicle.van => 15000,
  };

  /// All four now have fleet cover -- the backend enforces the same via
  /// `orders/pricing.py`'s `is_available`.
  bool get available => true;

  IconData get icon => switch (this) {
    JhVehicle.motorcycle => JhIcons.motorcycle,
    JhVehicle.bajaji => JhIcons.bajaji,
    JhVehicle.car => JhIcons.car,
    JhVehicle.van => JhIcons.van,
  };

  /// Matches `Vehicle` in `backend/orders/models.py`.
  String get apiValue => switch (this) {
    JhVehicle.motorcycle => 'MOTORCYCLE',
    JhVehicle.bajaji => 'BAJAJI',
    JhVehicle.car => 'CAR',
    JhVehicle.van => 'VAN',
  };

  static JhVehicle fromApi(String value) => switch (value) {
    'BAJAJI' => JhVehicle.bajaji,
    'CAR' => JhVehicle.car,
    'VAN' => JhVehicle.van,
    _ => JhVehicle.motorcycle,
  };
}

/// The only method the mockups show is settle-on-delivery; the enum leaves
/// room for mobile money / card later.
enum JhPaymentMethod { payAfterDelivery }

extension JhPaymentMethodX on JhPaymentMethod {
  String label(JhStrings t) => switch (this) {
    JhPaymentMethod.payAfterDelivery => t.payAfterDelivery,
  };

  /// Matches `PaymentMethod` in `backend/orders/models.py`.
  String get apiValue => switch (this) {
    JhPaymentMethod.payAfterDelivery => 'PAY_AFTER_DELIVERY',
  };

  static JhPaymentMethod fromApi(String value) =>
      JhPaymentMethod.payAfterDelivery;
}

enum JhPackageType { documents, clothes, food, electronics, household, other }

extension JhPackageTypeX on JhPackageType {
  String label(JhStrings t) => switch (this) {
    JhPackageType.documents => t.pkgDocuments,
    JhPackageType.clothes => t.pkgClothes,
    JhPackageType.food => t.pkgFood,
    JhPackageType.electronics => t.pkgElectronics,
    JhPackageType.household => t.pkgHousehold,
    JhPackageType.other => t.pkgOther,
  };

  IconData get icon => switch (this) {
    JhPackageType.documents => JhIcons.pkgDocuments,
    JhPackageType.clothes => JhIcons.pkgClothes,
    JhPackageType.food => JhIcons.pkgFood,
    JhPackageType.electronics => JhIcons.pkgElectronics,
    JhPackageType.household => JhIcons.pkgHousehold,
    JhPackageType.other => JhIcons.pkgOther,
  };

  /// Matches `PackageType` in `backend/orders/models.py`.
  String get apiValue => switch (this) {
    JhPackageType.documents => 'DOCUMENTS',
    JhPackageType.clothes => 'CLOTHES',
    JhPackageType.food => 'FOOD',
    JhPackageType.electronics => 'ELECTRONICS',
    JhPackageType.household => 'HOUSEHOLD',
    JhPackageType.other => 'OTHER',
  };

  static JhPackageType fromApi(String value) => switch (value) {
    'DOCUMENTS' => JhPackageType.documents,
    'CLOTHES' => JhPackageType.clothes,
    'FOOD' => JhPackageType.food,
    'ELECTRONICS' => JhPackageType.electronics,
    'HOUSEHOLD' => JhPackageType.household,
    _ => JhPackageType.other,
  };
}

enum JhPackageSize { small, medium, large }

extension JhPackageSizeX on JhPackageSize {
  String label(JhStrings t) => switch (this) {
    JhPackageSize.small => t.sizeSmall,
    JhPackageSize.medium => t.sizeMedium,
    JhPackageSize.large => t.sizeLarge,
  };

  String sub(JhStrings t) => switch (this) {
    JhPackageSize.small => t.sizeSmallSub,
    JhPackageSize.medium => t.sizeMediumSub,
    JhPackageSize.large => t.sizeLargeSub,
  };

  /// Matches `PackageSize` in `backend/orders/models.py`.
  String get apiValue => switch (this) {
    JhPackageSize.small => 'SMALL',
    JhPackageSize.medium => 'MEDIUM',
    JhPackageSize.large => 'LARGE',
  };

  static JhPackageSize fromApi(String value) => switch (value) {
    'MEDIUM' => JhPackageSize.medium,
    'LARGE' => JhPackageSize.large,
    _ => JhPackageSize.small,
  };
}

/// How far a placed order has got. Drives the tracking screen's step rail and
/// timeline.
enum JhTrackingStage {
  requestCreated,
  driverAssigned,
  driverArriving,
  pickedUp,
  delivered,
}

extension JhTrackingStageX on JhTrackingStage {
  int get index => JhTrackingStage.values.indexOf(this);

  String label(JhStrings t) => switch (this) {
    JhTrackingStage.requestCreated => t.trackFindingDriver,
    JhTrackingStage.driverAssigned => t.trackDriverAssigned,
    JhTrackingStage.driverArriving => t.trackDriverArriving,
    JhTrackingStage.pickedUp => t.trackPickedUp,
    JhTrackingStage.delivered => t.trackDelivered,
  };

  /// Matches `TrackingStage` in `backend/orders/models.py`.
  String get apiValue => switch (this) {
    JhTrackingStage.requestCreated => 'REQUEST_CREATED',
    JhTrackingStage.driverAssigned => 'DRIVER_ASSIGNED',
    JhTrackingStage.driverArriving => 'DRIVER_ARRIVING',
    JhTrackingStage.pickedUp => 'PICKED_UP',
    JhTrackingStage.delivered => 'DELIVERED',
  };

  static JhTrackingStage fromApi(String value) => switch (value) {
    'DRIVER_ASSIGNED' => JhTrackingStage.driverAssigned,
    'DRIVER_ARRIVING' => JhTrackingStage.driverArriving,
    'PICKED_UP' => JhTrackingStage.pickedUp,
    'DELIVERED' => JhTrackingStage.delivered,
    _ => JhTrackingStage.requestCreated,
  };
}

@immutable
class JhDriver {
  const JhDriver({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.plate,
  });

  final String name;
  final double rating;
  final JhVehicle vehicle;
  final String plate;

  factory JhDriver.fromJson(Map<String, dynamic> json) => JhDriver(
    name: json['name'] as String? ?? '',
    rating: double.tryParse('${json['rating']}') ?? 5.0,
    vehicle: JhVehicleX.fromApi(json['vehicle'] as String? ?? ''),
    plate: json['plate'] as String? ?? '',
  );

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

/// Shown where a real route has not been captured.
const String kNoRoute = '—';

@immutable
class JhOrder {
  const JhOrder({
    required this.id,
    required this.serverId,
    required this.pickupArea,
    required this.dropoffArea,
    required this.status,
    required this.stage,
    required this.vehicle,
    required this.priceTsh,
    required this.paid,
    required this.paymentMethod,
    required this.createdAt,
    required this.recipientName,
    required this.recipientPhone,
    required this.packageType,
    required this.packageSize,
    required this.quantity,
    required this.pickupAddress,
    required this.pickupLandmark,
    required this.pickupInstructions,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLandmark,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.deliveryInstructions,
    required this.packageDescription,
    required this.handlingInstructions,
    this.driver,
    this.myRating,
    this.packagePhotoUrl,
  });

  final String id;

  /// The backend's UUID -- what `cancel`/`rate` call by. [id] stays the
  /// human-readable order number shown everywhere in the UI.
  final String serverId;
  final String pickupArea;
  final String dropoffArea;
  final JhOrderStatus status;
  final JhTrackingStage stage;
  final JhVehicle vehicle;
  final int priceTsh;
  final bool paid;
  final JhPaymentMethod paymentMethod;
  final DateTime createdAt;

  final String recipientName;
  final String recipientPhone;
  final JhPackageType packageType;
  final JhPackageSize packageSize;
  final int quantity;
  final String pickupAddress;
  final String pickupLandmark;
  final String pickupInstructions;
  final double? pickupLat;
  final double? pickupLng;
  final String dropoffAddress;
  final String dropoffLandmark;
  final double? dropoffLat;
  final double? dropoffLng;
  final String deliveryInstructions;
  final String packageDescription;
  final String handlingInstructions;

  final JhDriver? driver;

  /// 1-5 stars the customer left after delivery. Null until they rate it.
  final int? myRating;

  /// Wherever the server is hosting the parcel photo, or null when none was
  /// attached. A committed order's photo is always a URL, never bytes -- the
  /// bytes only exist transiently on `JhOrderDraft` before the order exists.
  final String? packagePhotoUrl;

  bool get hasRoute => dropoffArea.isNotEmpty && dropoffArea != kNoRoute;

  double? get routeKm => haversineKm(
    pickupLat,
    pickupLng,
    dropoffLat,
    dropoffLng,
  );

  /// Same order, with [status] and/or [myRating] replaced. Used for
  /// cancelling and rating -- the rest of the record never changes.
  JhOrder copyWith({JhOrderStatus? status, int? myRating}) => JhOrder(
    id: id,
    serverId: serverId,
    pickupArea: pickupArea,
    dropoffArea: dropoffArea,
    status: status ?? this.status,
    stage: stage,
    vehicle: vehicle,
    priceTsh: priceTsh,
    paid: paid,
    paymentMethod: paymentMethod,
    createdAt: createdAt,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
    packageType: packageType,
    packageSize: packageSize,
    quantity: quantity,
    pickupAddress: pickupAddress,
    pickupLandmark: pickupLandmark,
    pickupInstructions: pickupInstructions,
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    dropoffAddress: dropoffAddress,
    dropoffLandmark: dropoffLandmark,
    dropoffLat: dropoffLat,
    dropoffLng: dropoffLng,
    deliveryInstructions: deliveryInstructions,
    packageDescription: packageDescription,
    handlingInstructions: handlingInstructions,
    driver: driver,
    myRating: myRating ?? this.myRating,
    packagePhotoUrl: packagePhotoUrl,
  );

  /// The draft→field mapping, still exercised by a unit test even though
  /// `_commitOrder` talks to the real API now rather than calling this
  /// directly. [serverId] has no real backend counterpart here, so it
  /// defaults to [id].
  factory JhOrder.fromDraft(
    JhOrderDraft d, {
    required String id,
    required DateTime createdAt,
    String? serverId,
  }) {
    final vehicle = d.deliveryMode ?? JhVehicle.motorcycle;
    return JhOrder(
      id: id,
      serverId: serverId ?? id,
      createdAt: createdAt,
      pickupArea: _firstSegment(d.pickupAddress),
      dropoffArea: _firstSegment(d.dropoffAddress),
      status: JhOrderStatus.inTransit,
      stage: JhTrackingStage.requestCreated,
      vehicle: vehicle,
      priceTsh: vehicle.priceTsh,
      paid: false,
      paymentMethod: d.paymentMethod,
      recipientName: d.recipientName.trim(),
      recipientPhone: d.recipientPhone,
      packageType: d.packageType ?? JhPackageType.other,
      packageSize: d.packageSize,
      quantity: d.quantity,
      pickupAddress: d.pickupAddress.trim(),
      pickupLandmark: d.pickupLandmark.trim(),
      pickupInstructions: d.pickupInstructions.trim(),
      pickupLat: d.pickupLat,
      pickupLng: d.pickupLng,
      dropoffAddress: d.dropoffAddress.trim(),
      dropoffLandmark: d.dropoffLandmark.trim(),
      dropoffLat: d.dropoffLat,
      dropoffLng: d.dropoffLng,
      deliveryInstructions: d.dropoffInstructions.trim(),
      packageDescription: d.packageDescription.trim(),
      handlingInstructions: d.handlingInstructions.trim(),
    );
  }

  /// Parses one order out of `GET/POST /api/orders` (`orders/serializers.py`
  /// `OrderSerializer` on the backend).
  factory JhOrder.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'];
    return JhOrder(
      id: json['order_number'] as String? ?? '',
      serverId: json['id'] as String? ?? '',
      pickupArea: _firstSegment(json['pickup_address'] as String? ?? ''),
      dropoffArea: _firstSegment(json['dropoff_address'] as String? ?? ''),
      status: JhOrderStatusX.fromApi(json['status'] as String? ?? ''),
      stage: JhTrackingStageX.fromApi(json['stage'] as String? ?? ''),
      vehicle: JhVehicleX.fromApi(json['vehicle'] as String? ?? ''),
      priceTsh: (json['price_tsh'] as num?)?.toInt() ?? 0,
      paid: json['paid'] as bool? ?? false,
      paymentMethod: JhPaymentMethodX.fromApi(
        json['payment_method'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      recipientName: json['recipient_name'] as String? ?? '',
      recipientPhone: json['recipient_phone'] as String? ?? '',
      packageType: JhPackageTypeX.fromApi(json['package_type'] as String? ?? ''),
      packageSize: JhPackageSizeX.fromApi(json['package_size'] as String? ?? ''),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLandmark: json['pickup_landmark'] as String? ?? '',
      pickupInstructions: json['pickup_instructions'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
      dropoffAddress: json['dropoff_address'] as String? ?? '',
      dropoffLandmark: json['dropoff_landmark'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
      deliveryInstructions: json['delivery_instructions'] as String? ?? '',
      packageDescription: json['package_description'] as String? ?? '',
      handlingInstructions: json['handling_instructions'] as String? ?? '',
      driver: driverJson is Map<String, dynamic>
          ? JhDriver.fromJson(driverJson)
          : null,
      myRating: (json['my_rating'] as num?)?.toInt(),
      packagePhotoUrl: json['photo_url'] as String?,
    );
  }

  static String _firstSegment(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return kNoRoute;
    return trimmed.split(RegExp(r'[,\n]')).first.trim();
  }
}

/// Mutable working copy of a Send a Package submission, replaced with a fresh
/// instance each time the wizard starts.
class JhOrderDraft {
  double? pickupLat;
  double? pickupLng;
  String pickupAddress = '';
  String pickupLandmark = '';
  String pickupInstructions = '';

  String recipientName = '';
  String recipientPhone = '';

  JhPackageType? packageType;
  JhPackageSize packageSize = JhPackageSize.small;
  int quantity = 1;
  String packageDescription = '';
  String handlingInstructions = '';
  bool declarationAccepted = false;

  /// Optional photo taken at the Package step. Bytes only, never persisted.
  Uint8List? packagePhoto;

  double? dropoffLat;
  double? dropoffLng;
  String dropoffAddress = '';
  String dropoffLandmark = '';
  String dropoffInstructions = '';

  JhVehicle? deliveryMode;
  JhPaymentMethod paymentMethod = JhPaymentMethod.payAfterDelivery;

  bool get hasPickup =>
      pickupAddress.trim().isNotEmpty ||
      (pickupLat != null && pickupLng != null);

  bool get hasDropoff =>
      dropoffAddress.trim().isNotEmpty ||
      (dropoffLat != null && dropoffLng != null);

  double? get routeKm =>
      haversineKm(pickupLat, pickupLng, dropoffLat, dropoffLng);

  /// Prefills a fresh draft from a past order -- powers "Reorder". The
  /// declaration is accepted up front: the customer already agreed to it once
  /// for this same package.
  static JhOrderDraft fromOrder(JhOrder order) => JhOrderDraft()
    ..pickupLat = order.pickupLat
    ..pickupLng = order.pickupLng
    ..pickupAddress = order.pickupAddress
    ..pickupLandmark = order.pickupLandmark
    ..pickupInstructions = order.pickupInstructions
    ..recipientName = order.recipientName
    ..recipientPhone = order.recipientPhone
    ..packageType = order.packageType
    ..packageSize = order.packageSize
    ..quantity = order.quantity
    ..packageDescription = order.packageDescription
    ..handlingInstructions = order.handlingInstructions
    ..declarationAccepted = true
    // Not carried forward: a committed order's photo is a URL the server
    // hosts, not bytes the client still has -- reordering starts without one.
    ..dropoffLat = order.dropoffLat
    ..dropoffLng = order.dropoffLng
    ..dropoffAddress = order.dropoffAddress
    ..dropoffLandmark = order.dropoffLandmark
    ..dropoffInstructions = order.deliveryInstructions
    ..deliveryMode = order.vehicle
    ..paymentMethod = order.paymentMethod;
}

/// Great-circle distance in kilometres, or null if either point is missing.
double? haversineKm(double? lat1, double? lng1, double? lat2, double? lng2) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const earthKm = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../orders/order_models.dart';
import '../orders/widgets/jh_pickup_map.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// Track Package — the live-ish status of a placed order: where it is, who is
/// carrying it, and a timeline. Driver and timings are sample data until the
/// backend exists.
class JhOrderDetailScreen extends StatelessWidget {
  const JhOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final order = state.selectedOrder;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    if (order == null) return const SizedBox.shrink();

    final start = (order.pickupLat != null && order.pickupLng != null)
        ? LatLng(order.pickupLat!, order.pickupLng!)
        : null;
    final end = (order.dropoffLat != null && order.dropoffLng != null)
        ? LatLng(order.dropoffLat!, order.dropoffLng!)
        : null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: JhColors.surface,
          padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JhRoundBackButton(onPressed: state.back),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.trackPackageTitle,
                      style: JhText.ui(
                        size: 17,
                        weight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: JhColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.id,
                      style: JhText.mono(
                        size: 11,
                        weight: FontWeight.w500,
                        color: JhColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const JhScrollBehavior(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusPill(label: order.stage.label(t)),
                  const SizedBox(height: 14),
                  JhPickupMap(
                    live: state.liveMap,
                    center: start,
                    routeEnd: end,
                    height: 190,
                    caption: '${order.pickupArea} → ${order.dropoffArea}',
                  ),
                  const SizedBox(height: 14),
                  _StageRail(current: order.stage, t: t),
                  if (order.driver != null) ...[
                    const SizedBox(height: 16),
                    _DriverCard(driver: order.driver!, t: t),
                  ],
                  const SizedBox(height: 16),
                  _DeliveryDetailsCard(order: order, t: t),
                  const SizedBox(height: 22),
                  Text(
                    t.deliveryTimelineTitle,
                    style: JhText.ui(size: 15, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _Timeline(order: order, t: t),
                  if (order.status == JhOrderStatus.completed) ...[
                    const SizedBox(height: 16),
                    _ProofOfDelivery(order: order, t: t),
                    const SizedBox(height: 16),
                    _RatingCard(order: order, state: state, t: t),
                  ],
                  const SizedBox(height: 22),
                  if (state.canCancelOrder)
                    JhDangerButton(
                      label: t.cancelOrderCta,
                      onPressed: state.askCancelOrder,
                    )
                  else if (order.status == JhOrderStatus.inTransit)
                    JhSecondaryButton(
                      label: t.contactSupport,
                      onPressed: () => state.showComingSoon(t.contactSupport),
                    )
                  else
                    JhSecondaryButton(
                      label: t.reorder,
                      onPressed: () => state.reorderFrom(order),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: JhColors.primaryTint,
        borderRadius: BorderRadius.circular(JhRadii.control),
      ),
      child: Row(
        children: [
          const Icon(
            JhIcons.timeline,
            size: 16,
            color: JhColors.primaryText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: JhText.ui(
              size: 13,
              weight: FontWeight.w800,
              color: JhColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageRail extends StatelessWidget {
  const _StageRail({required this.current, required this.t});

  final JhTrackingStage current;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final stage in JhTrackingStage.values) ...[
            if (stage.index > 0)
              Container(
                width: 18,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: stage.index <= current.index
                    ? JhColors.primary
                    : JhColors.cardBorder,
              ),
            _StageChip(
              label: stage.label(t),
              done: stage.index < current.index,
              active: stage.index == current.index,
            ),
          ],
        ],
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final on = done || active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? JhColors.primaryText
            : (done ? JhColors.primaryTint : JhColors.surfaceMuted),
        borderRadius: BorderRadius.circular(JhRadii.pill),
      ),
      child: Text(
        label,
        style: JhText.ui(
          size: 11,
          weight: FontWeight.w700,
          color: active
              ? JhColors.onDark
              : (on ? JhColors.primaryText : JhColors.textMuted),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.t});

  final JhDriver driver;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.primaryText,
              shape: BoxShape.circle,
            ),
            child: Text(
              driver.initials,
              style: JhText.ui(
                size: 15,
                weight: FontWeight.w800,
                color: JhColors.onDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: JhText.ui(size: 14.5, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      JhIcons.star,
                      size: 13,
                      color: JhColors.accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      driver.rating.toStringAsFixed(1),
                      style: JhText.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: JhColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      driver.vehicle.icon,
                      size: 13,
                      color: JhColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      driver.vehicle.label(t),
                      style: JhText.ui(
                        size: 12,
                        weight: FontWeight.w500,
                        color: JhColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  driver.plate,
                  style: JhText.mono(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: JhColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Calling the driver is the one real action on this card -- it gets
          // the accent colour, not red (which this screen reserves for
          // cancel/danger elsewhere and shouldn't mean "call").
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.primaryText,
              shape: BoxShape.circle,
            ),
            child: const Icon(JhIcons.call, size: 18, color: JhColors.onDark),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order, required this.t});

  final JhOrder order;
  final dynamic t;

  static const _offsets = [0, 3, 8, 15, 40]; // minutes past createdAt

  @override
  Widget build(BuildContext context) {
    final stages = JhTrackingStage.values;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final stage in stages)
            _Entry(
              label: _timelineLabel(stage),
              time: stage.index <= order.stage.index
                  ? _fmt(order.createdAt.add(
                      Duration(minutes: _offsets[stage.index]),
                    ))
                  : null,
              done: stage.index < order.stage.index,
              active: stage.index == order.stage.index,
              last: stage == stages.last,
            ),
        ],
      ),
    );
  }

  String _timelineLabel(JhTrackingStage stage) => switch (stage) {
    JhTrackingStage.requestCreated => t.trackRequestCreated,
    JhTrackingStage.driverAssigned => t.trackDriverAssigned,
    JhTrackingStage.driverArriving => t.trackDriverArriving,
    JhTrackingStage.pickedUp => t.trackPickedUp,
    JhTrackingStage.delivered => t.trackDelivered,
  };

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Who it's for and any note left at drop-off -- absent from the tracking
/// screen until now, so a customer deciding whether to cancel or call support
/// could not actually see what they were tracking.
class _DeliveryDetailsCard extends StatelessWidget {
  const _DeliveryDetailsCard({required this.order, required this.t});

  final JhOrder order;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.deliveryDetailsTitle.toUpperCase(),
            style: JhText.ui(
              size: 10.5,
              weight: FontWeight.w800,
              letterSpacing: 0.6,
              color: JhColors.textFaint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                JhIcons.recipient,
                size: 15,
                color: JhColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.recipientPhone.isEmpty
                      ? order.recipientName
                      : '${order.recipientName}  ·  +255 ${order.recipientPhone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(size: 13, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (order.deliveryInstructions.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${t.deliveryNoteLabel}: ${order.deliveryInstructions.trim()}',
              style: JhText.ui(
                size: 12.5,
                weight: FontWeight.w500,
                color: JhColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
          if (order.packagePhotoUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(JhRadii.control),
              child: Image.network(
                order.packagePhotoUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                // A broken/unreachable image must not take the tracking
                // screen down with it -- and this is what keeps it safe in
                // widget tests too, which have no network to actually load
                // from.
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: JhColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(
                    JhIcons.parcel,
                    size: 24,
                    color: JhColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown once an order reaches [JhTrackingStage.delivered]. There is no
/// driver-side app to capture a real signature/OTP yet, so this stands in as
/// a label on the record rather than a captured event.
class _ProofOfDelivery extends StatelessWidget {
  const _ProofOfDelivery({required this.order, required this.t});

  final JhOrder order;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: JhColors.primaryTint,
        borderRadius: BorderRadius.circular(JhRadii.control),
      ),
      child: Row(
        children: [
          const Icon(
            JhIcons.verified,
            size: 18,
            color: JhColors.primaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.proofOfDeliveryTitle,
                  style: JhText.ui(
                    size: 13,
                    weight: FontWeight.w800,
                    color: JhColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.receivedByLabel} ${order.recipientName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: JhColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rates the driver once, locally -- there is nowhere on a server to send it
/// to yet, but it closes the loop for the customer.
class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.order,
    required this.state,
    required this.t,
  });

  final JhOrder order;
  final JhAppState state;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    final rating = order.myRating;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating == null ? t.rateDriverTitle : t.youRatedThisDelivery,
            style: JhText.ui(size: 14, weight: FontWeight.w800),
          ),
          if (rating == null) ...[
            const SizedBox(height: 2),
            Text(
              t.rateDriverSub,
              style: JhText.ui(
                size: 12,
                weight: FontWeight.w500,
                color: JhColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Semantics(
                    button: rating == null,
                    label: '$i/5',
                    child: GestureDetector(
                      key: ValueKey('rateStar$i'),
                      onTap: rating == null
                          ? () => state.rateOrder(order, i)
                          : null,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        JhIcons.star,
                        size: 26,
                        color: i <= (rating ?? 0)
                            ? JhColors.accent
                            : JhColors.cardBorder,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.label,
    required this.time,
    required this.done,
    required this.active,
    required this.last,
  });

  final String label;
  final String? time;
  final bool done;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final on = done || active;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done
                      ? JhColors.primary
                      : (active ? JhColors.surface : JhColors.surfaceMuted),
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(color: JhColors.primary, width: 2)
                      : null,
                ),
                child: done
                    ? const Icon(
                        JhIcons.check,
                        size: 11,
                        color: JhColors.onDark,
                      )
                    : active
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: JhColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? JhColors.primary : JhColors.cardBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: JhText.ui(
                    size: 13,
                    weight: on ? FontWeight.w800 : FontWeight.w500,
                    color: on ? JhColors.ink : JhColors.textMuted,
                  ),
                ),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    time!,
                    style: JhText.mono(
                      size: 11,
                      weight: FontWeight.w500,
                      color: JhColors.textFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

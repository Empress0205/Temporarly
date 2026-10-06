import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../orders/money.dart';
import '../orders/order_models.dart';
import '../orders/widgets/jh_pickup_map.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// Track Package — a map behind a floating header, and a sheet that rises
/// from the bottom carrying the status, the driver and the timeline.
///
/// The mockup this follows shows a live "12 min" countdown and a timestamp
/// on every stage. Neither is real yet: there's no driver-location feed to
/// compute an ETA from, and the backend only ever records the *current*
/// stage, not when each earlier one happened. So the headline number is the
/// route's real distance instead of an invented ETA, and only the stages we
/// actually have a timestamp for (the order's creation, and whichever stage
/// it's in right now) show one — see `_TrackingSheet` and `_Timeline`.
class JhOrderDetailScreen extends StatelessWidget {
  const JhOrderDetailScreen({super.key});

  static const _mapHeight = 340.0;

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final order = state.selectedOrder;

    if (order == null) return const SizedBox.shrink();

    final start = (order.pickupLat != null && order.pickupLng != null)
        ? LatLng(order.pickupLat!, order.pickupLng!)
        : null;
    final end = (order.dropoffLat != null && order.dropoffLng != null)
        ? LatLng(order.dropoffLat!, order.dropoffLng!)
        : null;

    // The map and the sheet are plain, non-overlapping Column siblings now,
    // not two Positioned boxes sharing a strip of the screen -- only the
    // header floats (Stack) over the map itself. A scrollable sheet stacked
    // to overlap a sibling was letting scrolled-past content paint over the
    // map on this build/engine combination; siblings that never share a
    // pixel of screen space can't have that problem regardless of the cause.
    return DecoratedBox(
      decoration: const BoxDecoration(color: JhColors.surface),
      child: Column(
        children: [
          SizedBox(
            height: _mapHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: JhPickupMap(
                    live: state.liveMap,
                    center: start,
                    routeEnd: end,
                    height: _mapHeight,
                    caption: '${order.pickupArea} → ${order.dropoffArea}',
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _FloatingHeader(
                        order: order,
                        t: t,
                        onBack: state.back,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _TrackingSheet(order: order, state: state, t: t),
          ),
        ],
      ),
    );
  }
}

class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({
    required this.order,
    required this.t,
    required this.onBack,
  });

  final JhOrder order;
  final dynamic t;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.sheet),
        boxShadow: JhShadows.card,
      ),
      child: Row(
        children: [
          JhRoundBackButton(onPressed: onBack),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.trackPackageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(
                    size: 15,
                    weight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: JhColors.ink,
                  ),
                ),
                Text(
                  '${order.id} · ${order.vehicle.label(t)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.mono(
                    size: 10.5,
                    weight: FontWeight.w500,
                    color: JhColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({
    required this.order,
    required this.state,
    required this.t,
  });

  final JhOrder order;
  final JhAppState state;
  final dynamic t;

  static final _topRadius = BorderRadius.vertical(
    top: Radius.circular(JhRadii.sheet),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: _topRadius,
        boxShadow: JhShadows.card,
      ),
      child: ClipRRect(
        borderRadius: _topRadius,
        child: ScrollConfiguration(
          behavior: const JhScrollBehavior(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: JhColors.cardBorder,
                      borderRadius: BorderRadius.circular(JhRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _StatusRow(order: order, t: t),
                const SizedBox(height: 16),
                _ProgressBar(current: order.stage),
                const SizedBox(height: 20),
                _Timeline(order: order, t: t),
                if (order.driver != null) ...[
                  const SizedBox(height: 16),
                  _DriverRow(driver: order.driver!, t: t),
                ],
                const SizedBox(height: 36),
                _Actions(order: order, state: state, t: t),
                if (order.status == JhOrderStatus.completed) ...[
                  const SizedBox(height: 16),
                  _ProofOfDelivery(order: order, t: t),
                  const SizedBox(height: 16),
                  _RatingCard(order: order, state: state, t: t),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The stage name (real) on the left, next to the route's actual distance
/// (real) where the mockup had a live ETA countdown (not something we have),
/// and the fare (real) on the right.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.order, required this.t});

  final JhOrder order;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    final km = order.routeKm;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.stage.label(t).toUpperCase(),
                style: JhText.ui(
                  size: 11,
                  weight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: JhColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              if (km != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      km.toStringAsFixed(0),
                      style: JhText.ui(
                        size: 34,
                        weight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.kmUnit,
                      style: JhText.ui(
                        size: 14,
                        weight: FontWeight.w700,
                        color: JhColors.textMuted,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  order.dropoffArea,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(size: 22, weight: FontWeight.w800),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              t.estimateFee.toUpperCase(),
              style: JhText.ui(
                size: 10.5,
                weight: FontWeight.w800,
                letterSpacing: 0.6,
                color: JhColors.textFaint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${t.tshPrefix} ${jhMoney(order.priceTsh)}',
              style: JhText.ui(size: 16, weight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }
}

/// A segmented line rather than the old row of text chips -- each stage is
/// one block, filled up to and including the current one.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current});

  final JhTrackingStage current;

  @override
  Widget build(BuildContext context) {
    final stages = JhTrackingStage.values;
    return Row(
      children: [
        for (final stage in stages) ...[
          if (stage.index > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: stage.index <= current.index
                    ? JhColors.primary
                    : JhColors.cardBorder,
                borderRadius: BorderRadius.circular(JhRadii.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Only ever shows a time where one is real: the order's creation, and the
/// stage it's in right now (`updatedAt` -- the backend only stores the
/// current stage, so that's the one moment we can actually date). Every
/// other stage shows no time rather than a plausible-looking guess.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order, required this.t});

  final JhOrder order;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    final stages = JhTrackingStage.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in stages)
          _Entry(
            label: stage.label(t),
            time: switch (stage) {
              JhTrackingStage.requestCreated => _fmt(order.createdAt),
              _ when stage == order.stage => _fmt(order.updatedAt),
              _ => null,
            },
            done: stage.index < order.stage.index,
            active: stage.index == order.stage.index,
            last: stage == stages.last,
          ),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver, required this.t});

  final JhDriver driver;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: JhColors.surfaceMuted,
        borderRadius: BorderRadius.circular(JhRadii.card),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.primaryText,
              shape: BoxShape.circle,
            ),
            child: Text(
              driver.initials,
              style: JhText.ui(
                size: 14,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(size: 14, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(JhIcons.star, size: 12, color: JhColors.accent),
                    const SizedBox(width: 3),
                    // One flexible, ellipsising run rather than several fixed
                    // Text widgets plus one Flexible at the end -- a long
                    // vehicle name alone could already overflow the row
                    // before the plate ever got a chance to shrink.
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: driver.rating.toStringAsFixed(1),
                              style: JhText.ui(
                                size: 11.5,
                                weight: FontWeight.w700,
                                color: JhColors.primaryText,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  ·  ${driver.vehicle.label(t)}  ·  ${driver.plate}',
                              style: JhText.ui(
                                size: 11.5,
                                weight: FontWeight.w500,
                                color: JhColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Calling the driver is the one real action on this card -- it
          // gets the accent colour, not red (which this screen reserves for
          // cancel/danger elsewhere and shouldn't mean "call").
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.primaryText,
              shape: BoxShape.circle,
            ),
            child: const Icon(JhIcons.call, size: 17, color: JhColors.onDark),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order, required this.state, required this.t});

  final JhOrder order;
  final JhAppState state;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    if (state.canCancelOrder) {
      return JhDangerButton(
        label: t.cancelOrderCta,
        onPressed: state.askCancelOrder,
      );
    }
    if (order.status != JhOrderStatus.inTransit) {
      return JhSecondaryButton(
        label: t.reorder,
        onPressed: () => state.reorderFrom(order),
      );
    }
    // In transit but past the point cancel is offered: Support alongside
    // Share trip, matching the mockup, rather than Support alone.
    return Row(
      children: [
        Expanded(
          child: _PillButton(
            label: t.contactSupport,
            onPressed: () => state.showComingSoon(t.contactSupport),
            background: JhColors.surfaceMuted,
            labelColor: JhColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PillButton(
            label: t.shareTrip,
            onPressed: () => state.showComingSoon(t.shareTrip),
            background: JhColors.brandCharcoal,
            labelColor: JhColors.onDark,
          ),
        ),
      ],
    );
  }
}

/// A fully-rounded (capsule) flat action, no border -- matches the mockup's
/// Support/Share trip pair. Share trip isn't a brand action (that's orange)
/// and isn't a warning (that's red), so it's charcoal; Support is a flat
/// neutral tile rather than an outlined button.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.labelColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color labelColor;

  static const _height = 54.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: JhText.ui(size: 15, weight: FontWeight.w800, color: labelColor),
          ),
        ),
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
          const Icon(JhIcons.verified, size: 18, color: JhColors.primaryText),
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

import 'package:flutter/widgets.dart';

import '../../l10n/dict.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../money.dart';
import '../order_models.dart';
import 'jh_status_badge.dart';

class JhOrderCard extends StatelessWidget {
  const JhOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.t,
  });

  final JhOrder order;
  final VoidCallback onTap;
  final JhStrings t;

  @override
  Widget build(BuildContext context) {
    final price = '${t.tshPrefix} ${jhMoney(order.priceTsh)}';
    final route = order.hasRoute
        ? '${order.pickupArea} → ${order.dropoffArea}'
        : order.pickupArea;

    return Semantics(
      button: true,
      label: '${order.id}. $route. ${order.status.label(t)}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.card),
            boxShadow: JhShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.id,
                      style: JhText.mono(
                        size: 11.5,
                        weight: FontWeight.w500,
                        color: JhColors.textMuted,
                      ),
                    ),
                  ),
                  JhStatusBadge(status: order.status, t: t),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                route,
                style: JhText.ui(
                  size: 15.5,
                  weight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(order.vehicle.icon, size: 15, color: JhColors.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: JhText.ui(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: JhColors.textMuted,
                        ),
                        children: [
                          TextSpan(text: '${order.vehicle.label(t)}  ·  '),
                          TextSpan(
                            text: price,
                            style: JhText.mono(
                              size: 12.5,
                              color: JhColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.paid) ...[
                    const SizedBox(width: 8),
                    _PaidChip(label: t.orderPaid),
                  ],
                  if (order.myRating != null) ...[
                    const SizedBox(width: 8),
                    _RatingChip(rating: order.myRating!),
                  ],
                ],
              ),
              if (order.status == JhOrderStatus.inTransit) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: JhColors.primaryTint,
                    borderRadius: BorderRadius.circular(JhRadii.control),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        JhIcons.timeline,
                        size: 15,
                        color: JhColors.primaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.orderTapToTrack,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JhText.ui(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: JhColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: JhColors.wash(JhColors.accent),
        borderRadius: BorderRadius.circular(JhRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(JhIcons.star, size: 11, color: JhColors.accent),
          const SizedBox(width: 3),
          Text(
            '$rating',
            style: JhText.ui(
              size: 10.5,
              weight: FontWeight.w800,
              color: JhColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidChip extends StatelessWidget {
  const _PaidChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: JhColors.primaryTint,
        borderRadius: BorderRadius.circular(JhRadii.pill),
      ),
      child: Text(
        label,
        style: JhText.ui(
          size: 10.5,
          weight: FontWeight.w800,
          color: JhColors.primaryText,
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../orders/money.dart';
import '../orders/order_models.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// Shown the moment an order is committed. Confirmation, a summary, and the
/// way into tracking.
class JhOrderCreatedScreen extends StatelessWidget {
  const JhOrderCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final order = state.selectedOrder;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    if (order == null) return const SizedBox.shrink();

    final route = order.hasRoute
        ? [order.pickupArea, order.dropoffArea]
        : [order.pickupArea, '—'];

    return JhAuthScaffold(
      toastVisible: state.toast.isNotEmpty,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
      header: SizedBox(height: topInset + 12),
      body: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(JhIcons.check, size: 34, color: JhColors.onDark),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t.orderCreatedTitle,
          textAlign: TextAlign.center,
          style: JhText.ui(
            size: 22,
            weight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.orderCreatedSub,
          textAlign: TextAlign.center,
          style: JhText.ui(
            size: 13.5,
            weight: FontWeight.w500,
            color: JhColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.card),
            boxShadow: JhShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.deliverySummaryTitle.toUpperCase(),
                style: JhText.ui(
                  size: 10.5,
                  weight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: JhColors.textFaint,
                ),
              ),
              const SizedBox(height: 10),
              Text(order.id, style: JhText.mono(size: 13, color: JhColors.primaryText)),
              const SizedBox(height: 10),
              _Line(label: t.estimateFrom, value: route[0]),
              _Line(label: t.estimateTo, value: route[1]),
              _Line(
                label: t.summaryFee,
                value: '${t.tshPrefix} ${jhMoney(order.priceTsh)}',
              ),
              _Line(
                label: t.summaryPayment,
                value: order.paymentMethod.label(t),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: JhColors.warningPillBg,
                  borderRadius: BorderRadius.circular(JhRadii.control),
                ),
                child: Row(
                  children: [
                    const Icon(
                      JhIcons.timeline,
                      size: 14,
                      color: JhColors.warningPillText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.findingDriverPill,
                      style: JhText.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: JhColors.warningPillText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JhPrimaryButton(
            label: t.trackPackageButton,
            onPressed: () => state.openOrderDetail(order),
            radius: JhRadii.control,
            elevated: false,
          ),
          const SizedBox(height: 10),
          JhSecondaryButton(
            label: t.backToHome,
            onPressed: () => state.selectTab(JhTab.home),
            radius: JhRadii.control,
          ),
          if (state.canCancelOrder) ...[
            const SizedBox(height: 4),
            Center(
              child: JhTextLink(
                label: t.cancelOrderCta,
                onPressed: state.askCancelOrder,
                color: JhColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: JhText.ui(
              size: 12.5,
              weight: FontWeight.w500,
              color: JhColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: JhText.ui(size: 13, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

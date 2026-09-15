import 'package:flutter/material.dart';

import '../orders/order_models.dart';
import '../orders/widgets/jh_order_card.dart';
import '../orders/widgets/jh_send_package_card.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';
import '../widgets/jh_segmented_control.dart';
import '../widgets/jh_spinner.dart';
import '../widgets/jh_tab_bar.dart';

/// My Orders — the Orders tab. A hero card into Send a Package, a
/// bucket switch, and the order list for the chosen bucket.
class JhMyOrdersScreen extends StatelessWidget {
  const JhMyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bucketOrders = state.ordersIn(state.ordersBucket);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: JhColors.surface,
          padding: EdgeInsets.fromLTRB(16, topInset + 14, 16, 18),
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                JhRoundBackButton(onPressed: () => state.selectTab(JhTab.home)),
                Expanded(
                  child: Text(
                    t.myOrders,
                    textAlign: TextAlign.center,
                    style: JhText.ui(
                      size: 18,
                      weight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: JhColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const JhScrollBehavior(),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                JhTabBar.heightOf(context) + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JhSendPackageCard(
                    title: t.sendPackageCard,
                    subtitle: t.sendPackageCardSub,
                    onTap: state.startNewOrder,
                  ),
                  const SizedBox(height: 18),
                  JhSegmentedControl<JhOrderBucket>(
                    current: state.ordersBucket,
                    onChanged: state.setOrdersBucket,
                    segments: [
                      JhSegment(
                        value: JhOrderBucket.active,
                        label: t.ordersActive,
                      ),
                      JhSegment(
                        value: JhOrderBucket.completed,
                        label: t.ordersCompleted,
                      ),
                      JhSegment(
                        value: JhOrderBucket.cancelled,
                        label: t.ordersCancelled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.ordersLoading && state.orders.isEmpty)
                    const _OrdersLoading()
                  else if (bucketOrders.isEmpty)
                    _OrdersEmpty(bucket: state.ordersBucket, state: state)
                  else
                    for (final order in bucketOrders) ...[
                      JhOrderCard(
                        order: order,
                        t: t,
                        onTap: () => state.openOrderDetail(order),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _OrdersLoading extends StatelessWidget {
  const _OrdersLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: JhSpinner(size: 24, color: JhColors.primary)),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty({required this.bucket, required this.state});

  final JhOrderBucket bucket;
  final JhAppState state;

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final (title, sub) = switch (bucket) {
      JhOrderBucket.active => (t.ordersEmptyActive, t.ordersEmptyActiveSub),
      JhOrderBucket.completed => (
        t.ordersEmptyCompleted,
        t.ordersEmptyCompletedSub,
      ),
      JhOrderBucket.cancelled => (
        t.ordersEmptyCancelled,
        t.ordersEmptyCancelledSub,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        boxShadow: JhShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              JhIcons.parcel,
              size: 24,
              color: JhColors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: JhText.ui(size: 14.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: JhText.ui(
              size: 12.5,
              weight: FontWeight.w500,
              color: JhColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

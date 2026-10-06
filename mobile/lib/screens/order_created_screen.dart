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
        const SizedBox(height: 12),
        const Center(child: _GlowingCheck()),
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
                  color: JhColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(order.id, style: JhText.mono(size: 13, color: JhColors.primaryText)),
              const SizedBox(height: 10),
              const SizedBox(
                height: 1,
                child: ColoredBox(color: JhColors.cardBorder),
              ),
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
              // Orange, matching the brand -- not the generic amber "warning"
              // treatment this used before. There's no real ETA to show next
              // to it (no live driver-matching countdown), so this stays
              // just the status, not an invented "~2 min".
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: JhColors.primaryTint,
                  borderRadius: BorderRadius.circular(JhRadii.control),
                ),
                child: Row(
                  children: [
                    const Icon(
                      JhIcons.timeline,
                      size: 14,
                      color: JhColors.primaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.findingDriverPill,
                      style: JhText.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: JhColors.primaryText,
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
          _CapsuleButton(
            label: t.trackPackageButton,
            onPressed: () => state.openOrderDetail(order),
            background: JhColors.primary,
            labelColor: JhColors.ink,
          ),
          const SizedBox(height: 10),
          _CapsuleButton(
            label: t.backToHome,
            onPressed: () => state.selectTab(JhTab.home),
            background: JhColors.surfaceMuted,
            labelColor: JhColors.ink,
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

/// The success mark: a static orange circle with a dark check (matching the
/// "dark on orange" language used on the Send a Package hero card), with
/// rings that start small at its edge and continuously expand outward while
/// fading -- three of them staggered evenly through one cycle, so it reads
/// as a steady ripple spreading out rather than one shape breathing in
/// place.
class _GlowingCheck extends StatefulWidget {
  const _GlowingCheck();

  @override
  State<_GlowingCheck> createState() => _GlowingCheckState();
}

class _GlowingCheckState extends State<_GlowingCheck>
    with SingleTickerProviderStateMixin {
  static const _ringCount = 3;
  static const _minSize = 88.0; // starts right at the check circle's edge
  static const _maxSize = 260.0;

  // repeat() with no reverse: a sawtooth 0->1, jump to 0, 0->1... -- each
  // ring needs to keep growing and restart small, never grow then shrink
  // back in place.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: _maxSize,
          height: _maxSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _ringCount; i++)
                _Ring(phase: (_controller.value + i / _ringCount) % 1.0),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: JhColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(JhIcons.check, size: 34, color: JhColors.ink),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.phase});

  /// 0 at spawn (small, most visible) to 1 at full spread (gone).
  final double phase;

  @override
  Widget build(BuildContext context) {
    final size = _GlowingCheckState._minSize +
        (_GlowingCheckState._maxSize - _GlowingCheckState._minSize) * phase;
    final opacity = (1 - phase) * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: JhColors.primary.withValues(alpha: opacity),
          width: 2.5,
        ),
      ),
    );
  }
}

/// A fully-rounded (capsule) flat action, no border -- same language as the
/// Track Package screen's Support/Share trip pair.
class _CapsuleButton extends StatelessWidget {
  const _CapsuleButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.labelColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color labelColor;

  static const _height = 56.0;

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
            style: JhText.ui(size: 16, weight: FontWeight.w800, color: labelColor),
          ),
        ),
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

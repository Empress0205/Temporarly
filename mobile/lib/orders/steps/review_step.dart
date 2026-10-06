import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_scope.dart';
import '../../widgets/jh_spinner.dart';
import '../money.dart';
import '../order_models.dart';
import '../widgets/jh_wizard_scaffold.dart';

/// Step 6 — everything laid out for a last check, each section editable.
class JhReviewStep extends StatelessWidget {
  const JhReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final d = state.draft;

    final recipient = [
      d.recipientName.trim(),
      d.recipientPhone.isEmpty ? '' : '+255 ${d.recipientPhone}',
    ].where((s) => s.isNotEmpty).join(' · ');

    final packageLine = [
      d.packageDescription.trim().isNotEmpty
          ? d.packageDescription.trim()
          : (d.packageType?.label(t) ?? t.pkgOther),
      '${d.quantity} ${d.quantity == 1 ? t.packageUnitOne : t.packageUnitMany}',
      d.packageSize.label(t),
    ].join(' · ');

    final mode = d.deliveryMode;

    return JhWizardScaffold(
      step: 5,
      stepCount: JhAppState.orderStepCount,
      crumb: t.stepTitleReview,
      stepLabel: state.stepLabel(5),
      title: t.reviewTitle,
      onBack: state.back,
      toastVisible: state.toast.isNotEmpty,
      body: [
        _Section(
          label: t.stepTitlePickup,
          onEdit: () =>
              state.editOrderStep(1, phase: JhRoutePhase.pickup),
          editLabel: t.reviewEdit,
          lines: [
            _pretty(d.pickupAddress),
            d.pickupLandmark,
            d.pickupInstructions,
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          label: t.stepTitleDestination,
          onEdit: () =>
              state.editOrderStep(1, phase: JhRoutePhase.dropoff),
          editLabel: t.reviewEdit,
          lines: [
            _pretty(d.dropoffAddress),
            d.dropoffLandmark,
            d.dropoffInstructions,
            recipient,
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          label: t.stepTitlePackage,
          onEdit: () => state.editOrderStep(3),
          editLabel: t.reviewEdit,
          lines: [packageLine],
        ),
        const SizedBox(height: 12),
        _TotalCard(
          totalLabel: t.reviewTotalLabel,
          paymentLabel: d.paymentMethod.label(t),
          price: '${t.tshPrefix} ${jhMoney(mode?.priceTsh ?? 0)}',
          modeLabel: mode?.label(t) ?? '—',
          eta: mode == null ? '' : '${t.reviewArrivesIn} ${mode.eta(t)}',
          onEdit: () => state.editOrderStep(4),
          editLabel: t.reviewEdit,
        ),
      ],
      footer: _SendCapsule(
        label: t.sendPackageButton,
        onPressed: state.nextOrderStep,
        busy: state.orderSubmitting,
      ),
    );
  }

  static String _pretty(String address) {
    final trimmed = address.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }
}

/// Full capsule, dark text on orange, with the recipient card's original
/// busy/spinner behaviour -- this is the flow's final, submitting action.
class _SendCapsule extends StatelessWidget {
  const _SendCapsule({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  static const _height = 56.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      label: label,
      child: GestureDetector(
        onTap: busy ? null : onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JhColors.primary,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                const JhSpinner(),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(size: 16, weight: FontWeight.w800, color: JhColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.onEdit,
    required this.editLabel,
    required this.lines,
  });

  final String label;
  final VoidCallback onEdit;
  final String editLabel;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final shown = lines.where((l) => l.trim().isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.card),
        border: Border.all(color: JhColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: JhText.ui(
                    size: 10.5,
                    weight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: JhColors.textFaint,
                  ),
                ),
              ),
              _EditButton(label: editLabel, onTap: onEdit),
            ],
          ),
          const SizedBox(height: 8),
          for (final (i, line) in shown.indexed) ...[
            if (i > 0) const SizedBox(height: 3),
            Text(
              line,
              style: i == 0
                  ? JhText.ui(size: 14, weight: FontWeight.w800)
                  : JhText.ui(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: JhColors.textMuted,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The filled orange card that closes the review -- combines delivery mode,
/// ETA and payment method into the one figure that actually matters here:
/// what's owed and when it shows up.
class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.totalLabel,
    required this.paymentLabel,
    required this.price,
    required this.modeLabel,
    required this.eta,
    required this.onEdit,
    required this.editLabel,
  });

  final String totalLabel;
  final String paymentLabel;
  final String price;
  final String modeLabel;
  final String eta;
  final VoidCallback onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JhColors.primary,
        borderRadius: BorderRadius.circular(JhRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${totalLabel.toUpperCase()} · ${paymentLabel.toUpperCase()}',
                  style: JhText.ui(
                    size: 10.5,
                    weight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: JhColors.ink,
                  ),
                ),
              ),
              _EditButton(label: editLabel, onTap: onEdit, onPrimary: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: JhText.mono(size: 26, weight: FontWeight.w800, color: JhColors.ink),
          ),
          if (eta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '$modeLabel · $eta',
              style: JhText.ui(size: 12.5, weight: FontWeight.w600, color: JhColors.ink),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({
    required this.label,
    required this.onTap,
    this.onPrimary = false,
  });

  final String label;
  final VoidCallback onTap;

  /// True when this sits on the filled orange Total card, where the usual
  /// tinted-orange chip would disappear into the background.
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: onPrimary
                ? JhColors.ink.withValues(alpha: 0.14)
                : JhColors.primaryTint,
            borderRadius: BorderRadius.circular(JhRadii.pill),
          ),
          child: Text(
            label,
            style: JhText.ui(
              size: 11,
              weight: FontWeight.w800,
              color: onPrimary ? JhColors.ink : JhColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}

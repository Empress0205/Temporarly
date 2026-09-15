import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_buttons.dart';
import '../../widgets/jh_scope.dart';
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

    final packageLine = [
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
      subtitle: t.reviewSub,
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
          label: t.stepTitleRecipient,
          onEdit: () => state.editOrderStep(2),
          editLabel: t.reviewEdit,
          lines: [
            d.recipientName.trim(),
            d.recipientPhone.isEmpty ? '' : '+255 ${d.recipientPhone}',
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          label: t.stepTitlePackage,
          onEdit: () => state.editOrderStep(3),
          editLabel: t.reviewEdit,
          lines: [
            d.packageType?.label(t) ?? t.pkgOther,
            packageLine,
            d.packageDescription,
          ],
          trailing: d.packagePhoto == null
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(JhRadii.control),
                  child: Image.memory(
                    d.packagePhoto!,
                    height: 96,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
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
          ],
        ),
        const SizedBox(height: 12),
        _PaymentCard(
          title: t.reviewDeliveryPayment,
          rows: [
            (t.estimateMode, mode?.label(t) ?? '—'),
            (
              t.estimateFee,
              mode == null
                  ? '—'
                  : '${t.tshPrefix} ${jhMoney(mode.priceTsh)}',
            ),
            (t.reviewPaymentLabel, d.paymentMethod.label(t)),
          ],
          onEdit: () => state.editOrderStep(4),
          editLabel: t.reviewEdit,
        ),
      ],
      footer: JhPrimaryButton(
        label: t.sendPackageButton,
        onPressed: state.nextOrderStep,
        busy: state.orderSubmitting,
        radius: JhRadii.control,
        elevated: false,
      ),
    );
  }

  static String _pretty(String address) {
    final trimmed = address.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.onEdit,
    required this.editLabel,
    required this.lines,
    this.trailing,
  });

  final String label;
  final VoidCallback onEdit;
  final String editLabel;
  final List<String> lines;

  /// Extra content under the text lines -- the package photo, when there is
  /// one.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final shown = lines.where((l) => l.trim().isNotEmpty).toList();
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
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.title,
    required this.rows,
    required this.onEdit,
    required this.editLabel,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;
  final String editLabel;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
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
          const SizedBox(height: 6),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    row.$1,
                    style: JhText.ui(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: JhColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JhText.ui(size: 13, weight: FontWeight.w700),
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

class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
            color: JhColors.primaryTint,
            borderRadius: BorderRadius.circular(JhRadii.pill),
          ),
          child: Text(
            label,
            style: JhText.ui(
              size: 11,
              weight: FontWeight.w800,
              color: JhColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}

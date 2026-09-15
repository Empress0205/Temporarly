import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_buttons.dart';
import '../../widgets/jh_scope.dart';
import '../money.dart';
import '../order_models.dart';
import '../widgets/jh_wizard_scaffold.dart';

/// Step 5 — how the package travels, and the resulting estimate.
class JhDeliveryModeStep extends StatelessWidget {
  const JhDeliveryModeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final draft = state.draft;
    final selected = draft.deliveryMode;
    final km = draft.routeKm;

    return JhWizardScaffold(
      step: 4,
      stepCount: JhAppState.orderStepCount,
      crumb: t.stepTitleDelivery,
      stepLabel: state.stepLabel(4),
      title: t.deliveryModeTitle,
      subtitle: t.deliveryModeSub,
      onBack: state.back,
      toastVisible: state.toast.isNotEmpty,
      body: [
        _RoutePill(
          from: draft.hasPickup ? _area(draft.pickupAddress) : '—',
          to: draft.hasDropoff ? _area(draft.dropoffAddress) : '—',
          km: km,
          kmUnit: t.kmUnit,
        ),
        const SizedBox(height: 16),
        for (final vehicle in JhVehicle.values) ...[
          _ModeCard(
            vehicle: vehicle,
            selected: vehicle == selected,
            t: t,
            onTap: () => state.setDeliveryMode(vehicle),
          ),
          const SizedBox(height: 10),
        ],
        if (selected != null) ...[
          const SizedBox(height: 10),
          _EstimateCard(
            from: _area(draft.pickupAddress),
            to: _area(draft.dropoffAddress),
            mode: selected.label(t),
            time: selected.eta(t),
            fee: '${t.tshPrefix} ${jhMoney(selected.priceTsh)}',
            payment: draft.paymentMethod.label(t),
            t: t,
          ),
        ],
      ],
      footer: JhPrimaryButton(
        label: t.continueLabel,
        onPressed: state.nextOrderStep,
        enabled: selected != null,
        radius: JhRadii.control,
        elevated: false,
      ),
    );
  }

  static String _area(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '—';
    return trimmed.split(RegExp(r'[,\n]')).first.trim();
  }
}

class _RoutePill extends StatelessWidget {
  const _RoutePill({
    required this.from,
    required this.to,
    required this.km,
    required this.kmUnit,
  });

  final String from;
  final String to;
  final double? km;
  final String kmUnit;

  @override
  Widget build(BuildContext context) {
    final distance = km == null ? '' : '  ·  ~${km!.toStringAsFixed(0)} $kmUnit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: JhColors.primaryTint,
        borderRadius: BorderRadius.circular(JhRadii.control),
      ),
      child: Row(
        children: [
          const Icon(JhIcons.mapPin, size: 15, color: JhColors.primaryText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$from → $to$distance',
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
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.vehicle,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final JhVehicle vehicle;
  final bool selected;
  final dynamic t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = vehicle.available;
    final dim = !available;

    return Semantics(
      button: available,
      selected: selected,
      label: vehicle.label(t),
      child: GestureDetector(
        onTap: available ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: dim ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? JhColors.primaryTint : JhColors.surface,
              borderRadius: BorderRadius.circular(JhRadii.control),
              // Only the selected card gets an outline -- it's the one piece
              // of information a border actually carries here. Everything
              // else separates from the page with a shadow instead.
              border: selected
                  ? Border.all(color: JhColors.primary, width: 1.5)
                  : null,
              boxShadow: selected ? null : JhShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? JhColors.primaryText
                        : JhColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    vehicle.icon,
                    size: 20,
                    color: selected
                        ? JhColors.onDark
                        : JhColors.primaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.label(t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: JhText.ui(
                                size: 14.5,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${t.tshPrefix} ${jhMoney(vehicle.priceTsh)}',
                            style: JhText.mono(
                              size: 13.5,
                              color: selected
                                  ? JhColors.primaryText
                                  : JhColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicle.spec(t),
                        style: JhText.ui(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: JhColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                JhIcons.timeline,
                                size: 12,
                                color: JhColors.textFaint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vehicle.eta(t),
                                style: JhText.ui(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: JhColors.textFaint,
                                ),
                              ),
                            ],
                          ),
                          if (!available)
                            Text(
                              t.modeUnavailable,
                              style: JhText.ui(
                                size: 11,
                                weight: FontWeight.w800,
                                color: JhColors.danger,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: JhColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      JhIcons.check,
                      size: 13,
                      color: JhColors.onDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.from,
    required this.to,
    required this.mode,
    required this.time,
    required this.fee,
    required this.payment,
    required this.t,
  });

  final String from;
  final String to;
  final String mode;
  final String time;
  final String fee;
  final String payment;
  final dynamic t;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            t.deliveryEstimateTitle.toUpperCase(),
            style: JhText.ui(
              size: 10.5,
              weight: FontWeight.w800,
              letterSpacing: 0.6,
              color: JhColors.textFaint,
            ),
          ),
          const SizedBox(height: 12),
          _Line(label: t.estimateFrom, value: from),
          _Line(label: t.estimateTo, value: to),
          _Line(label: t.estimateMode, value: mode),
          _Line(label: t.estimateTime, value: time),
          _Line(label: t.estimateFee, value: fee, emphasise: true),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                JhIcons.email,
                size: 14,
                color: JhColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                payment,
                style: JhText.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: JhColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

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
              style: emphasise
                  ? JhText.ui(
                      size: 14,
                      weight: FontWeight.w800,
                      color: JhColors.primaryText,
                    )
                  : JhText.ui(size: 13, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

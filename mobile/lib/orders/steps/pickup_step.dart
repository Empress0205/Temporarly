import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../state/app_state.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_fields.dart';
import '../../widgets/jh_scope.dart';
import '../../widgets/jh_spinner.dart';
import '../location_service.dart';
import '../widgets/jh_pickup_map.dart';
import '../widgets/jh_recent_places.dart';
import '../widgets/jh_wizard_controls.dart';
import '../widgets/jh_wizard_scaffold.dart';

/// Step 1 — where the parcel is collected. Search-first, the same idea as
/// the Destination half: type an address and the map finds it. "Use Current
/// Location" and dragging the pin are shortcuts on the same screen, not a
/// separate one. `state.pickupMode` only ever spends a moment on `locating`
/// while GPS resolves; the rest of the time it's `manual`.
class JhPickupStep extends StatelessWidget {
  const JhPickupStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    return switch (state.pickupMode) {
      JhPickupMode.locating => const _Locating(),
      JhPickupMode.manual => const _ManualForm(),
    };
  }
}

JhWizardScaffold _scaffold({
  required JhAppState state,
  required List<Widget> body,
  required Widget footer,
  String? title,
}) {
  final t = state.t;
  return JhWizardScaffold(
    step: 1,
    stepCount: JhAppState.orderStepCount,
    crumb: t.stepTitlePickup,
    stepLabel: state.stepLabel(1),
    title: title ?? t.pickupTitle,
    onBack: state.back,
    toastVisible: state.toast.isNotEmpty,
    body: body,
    footer: footer,
  );
}

class _Locating extends StatelessWidget {
  const _Locating();

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;

    return _scaffold(
      state: state,
      title: '',
      body: [
        const SizedBox(height: 60),
        const Center(child: JhSpinner(size: 24, color: JhColors.primary)),
        const SizedBox(height: 16),
        Text(
          t.pickupLocating,
          textAlign: TextAlign.center,
          style: JhText.ui(
            size: 13.5,
            weight: FontWeight.w600,
            color: JhColors.textMuted,
          ),
        ),
      ],
      footer: const SizedBox.shrink(),
    );
  }
}

/// The pickup form: search, "Use Current Location", recents and a draggable
/// map, all on one screen. GPS fills the same fields typing would.
class _ManualForm extends StatefulWidget {
  const _ManualForm();

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  static const _minQueryLength = 3;
  static const _debounceDelay = Duration(milliseconds: 400);

  final TextEditingController _search = TextEditingController();
  List<JhPlacePrediction> _results = const [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Search as the customer types, not only once they press Enter -- a short
  /// debounce so every keystroke doesn't fire its own lookup.
  void _onChanged(JhAppState state, String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < _minQueryLength) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(_debounceDelay, () => _runSearch(state, query));
  }

  Future<void> _runSearch(JhAppState state, String query) async {
    if (query.isEmpty) return;
    setState(() => _searching = true);
    final results = await state.pickupSearch(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final draft = state.draft;
    final center = (draft.pickupLat != null && draft.pickupLng != null)
        ? LatLng(draft.pickupLat!, draft.pickupLng!)
        : null;

    return _scaffold(
      state: state,
      body: [
        if (state.pickupError.isNotEmpty) ...[
          _Banner(
            icon: JhIcons.mapPin,
            text: state.pickupError,
            tone: _BannerTone.warn,
          ),
          const SizedBox(height: 14),
        ],
        // Search stays pinned at the top of the screen -- the reference this
        // redesign matches drops it in favour of drag-to-set-pin, but typing
        // an address and getting live results as you type is a hard
        // requirement for this app, so it isn't going anywhere.
        JhFieldShell(
          borderColor: JhColors.cardBorder,
          radius: JhRadii.card,
          child: Row(
            children: [
              const Icon(
                JhIcons.search,
                size: 18,
                color: JhColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EditableTextField(
                  controller: _search,
                  onChanged: (v) => _onChanged(state, v),
                  onSubmitted: () {
                    _debounce?.cancel();
                    _runSearch(state, _search.text.trim());
                  },
                  placeholder: t.pickupSearchHint,
                  style: JhText.input,
                ),
              ),
              if (_searching)
                const JhSpinner(size: 15, color: JhColors.primary),
            ],
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final prediction in _results)
            _ResultRow(
              prediction: prediction,
              onTap: () async {
                setState(() => _results = const []);
                _search.clear();
                await state.pickupSelectPrediction(prediction);
              },
            ),
        ],
        const SizedBox(height: 14),
        Stack(
          children: [
            JhPickupMap(
              live: state.liveMap,
              center: center,
              draggable: true,
              radius: JhRadii.card,
              onPinMoved: (p) =>
                  state.pickupPinMoved(p.latitude, p.longitude),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _LocationPill(
                label: t.pickupUseCurrentLocation,
                onTap: state.pickupAllowLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          t.pickupMoveHint,
          style: JhText.ui(
            size: 12,
            weight: FontWeight.w600,
            color: JhColors.textFaint,
          ),
        ),
        const SizedBox(height: 20),
        JhSectionLabel(t.pickupAddressLabel),
        const SizedBox(height: 6),
        JhUnderlineDisplay(
          value: draft.pickupAddress.trim().isEmpty
              ? '—'
              : draft.pickupAddress,
        ),
        const SizedBox(height: 18),
        JhSectionLabel(t.pickupLandmarkLabel),
        const SizedBox(height: 6),
        JhUnderlineField(
          value: draft.pickupLandmark,
          onChanged: state.setPickupLandmark,
          placeholder: t.pickupLandmarkHint,
        ),
        if (state.recentPlaces.isNotEmpty) ...[
          const SizedBox(height: 20),
          JhRecentPlaces(
            places: state.recentPlaces,
            onSelect: state.pickupSelectPlace,
            t: t,
          ),
        ],
      ],
      footer: JhContinueCapsule(
        label: t.pickupConfirm,
        onPressed: state.draft.hasPickup ? state.confirmPickup : null,
      ),
    );
  }
}

/// A floating white pill over the map's top-right corner -- matches the
/// reference's map treatment, replacing the tinted row that used to sit
/// above the map.
class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.pill),
            boxShadow: JhShadows.field,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                JhIcons.myLocation,
                size: 14,
                color: JhColors.primaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: JhText.ui(size: 12, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BannerTone { good, warn }

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _BannerTone.good => (JhColors.primaryTint, JhColors.primaryText),
      _BannerTone.warn => (JhColors.warningPillBg, JhColors.warningPillText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(JhRadii.card),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: JhText.ui(size: 12.5, weight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.prediction, required this.onTap});

  final JhPlacePrediction prediction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: JhColors.surface,
          borderRadius: BorderRadius.circular(JhRadii.card),
          border: Border.all(color: JhColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(JhIcons.mapPin, size: 16, color: JhColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                prediction.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JhText.ui(size: 13, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

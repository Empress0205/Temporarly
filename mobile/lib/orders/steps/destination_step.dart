import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../state/app_state.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_buttons.dart';
import '../../widgets/jh_fields.dart';
import '../../widgets/jh_scope.dart';
import '../../widgets/jh_spinner.dart';
import '../location_service.dart';
import '../widgets/jh_pickup_map.dart';
import '../widgets/jh_recent_places.dart';
import '../widgets/jh_wizard_scaffold.dart';

/// Step 4 — where the parcel is delivered. Always the map/search form: the
/// customer is not standing at the drop-off, so there is no "use current
/// location".
class JhDestinationStep extends StatefulWidget {
  const JhDestinationStep({super.key});

  @override
  State<JhDestinationStep> createState() => _JhDestinationStepState();
}

class _JhDestinationStepState extends State<JhDestinationStep> {
  static const _minQueryLength = 3;
  static const _debounceDelay = Duration(milliseconds: 400);

  final TextEditingController _search = TextEditingController();
  List<JhPlace> _results = const [];
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
    final results = await state.dropoffSearch(query);
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
    final center = (draft.dropoffLat != null && draft.dropoffLng != null)
        ? LatLng(draft.dropoffLat!, draft.dropoffLng!)
        : null;

    return JhWizardScaffold(
      step: 1,
      stepCount: JhAppState.orderStepCount,
      crumb: '${t.stepTitleRoute} · ${t.stepTitleDestination}',
      stepLabel: state.stepLabel(1),
      title: t.destinationTitle,
      subtitle: t.destinationSub,
      onBack: state.back,
      toastVisible: state.toast.isNotEmpty,
      body: [
        JhFieldShell(
          borderColor: JhColors.cardBorder,
          child: Row(
            children: [
              const Icon(JhIcons.search, size: 18, color: JhColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: EditableTextField(
                  controller: _search,
                  onChanged: (v) => _onChanged(state, v),
                  onSubmitted: () {
                    _debounce?.cancel();
                    _runSearch(state, _search.text.trim());
                  },
                  placeholder: t.destinationSearchHint,
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
          for (final place in _results)
            _ResultRow(
              place: place,
              onTap: () {
                state.dropoffSelectPlace(place);
                setState(() => _results = const []);
                _search.clear();
              },
            ),
        ] else if (draft.dropoffAddress.trim().isEmpty &&
            state.recentPlaces.isNotEmpty) ...[
          const SizedBox(height: 12),
          JhRecentPlaces(
            places: state.recentPlaces,
            onSelect: state.dropoffSelectPlace,
            t: t,
          ),
        ],
        const SizedBox(height: 14),
        JhPickupMap(
          live: state.liveMap,
          center: center,
          draggable: true,
          onPinMoved: (p) => state.dropoffPinMoved(p.latitude, p.longitude),
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
        if (draft.dropoffAddress.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            draft.dropoffAddress,
            style: JhText.ui(size: 14.5, weight: FontWeight.w800),
          ),
        ],
        const SizedBox(height: 18),
        JhLabeledField(
          label: '${t.pickupLandmarkLabel} (${t.optionalSuffix})',
          child: JhTextField(
            value: draft.dropoffLandmark,
            onChanged: state.setDropoffLandmark,
            placeholder: t.destinationLandmarkHint,
            hasError: false,
          ),
        ),
        const SizedBox(height: 18),
        JhLabeledField(
          label: '${t.recipientDeliveryLabel} (${t.optionalSuffix})',
          child: JhTextArea(
            value: draft.dropoffInstructions,
            onChanged: state.setDropoffInstructions,
            placeholder: t.recipientDeliveryHint,
            minLines: 1,
            maxLines: 3,
          ),
        ),
      ],
      footer: JhPrimaryButton(
        label: t.destinationConfirm,
        onPressed: state.confirmDestination,
        enabled: state.draft.hasDropoff,
        radius: JhRadii.control,
        elevated: false,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.place, required this.onTap});

  final JhPlace place;
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
          borderRadius: BorderRadius.circular(JhRadii.control),
          boxShadow: JhShadows.card,
        ),
        child: Row(
          children: [
            const Icon(JhIcons.mapPin, size: 16, color: JhColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                place.address,
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

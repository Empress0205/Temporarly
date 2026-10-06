import 'package:flutter/widgets.dart';

import '../../l10n/dict.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../location_service.dart';

/// Offered at the top of the Route step once there is at least one past
/// order to draw from. A tap fills the field the way typing or a search
/// result would -- it is a shortcut past retyping, not past confirming.
class JhRecentPlaces extends StatelessWidget {
  const JhRecentPlaces({
    super.key,
    required this.places,
    required this.onSelect,
    required this.t,
  });

  final List<JhPlace> places;
  final ValueChanged<JhPlace> onSelect;
  final JhStrings t;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.recentPlacesTitle.toUpperCase(),
          style: JhText.ui(
            size: 10.5,
            weight: FontWeight.w800,
            letterSpacing: 0.6,
            color: JhColors.textFaint,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final place in places)
              _Chip(place: place, onTap: () => onSelect(place)),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.place, required this.onTap});

  final JhPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: place.address,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.pill),
            border: Border.all(color: JhColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                JhIcons.recent,
                size: 14,
                color: JhColors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  place.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(size: 12.5, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

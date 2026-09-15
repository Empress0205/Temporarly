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
        for (final place in places)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              button: true,
              label: place.address,
              child: GestureDetector(
                onTap: () => onSelect(place),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: JhColors.surface,
                    borderRadius: BorderRadius.circular(JhRadii.control),
                    boxShadow: JhShadows.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        JhIcons.recent,
                        size: 16,
                        color: JhColors.textMuted,
                      ),
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
              ),
            ),
          ),
        const SizedBox(height: 14),
      ],
    );
  }
}

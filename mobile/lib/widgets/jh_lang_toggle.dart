import 'package:flutter/widgets.dart';

import '../l10n/dict.dart';
import '../theme/tokens.dart';
import 'jh_scope.dart';

/// EN / SW switch -- both options shown at once in one pill, the active one
/// picked out in full weight/colour, the other muted. Tapping the muted side
/// switches to it; tapping the already-active side does nothing.
///
/// Switching rebuilds copy only -- the current screen and every form value
/// survive it.
class JhLangToggle extends StatelessWidget {
  const JhLangToggle({super.key, this.onDark = true});

  /// Green header placement uses the translucent light chrome; on a light
  /// surface it takes the primary tint instead.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final isEn = state.lang == JhLang.en;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: onDark ? JhColors.onDarkSurfaceSoft : JhColors.primaryTint,
        borderRadius: BorderRadius.circular(JhRadii.pill),
        border: Border.all(
          color: onDark ? JhColors.onDarkBorderSoft : JhColors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'EN',
            active: isEn,
            onDark: onDark,
            onTap: isEn ? null : state.toggleLang,
          ),
          _Segment(
            label: 'SW',
            active: !isEn,
            onDark: onDark,
            onTap: isEn ? state.toggleLang : null,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onDark,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool onDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = onDark ? JhColors.onDark : JhColors.primaryText;
    final mutedColor = onDark ? JhColors.onDarkMuted : JhColors.textMuted;

    return Semantics(
      button: true,
      selected: active,
      label: 'Switch language to $label',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 26,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active
                ? (onDark ? JhColors.onDarkSurface : JhColors.surface)
                : null,
            borderRadius: BorderRadius.circular(JhRadii.pill),
          ),
          child: Text(
            label,
            style: JhText.mono(
              size: 11.5,
              weight: active ? FontWeight.w800 : FontWeight.w500,
              letterSpacing: 1,
              color: active ? activeColor : mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}

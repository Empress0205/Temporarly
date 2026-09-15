import 'package:flutter/widgets.dart';

import '../l10n/dict.dart';
import '../theme/tokens.dart';
import 'jh_scope.dart';

/// EN / SW switch.
///
/// The prototype took its language from the review harness, which is not
/// ported, so the app needs an affordance of its own. Switching rebuilds copy
/// only -- the current screen and every form value survive it.
class JhLangToggle extends StatelessWidget {
  const JhLangToggle({super.key, this.onDark = true});

  /// Green header placement uses the translucent light chrome; on a light
  /// surface it takes the primary tint instead.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final other = state.lang == JhLang.en ? 'SW' : 'EN';

    return Semantics(
      button: true,
      label: 'Switch language to $other',
      child: GestureDetector(
        onTap: state.toggleLang,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: onDark ? JhColors.onDarkSurfaceSoft : JhColors.primaryTint,
            borderRadius: BorderRadius.circular(JhRadii.pill),
            border: Border.all(
              color: onDark ? JhColors.onDarkBorderSoft : JhColors.cardBorder,
            ),
          ),
          child: Text(
            other,
            style: JhText.mono(
              size: 11.5,
              letterSpacing: 1,
              color: onDark ? JhColors.onDark : JhColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}

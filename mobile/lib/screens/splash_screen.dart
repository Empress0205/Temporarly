import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/jh_brand.dart';
import '../widgets/jh_scope.dart';
import '../widgets/jh_spinner.dart';

/// Checks local authentication state before showing anything (spec 34).
///
/// The branch itself lives in `JhAppState`: on a valid stored session it goes
/// to Home, otherwise Welcome. Authenticated data is never rendered while the
/// state is unknown.
class JhSplashScreen extends StatelessWidget {
  const JhSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = JhScope.of(context).t;

    // Plain white, like every other screen -- the brief loading moment
    // doesn't need its own colour treatment, and a charcoal field here would
    // be the one screen that contradicts "very plain" before the app has
    // even shown anything else.
    return DecoratedBox(
      decoration: const BoxDecoration(color: JhColors.surface),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const JhBrandLockup(
              tileSize: 68,
              wordSize: 23,
              axis: Axis.vertical,
              showEyebrow: true,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const JhSpinner(
                  size: 14,
                  color: JhColors.primaryText,
                  trackColor: JhColors.hairline,
                ),
                const SizedBox(width: 9),
                Text(
                  t.checkingSession,
                  style: JhText.ui(
                    size: 13,
                    weight: FontWeight.w600,
                    color: JhColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

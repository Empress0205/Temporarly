import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/jh_brand.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_onboarding_carousel.dart';
import '../widgets/jh_lang_toggle.dart';
import '../widgets/jh_scope.dart';

/// The unauthenticated landing: an onboarding sequence (an illustrated
/// scene, a headline and a subtitle -- one slide per vehicle type,
/// auto-advancing and swipeable, dots showing where you are) with a single
/// Continue action underneath, rather than putting the Login/Create-account
/// choice in front of someone before they've seen what the app does.
/// Continue starts registration; Register's own footer already offers the
/// way to Login for someone who has an account.
class JhWelcomeScreen extends StatelessWidget {
  const JhWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(color: JhColors.surface),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topInset + 18, 24, 22 + bottomInset),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                const JhBrandLockup(),
                const Spacer(),
                const Align(
                  alignment: Alignment.centerRight,
                  child: JhLangToggle(onDark: false),
                ),
              ],
            ),
            Expanded(child: Center(child: JhOnboardingCarousel(t: t))),
            const SizedBox(height: 22),
            JhPrimaryButton(
              label: t.continueLabel,
              onPressed: state.goRegister,
              radius: JhRadii.control,
              elevated: false,
            ),
            const SizedBox(height: 16),
            const _LegalLine(),
          ],
        ),
      ),
    );
  }
}

/// "By continuing you agree to our Terms of Service & Privacy Policy."
///
/// The two documents are Sprint 2; the links are styled and tappable but have
/// nowhere to go yet, so they say so rather than failing silently.
class _LegalLine extends StatelessWidget {
  const _LegalLine();

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;

    final base = JhText.ui(
      size: 11.5,
      weight: FontWeight.w500,
      color: JhColors.textFaint,
      height: 1.45,
    );
    final link = base.copyWith(
      color: JhColors.primaryText,
      fontWeight: FontWeight.w700,
    );

    Widget document(String label) => GestureDetector(
      onTap: () => state.showComingSoon(label),
      behavior: HitTestBehavior.opaque,
      child: Text(label, style: link),
    );

    // A Wrap of separate spans rather than one rich paragraph: tappable spans
    // need a gesture recogniser each, and those have to be disposed by hand.
    // This keeps the line stateless and the tap targets real.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        Text(t.legalPrefix, style: base),
        document(t.legalTerms),
        Text(t.legalAnd, style: base),
        document(t.legalPrivacy),
      ],
    );
  }
}

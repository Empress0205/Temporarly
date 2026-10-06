import 'package:flutter/material.dart';

import '../l10n/dict.dart';
import '../orders/widgets/jh_send_package_card.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_lang_toggle.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';
import '../widgets/jh_tab_bar.dart';

/// The authenticated landing: a plain header carrying the greeting, then the
/// Send a Package hero, quick actions and a first-delivery guide on a flat
/// neutral ground.
///
/// Only the greeting comes from the session. Everything below it is Sprint 2
/// surface area, shown in its empty state rather than with invented data.
class JhHomeScreen extends StatelessWidget {
  const JhHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;

    // Flat -- no gradient. The header below has no colour of its own, so it
    // reads as one continuous surface with the Scaffold's flat background
    // rather than a separate card with a seam.
    return Column(
      children: [
        const _HomeHeader(),
        Expanded(
          child: ScrollConfiguration(
            behavior: const JhScrollBehavior(),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                JhTabBar.heightOf(context) + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JhSendPackageCard(
                    title: t.sendPackageCard,
                    subtitle: t.sendPackageCardSub,
                    onTap: state.startNewOrder,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(t.quickActions),
                  const SizedBox(height: 12),
                  const _QuickActions(),
                  const SizedBox(height: 24),
                  _SectionTitle(t.firstDeliveryTitle),
                  const SizedBox(height: 12),
                  _FirstDeliveryCard(t: t),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      // No colour of its own -- the screen's radial glow shows straight
      // through, so there's no seam where a separate header used to end.
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingFor(state.clock(), t).toUpperCase(),
                      style: JhText.ui(
                        size: 11.5,
                        weight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: JhColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.greetingName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JhText.ui(
                        size: 27,
                        weight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: JhColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const JhLangToggle(onDark: false),
              const SizedBox(width: 8),
              _CircleButton(
                icon: JhIcons.help,
                semanticLabel: t.support,
                onTap: () => state.showComingSoon(t.support),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Time-of-day greeting. Kept here rather than in state because it is a
  /// presentation detail with no bearing on the flows.
  static String _greetingFor(DateTime now, JhStrings t) {
    if (now.hour < 12) return t.goodMorning;
    if (now.hour < 18) return t.goodAfternoon;
    return t.goodEvening;
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JhColors.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(color: JhColors.cardBorder),
          ),
          child: Icon(icon, size: 19, color: JhColors.textMuted),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: JhText.ui(
      size: 11.5,
      weight: FontWeight.w800,
      letterSpacing: 0.7,
      color: JhColors.textFaint,
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;

    // Each icon in the colour it would naturally be, not one accent stamped
    // on all four and not a flat grey either -- a delivery truck reads as
    // amber, a pin as terracotta, a star as gold. Kept muted/warm so the row
    // still sits quietly in the palette rather than turning into a rainbow.
    final actions = <_Action>[
      _Action(JhIcons.track, const Color(0xFFB5651D), t.track, t.trackSub),
      _Action(JhIcons.shop, const Color(0xFFA9821C), t.shop, t.shopSub),
      _Action(JhIcons.nearby, const Color(0xFFBD5B4C), t.nearby, t.nearbySub),
      _Action(
        JhIcons.favourites,
        const Color(0xFFC49A2C),
        t.favourites,
        t.favouritesSub,
      ),
    ];

    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    action: actions[row * 2 + col],
                    onTap: () =>
                        state.showComingSoon(actions[row * 2 + col].title),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Action {
  const _Action(this.icon, this.color, this.title, this.subtitle);

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final _Action action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${action.title}. ${action.subtitle}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.cardSmall),
            boxShadow: JhShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: JhColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 19, color: action.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JhText.ui(size: 13.5, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: JhText.ui(
                        size: 11,
                        weight: FontWeight.w500,
                        color: JhColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Replaces a generic "no orders yet" empty state with something a first-time
/// sender can actually act on: what the three steps look like, and roughly
/// what it costs by the cheapest vehicle -- an anchor, not a quote (nothing
/// is chosen yet, so this can't be computed from a real route).
class _FirstDeliveryCard extends StatelessWidget {
  const _FirstDeliveryCard({required this.t});

  final JhStrings t;

  @override
  Widget build(BuildContext context) {
    final steps = [t.homeStep1, t.homeStep2, t.homeStep3];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.cardSmall),
        boxShadow: JhShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in steps.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: [
                _StepBadge(number: i + 1, filled: i == 0),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step,
                    style: JhText.ui(size: 13.5, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: JhColors.cardBorder),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.typicalFareLabel.toUpperCase(),
                  style: JhText.ui(
                    size: 10.5,
                    weight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: JhColors.textFaint,
                  ),
                ),
              ),
              Text(
                t.typicalFareValue,
                style: JhText.ui(size: 14, weight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.filled});

  final int number;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? JhColors.primary : JhColors.surfaceMuted,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$number',
        style: JhText.ui(
          size: 12,
          weight: FontWeight.w800,
          color: filled ? JhColors.onDark : JhColors.textMuted,
        ),
      ),
    );
  }
}


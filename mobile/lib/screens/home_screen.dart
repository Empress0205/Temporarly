import 'package:flutter/material.dart';

import '../l10n/dict.dart';
import '../orders/widgets/jh_send_package_card.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_lang_toggle.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';
import '../widgets/jh_tab_bar.dart';

/// The authenticated landing: a green header carrying the greeting and search,
/// then quick actions and recent orders on a light ground.
///
/// Only the greeting comes from the session. Everything below it is Sprint 2
/// surface area, shown in its empty state rather than with invented data.
class JhHomeScreen extends StatelessWidget {
  const JhHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;

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
                  _SectionTitle(t.recentOrders),
                  const SizedBox(height: 12),
                  _EmptyOrders(t: t),
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
      color: JhColors.surface,
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
                      _greetingFor(state.clock(), t),
                      style: JhText.ui(
                        size: 13,
                        weight: FontWeight.w600,
                        color: JhColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.greetingName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: JhText.ui(
                              size: 20,
                              weight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: JhColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          JhIcons.wave,
                          size: 18,
                          color: JhColors.accent,
                        ),
                      ],
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
          const SizedBox(height: 16),
          _SearchField(hint: t.searchHint, onTap: () => state.showComingSoon(t.shop)),
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
          child: Icon(icon, size: 19, color: JhColors.primaryText),
        ),
      ),
    );
  }
}

/// Search is a Sprint 2 surface; the field is presentational and says so when
/// tapped rather than opening a dead screen.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: hint,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: JhColors.surfaceMuted,
            borderRadius: BorderRadius.circular(JhRadii.control),
            border: Border.all(color: JhColors.cardBorder),
          ),
          child: Row(
            children: [
              const Icon(JhIcons.search, size: 19, color: JhColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(
                    size: 14,
                    weight: FontWeight.w500,
                    color: JhColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
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
    text,
    style: JhText.ui(size: 15.5, weight: FontWeight.w800, letterSpacing: -0.3),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;

    // One neutral treatment for all four -- colour-coding a row of equally
    // weighted actions doesn't communicate anything real; it just adds more
    // accents to a screen that already has one (the hero card above).
    final actions = <_Action>[
      _Action(JhIcons.shop, t.shop, t.shopSub),
      _Action(JhIcons.track, t.track, t.trackSub),
      _Action(JhIcons.nearby, t.nearby, t.nearbySub),
      _Action(JhIcons.favourites, t.favourites, t.favouritesSub),
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
  const _Action(this.icon, this.title, this.subtitle);

  final IconData icon;
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
                child: Icon(action.icon, size: 19, color: JhColors.primaryText),
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

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.t});

  final JhStrings t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.cardSmall),
        boxShadow: JhShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: JhColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              JhIcons.parcel,
              size: 24,
              color: JhColors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t.noOrders,
            textAlign: TextAlign.center,
            style: JhText.ui(size: 14.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            t.noOrdersSub,
            textAlign: TextAlign.center,
            style: JhText.ui(
              size: 12.5,
              weight: FontWeight.w500,
              color: JhColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

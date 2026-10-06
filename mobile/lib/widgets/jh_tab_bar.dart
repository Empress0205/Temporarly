import 'package:flutter/material.dart';

import '../l10n/dict.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';

/// The four-item bar on authenticated screens: Home, Shop, Orders, Account.
///
/// The active item is marked by colour plus a dot beneath the label, so the
/// selection does not rely on colour alone.
class JhTabBar extends StatelessWidget {
  const JhTabBar({
    super.key,
    required this.current,
    required this.strings,
    required this.onSelect,
  });

  final JhTab current;
  final JhStrings strings;
  final ValueChanged<JhTab> onSelect;

  /// Total footprint reserved for the floating bar, including the gap above
  /// it and the safe-area allowance below it -- screens pad their scroll
  /// content by this so nothing sits underneath it.
  static const double baseHeight = 78;

  static double heightOf(BuildContext context) =>
      baseHeight + bottomInsetOf(context);

  /// The design reserves a bottom allowance for the home indicator; on devices
  /// that report a deeper inset we use theirs instead.
  static double bottomInsetOf(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return inset > 16 ? inset : 16;
  }

  @override
  Widget build(BuildContext context) {
    // A floating pill rather than an edge-to-edge bar: margin on every side
    // lets the page's own background show around it instead of the bar
    // owning the full width and pinning a hairline across the screen.
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInsetOf(context)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: JhColors.surface,
          borderRadius: BorderRadius.circular(JhRadii.sheet),
          boxShadow: JhShadows.tabBar,
        ),
        child: Row(
          children: [
            _Item(
              icon: JhIcons.tabHome,
              label: strings.home,
              selected: current == JhTab.home,
              onTap: () => onSelect(JhTab.home),
            ),
            _Item(
              icon: JhIcons.tabShop,
              label: strings.shop,
              selected: current == JhTab.shop,
              onTap: () => onSelect(JhTab.shop),
            ),
            _Item(
              icon: JhIcons.tabOrders,
              label: strings.orders,
              selected: current == JhTab.orders,
              onTap: () => onSelect(JhTab.orders),
            ),
            _Item(
              icon: JhIcons.tabAccount,
              label: strings.account,
              selected: current == JhTab.account,
              onTap: () => onSelect(JhTab.account),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? JhColors.primaryText : JhColors.textMuted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 23, color: colour),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(
                    size: 11,
                    weight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: colour,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: selected
                        ? JhColors.primaryText
                        : const Color(0x00000000),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

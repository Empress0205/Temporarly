import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/jh_scope.dart';
import '../widgets/jh_tab_bar.dart';

/// Stands behind the Shop and Orders tabs, which Sprint 1 does not build.
///
/// A tab that only raised a toast would look broken; this gives the tab a real
/// destination that states plainly what is not there yet.
class JhComingSoonScreen extends StatelessWidget {
  const JhComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = JhScope.of(context).t;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: JhColors.surface,
          padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 20),
          child: Text(
            title,
            style: JhText.ui(
              size: 22,
              weight: FontWeight.w800,
              letterSpacing: -0.6,
              color: JhColors.ink,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              0,
              32,
              JhTabBar.heightOf(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: JhColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: JhColors.primaryText),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: JhText.ui(size: 17, weight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  t.comingSoon,
                  textAlign: TextAlign.center,
                  style: JhText.ui(
                    size: 13.5,
                    weight: FontWeight.w500,
                    color: JhColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

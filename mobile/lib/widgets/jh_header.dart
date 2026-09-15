import 'package:flutter/material.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'jh_brand.dart';
import 'jh_lang_toggle.dart';

/// The white header above register, login, OTP and change phone: back
/// button, small brand lockup and language switch on one row, then the title
/// and its explanation in dark text on the light surface -- matching the
/// driver app's Register screen rather than the old filled colour band.
class JhAuthHeader extends StatelessWidget {
  const JhAuthHeader({
    super.key,
    required this.onBack,
    required this.title,
    required this.subtitle,
    this.extra,
  });

  final VoidCallback onBack;
  final String title;
  final String subtitle;

  /// An extra line under the subtitle — the OTP screen puts the number here.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      color: JhColors.surface,
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              JhRoundBackButton(onPressed: onBack),
              const Spacer(),
              const JhBrandLockup(tileSize: 30, wordSize: 16),
              const Spacer(),
              const JhLangToggle(onDark: false),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: JhText.ui(
              size: 24,
              weight: FontWeight.w800,
              letterSpacing: -0.7,
              color: JhColors.ink,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: JhText.ui(
              size: 13.5,
              weight: FontWeight.w500,
              color: JhColors.textMuted,
              height: 1.5,
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 6), extra!],
        ],
      ),
    );
  }
}

/// A white circular back button with a soft lift — used on the light headers
/// (Account, the Send a Package wizard) rather than the translucent square on
/// the green bands.
class JhRoundBackButton extends StatelessWidget {
  const JhRoundBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: JhColors.surface,
            shape: BoxShape.circle,
            boxShadow: JhShadows.field,
          ),
          child: const Icon(JhIcons.back, size: 19, color: JhColors.ink),
        ),
      ),
    );
  }
}


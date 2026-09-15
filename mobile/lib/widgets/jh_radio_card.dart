import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// A tappable row with a leading radio dot — the package-size picker. Group
/// these in a column; the caller owns selection.
class JhRadioCard extends StatelessWidget {
  const JhRadioCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? JhColors.primaryTint : JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.control),
            border: Border.all(
              color: selected ? JhColors.primary : JhColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _Dot(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: JhText.ui(size: 14.5, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: JhText.ui(
                        size: 12,
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

class _Dot extends StatelessWidget {
  const _Dot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? JhColors.primary : JhColors.outlineButton,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: JhColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

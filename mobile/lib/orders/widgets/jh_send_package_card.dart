import 'package:flutter/widgets.dart';

import '../../theme/icons.dart';
import '../../theme/tokens.dart';

/// The orange "Send a Package" call-to-action. On Home and on My Orders.
///
/// Dark text on the orange fill, not white -- reads calmer than a white-on-
/// orange card, and the black circle+arrow reads as "go" without needing a
/// second colour.
class JhSendPackageCard extends StatelessWidget {
  const JhSendPackageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: JhColors.primary,
            borderRadius: BorderRadius.circular(JhRadii.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: JhText.ui(
                        size: 19,
                        weight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: JhColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: JhText.ui(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: JhColors.inkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: JhColors.brandCharcoal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  JhIcons.forward,
                  size: 19,
                  color: JhColors.onDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

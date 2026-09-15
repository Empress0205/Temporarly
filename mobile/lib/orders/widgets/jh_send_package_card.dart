import 'package:flutter/widgets.dart';

import '../../theme/icons.dart';
import '../../theme/tokens.dart';

/// The green "Send a Package" call-to-action. On Home and on My Orders.
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: JhColors.primaryText,
            borderRadius: BorderRadius.circular(JhRadii.card),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: JhColors.onDarkSurfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  JhIcons.box,
                  size: 22,
                  color: JhColors.onDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: JhText.ui(
                        size: 15.5,
                        weight: FontWeight.w800,
                        color: JhColors.onDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: JhText.ui(
                        size: 12,
                        weight: FontWeight.w500,
                        color: JhColors.onDarkFaint,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                JhIcons.chevron,
                size: 22,
                color: JhColors.onDarkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

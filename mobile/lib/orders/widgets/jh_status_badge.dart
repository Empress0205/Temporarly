import 'package:flutter/widgets.dart';

import '../../l10n/dict.dart';
import '../../theme/tokens.dart';
import '../order_models.dart';

/// The pill on an order card / detail screen showing where the order stands.
class JhStatusBadge extends StatelessWidget {
  const JhStatusBadge({super.key, required this.status, required this.t});

  final JhOrderStatus status;
  final JhStrings t;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      JhOrderStatus.inTransit => (JhColors.primaryTint, JhColors.primaryText),
      // The one place in the app the palette's Operations Green shows up --
      // a delivery actually completing is exactly the "success state" the
      // client's palette reserves it for.
      JhOrderStatus.completed => (JhColors.successBg, JhColors.success),
      JhOrderStatus.cancelled => (JhColors.dangerBg, JhColors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(JhRadii.pill),
      ),
      child: Text(
        status.label(t),
        style: JhText.ui(size: 11, weight: FontWeight.w800, color: fg),
      ),
    );
  }
}

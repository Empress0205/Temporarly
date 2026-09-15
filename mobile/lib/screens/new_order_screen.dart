import 'package:flutter/widgets.dart';

import '../orders/steps/delivery_mode_step.dart';
import '../orders/steps/package_step.dart';
import '../orders/steps/recipient_step.dart';
import '../orders/steps/review_step.dart';
import '../orders/steps/route_step.dart';
import '../widgets/jh_scope.dart';

/// The Send a Package wizard. One screen; the body is chosen by
/// `state.orderStep`.
class JhNewOrderScreen extends StatelessWidget {
  const JhNewOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final step = JhScope.of(context).orderStep;
    return switch (step) {
      1 => const JhRouteStep(),
      2 => const JhRecipientStep(),
      3 => const JhPackageStep(),
      4 => const JhDeliveryModeStep(),
      5 => const JhReviewStep(),
      _ => const SizedBox.shrink(),
    };
  }
}

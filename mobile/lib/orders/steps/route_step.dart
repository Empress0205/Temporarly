import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../../widgets/jh_scope.dart';
import 'destination_step.dart';
import 'pickup_step.dart';

/// Step 1 — the whole route, captured as "from here" then "to there" without
/// leaving the step.
class JhRouteStep extends StatelessWidget {
  const JhRouteStep({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (JhScope.of(context).routePhase) {
      JhRoutePhase.pickup => const JhPickupStep(),
      JhRoutePhase.dropoff => const JhDestinationStep(),
    };
  }
}

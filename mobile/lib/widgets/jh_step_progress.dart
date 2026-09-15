import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The row of segments at the top of the Send a Package wizard. `step` of
/// `total` segments are filled.
class JhStepProgress extends StatelessWidget {
  const JhStepProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < step ? JhColors.primary : JhColors.surfaceMuted,
                borderRadius: BorderRadius.circular(JhRadii.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

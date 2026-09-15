import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import '../../widgets/jh_header.dart';
import '../../widgets/jh_scaffold.dart';
import '../../widgets/jh_step_progress.dart';

/// The shared frame for every Send a Package step: a light header (back button,
/// progress bar, "Pickup · Step 1 of 6", step title) over the scroll-body /
/// pinned-footer composition the auth screens use.
class JhWizardScaffold extends StatelessWidget {
  const JhWizardScaffold({
    super.key,
    required this.step,
    required this.stepCount,
    required this.crumb,
    required this.stepLabel,
    required this.title,
    required this.onBack,
    required this.body,
    required this.footer,
    required this.toastVisible,
    this.subtitle,
  });

  final int step;
  final int stepCount;

  /// The step's own name, e.g. "Pickup".
  final String crumb;

  /// e.g. "Step 1 of 6".
  final String stepLabel;

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<Widget> body;
  final Widget footer;
  final bool toastVisible;

  @override
  Widget build(BuildContext context) {
    return JhAuthScaffold(
      toastVisible: toastVisible,
      header: _Header(
        step: step,
        stepCount: stepCount,
        crumb: crumb,
        stepLabel: stepLabel,
        title: title,
        subtitle: subtitle,
        onBack: onBack,
      ),
      body: body,
      footer: footer,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.stepCount,
    required this.crumb,
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final int step;
  final int stepCount;
  final String crumb;
  final String stepLabel;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Container(
      width: double.infinity,
      color: JhColors.background,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          JhRoundBackButton(onPressed: onBack),
          const SizedBox(height: 16),
          JhStepProgress(step: step, total: stepCount),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: crumb,
                  style: JhText.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: JhColors.primaryText,
                  ),
                ),
                TextSpan(
                  text: '  ·  $stepLabel',
                  style: JhText.ui(
                    size: 12,
                    weight: FontWeight.w600,
                    color: JhColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              title,
              style: JhText.ui(
                size: 22,
                weight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: JhText.ui(
                size: 13,
                weight: FontWeight.w500,
                color: JhColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

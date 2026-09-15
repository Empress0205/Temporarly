import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'jh_spinner.dart';

/// The filled green action at the bottom of every screen.
///
/// [enabled] false paints the `Primary disabled` token but keeps the button
/// looking tappable, per the handoff's "Disabled / inactive styling" note.
/// [busy] swaps in a spinner and blocks the tap, which is the same guard that
/// stops duplicate submissions.
class JhPrimaryButton extends StatelessWidget {
  const JhPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.busy = false,
    this.height = 56,
    this.radius = JhRadii.button,
    this.elevated = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool busy;
  final double height;
  final double radius;

  /// The coloured lift under the button. Off in the flatter second-pass look.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      child: GestureDetector(
        onTap: busy ? null : onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: active ? JhColors.primaryText : JhColors.primaryDisabled,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: active && elevated ? JhShadows.button : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                const JhSpinner(),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.button,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White button with a hairline border -- "Log in" on Welcome, "Cancel" in the
/// logout sheet.
class JhSecondaryButton extends StatelessWidget {
  const JhSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.fontSize = 16,
    this.radius = JhRadii.button,
    this.borderColor = JhColors.outlineButton,
    this.labelColor = JhColors.ink,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;
  final double fontSize;
  final double radius;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            label,
            style: JhText.ui(
              size: fontSize,
              weight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Destructive action. [filled] is the red block inside the logout sheet;
/// otherwise it is the outlined "Log out" row on Profile.
class JhDangerButton extends StatelessWidget {
  const JhDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.height = 54,
    this.fontSize = 15.5,
    this.radius = 16,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final double height;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? JhColors.danger : JhColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: filled
                ? null
                : Border.all(color: JhColors.dangerBorderStrong, width: 1.5),
          ),
          child: Text(
            label,
            style: JhText.ui(
              size: fontSize,
              weight: FontWeight.w800,
              color: filled ? JhColors.onDark : JhColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline green text action -- "Log in", "Register", "Resend code".
class JhTextLink extends StatelessWidget {
  const JhTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 13.5,
    this.color = JhColors.primaryText,
    this.underline = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final double fontSize;
  final Color color;
  final bool underline;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Lifts a 13px label to a 44px-tall tap target without changing the
          // visual rhythm of the row it sits in.
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            style: JhText.ui(
              size: fontSize,
              weight: FontWeight.w800,
              color: color,
            ).copyWith(
              decoration: underline ? TextDecoration.underline : null,
              decorationColor: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A prompt and its action on one centred line: "Already have an account? Log in".
class JhSwitchPrompt extends StatelessWidget {
  const JhSwitchPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // A Wrap rather than a Row: Swahili copy and large text scales both push
    // this line past the available width, and it should fold instead of
    // overflowing.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      children: [
        Text(
          prompt,
          style: JhText.ui(
            size: 13.5,
            weight: FontWeight.w600,
            color: JhColors.inkMuted,
          ),
        ),
        JhTextLink(label: action, onPressed: onPressed),
      ],
    );
  }
}

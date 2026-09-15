import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'jh_buttons.dart';

/// The `jhup` entry: rises 12px while fading in. Used by errors and the toast.
class JhRise extends StatelessWidget {
  const JhRise({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// The shared error slot on the phone, register and change-phone screens:
/// red copy plus, when the failure has a way out, an underlined recovery
/// action (spec 15).
class JhInlineError extends StatelessWidget {
  const JhInlineError({
    super.key,
    required this.message,
    this.action = '',
    this.onAction,
  });

  final String message;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return JhRise(
      key: ValueKey(message + action),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: JhText.ui(
                size: 13,
                weight: FontWeight.w600,
                color: JhColors.danger,
                height: 1.45,
              ),
            ),
            if (action.isNotEmpty && onAction != null)
              JhTextLink(
                label: action,
                onPressed: onAction!,
                fontSize: 13,
                underline: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// The tinted error panel on the OTP screen.
class JhErrorBlock extends StatelessWidget {
  const JhErrorBlock({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return JhRise(
      key: ValueKey(message),
      child: Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: JhColors.dangerBg,
          borderRadius: BorderRadius.circular(JhRadii.control),
          border: Border.all(color: JhColors.dangerBorder),
        ),
        child: Text(
          message,
          style: JhText.ui(
            size: 13,
            weight: FontWeight.w600,
            color: JhColors.danger,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

/// Transient confirmation, pinned above the primary action. The body padding
/// on auth screens grows while this is up so it can never cover the button.
class JhToast extends StatelessWidget {
  const JhToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return JhRise(
      key: ValueKey(message),
      duration: JhMotion.rise,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: JhColors.surface,
          borderRadius: BorderRadius.circular(JhRadii.cardSmall),
          border: Border.all(color: const Color(0x3800803F)),
          boxShadow: JhShadows.toast,
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: JhColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: JhText.ui(
                  size: 13.5,
                  weight: FontWeight.w700,
                  color: JhColors.toastText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

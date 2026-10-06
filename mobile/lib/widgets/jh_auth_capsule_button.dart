import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'jh_spinner.dart';

/// Full capsule, dark text on orange -- the Register/OTP reference's button
/// language, shared by the two screens that use it.
class JhAuthCapsuleButton extends StatelessWidget {
  const JhAuthCapsuleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.busy = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !busy;
    return Semantics(
      button: true,
      enabled: active,
      label: label,
      child: GestureDetector(
        onTap: active ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? JhColors.primary : JhColors.primaryDisabled,
            borderRadius: BorderRadius.circular(height / 2),
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
                  style: JhText.ui(
                    size: 16,
                    weight: FontWeight.w800,
                    color: JhColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

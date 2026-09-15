import 'package:flutter/widgets.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';

/// A checkbox with an inline label — the whole row is the tap target.
class JhCheckbox extends StatelessWidget {
  const JhCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.label,
    this.hasError = false,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? JhColors.danger
        : checked
        ? JhColors.primary
        : JhColors.outlineButton;

    return Semantics(
      button: true,
      checked: checked,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!checked),
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? JhColors.primary : JhColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: checked
                  ? const Icon(JhIcons.check, size: 13, color: JhColors.onDark)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: JhText.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: JhColors.inkMuted,
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

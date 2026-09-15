import 'package:flutter/widgets.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';

/// `[−] value [+]` quantity control. Buttons dim and stop responding at the
/// bounds.
class JhStepper extends StatelessWidget {
  const JhStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Button(
          icon: JhIcons.minus,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: JhText.mono(size: 17),
          ),
        ),
        _Button(
          icon: JhIcons.plus,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JhColors.surfaceMuted,
            borderRadius: BorderRadius.circular(JhRadii.control),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? JhColors.primaryText : JhColors.textFaint,
          ),
        ),
      ),
    );
  }
}

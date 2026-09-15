import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

class JhChoice<T> {
  const JhChoice({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A wrap of single-select pill chips — the package-type picker.
class JhChoiceChipGrid<T> extends StatelessWidget {
  const JhChoiceChipGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<JhChoice<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in options)
          _Chip(
            label: option.label,
            icon: option.icon,
            selected: option.value == selected,
            onTap: () => onSelected(option.value),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? JhColors.onDark : JhColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? JhColors.primaryText : JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.pill),
            border: Border.all(
              color: selected ? JhColors.primaryText : JhColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: JhText.ui(size: 13, weight: FontWeight.w700, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

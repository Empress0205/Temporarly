import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

class JhChoice<T> {
  const JhChoice({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A fixed 2-column grid of single-select pill chips — the package-type
/// picker. Each chip fills its column, so rows stay even instead of the
/// ragged trailing gap a text-sized [Wrap] leaves behind an odd item.
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
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      final left = options[i];
      final right = i + 1 < options.length ? options[i + 1] : null;
      rows.add(
        Row(
          children: [
            Expanded(
              child: _Chip(
                label: left.label,
                icon: left.icon,
                selected: left.value == selected,
                onTap: () => onSelected(left.value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _Chip(
                      label: right.label,
                      icon: right.icon,
                      selected: right.value == selected,
                      onTap: () => onSelected(right.value),
                    ),
            ),
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JhText.ui(size: 13, weight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

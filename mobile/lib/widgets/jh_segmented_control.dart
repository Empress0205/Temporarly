import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

class JhSegment<T> {
  const JhSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// A pill-framed row of mutually exclusive options — the Active / Completed /
/// Cancelled switch on My Orders.
class JhSegmentedControl<T> extends StatelessWidget {
  const JhSegmentedControl({
    super.key,
    required this.segments,
    required this.current,
    required this.onChanged,
  });

  final List<JhSegment<T>> segments;
  final T current;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: JhColors.surfaceMuted,
        borderRadius: BorderRadius.circular(JhRadii.control),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _Segment(
                label: segment.label,
                selected: segment.value == current,
                onTap: () => onChanged(segment.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: JhMotion.sheet,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? JhColors.surface : null,
            borderRadius: BorderRadius.circular(JhRadii.control - 2),
            boxShadow: selected ? JhShadows.field : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: JhText.ui(
              size: 13,
              weight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? JhColors.primaryText : JhColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

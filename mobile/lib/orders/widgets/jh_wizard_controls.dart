import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import '../../widgets/jh_fields.dart';

/// Full capsule, dark text on orange -- the button language shared by every
/// redesigned wizard step (Pickup, Package, Destination, ...).
class JhContinueCapsule extends StatelessWidget {
  const JhContinueCapsule({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  static const _height = 56.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? JhColors.primary : JhColors.primaryDisabled,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: JhText.ui(size: 16, weight: FontWeight.w800, color: JhColors.ink),
          ),
        ),
      ),
    );
  }
}

/// The small uppercase, tracked-letter-spacing group header used above a
/// cluster of fields or choices ("ADDRESS", "LANDMARK", "TYPE", ...) --
/// distinct from [JhFieldLabel], which stays plain sentence case for an
/// actual input's own label (Register/Login).
class JhSectionLabel extends StatelessWidget {
  const JhSectionLabel(this.text, {super.key, this.color = JhColors.textFaint});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: JhText.ui(
      size: 11,
      weight: FontWeight.w800,
      letterSpacing: 0.6,
      color: color,
    ),
  );
}

/// Read-only text with a bottom-rule underline -- for a value the customer
/// didn't type (a resolved address), styled like the editable field next to
/// it rather than as plain body text.
class JhUnderlineDisplay extends StatelessWidget {
  const JhUnderlineDisplay({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: JhColors.cardBorder)),
      ),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: JhText.ui(size: 15, weight: FontWeight.w800),
      ),
    );
  }
}

/// A borderless field with just a bottom rule -- e.g. "Landmark",
/// "Describe the item".
class JhUnderlineField extends StatefulWidget {
  const JhUnderlineField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.placeholder,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  State<JhUnderlineField> createState() => _JhUnderlineFieldState();
}

class _JhUnderlineFieldState extends State<JhUnderlineField>
    with JhControllerSync<JhUnderlineField> {
  @override
  Widget build(BuildContext context) {
    syncController(widget.value);
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: JhColors.cardBorder)),
      ),
      child: EditableTextField(
        controller: controller,
        onChanged: widget.onChanged,
        placeholder: widget.placeholder,
        style: JhText.ui(size: 15, weight: FontWeight.w600),
      ),
    );
  }
}

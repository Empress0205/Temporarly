import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'jh_fields.dart';

/// Six code cells with a single transparent field laid over them.
///
/// The overlay owns the value, exactly as in the prototype: the cells are
/// presentation only, so paste, backspace and the system keyboard all behave
/// like a normal single input.
class JhOtpInput extends StatefulWidget {
  const JhOtpInput({
    super.key,
    required this.value,
    required this.length,
    required this.onChanged,
    required this.hasError,
    required this.locked,
    this.onSubmitted,
  });

  final String value;
  final int length;
  final ValueChanged<String> onChanged;
  final bool hasError;

  /// True after the attempt limit is reached; the field stays disabled until a
  /// new code is requested (spec 13).
  final bool locked;

  final VoidCallback? onSubmitted;

  @override
  State<JhOtpInput> createState() => _JhOtpInputState();
}

class _JhOtpInputState extends State<JhOtpInput>
    with JhControllerSync<JhOtpInput> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    syncController(widget.value);
    final filled = widget.value.length;

    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              Expanded(
                child: _Cell(
                  char: i < filled ? widget.value[i] : '',
                  active: i == filled && !widget.locked,
                  hasError: widget.hasError,
                ),
              ),
            ],
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: _focus,
              enabled: !widget.locked,
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              keyboardType: TextInputType.number,
              showCursor: false,
              style: JhText.mono(size: 24),
              // The formatters cap the length; `maxLength` is avoided because
              // its counter would add height to the overlay.
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.char,
    required this.active,
    required this.hasError,
  });

  final String char;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = char.isNotEmpty;
    final border = hasError
        ? JhColors.dangerField
        : active
        ? JhColors.primary
        : filled
        ? const Color(0x290F1A15) // rgba(15,26,21,.16)
        : JhColors.cardBorder;

    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? JhColors.surface : JhColors.cellEmpty,
        borderRadius: BorderRadius.circular(JhRadii.control),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(
        char,
        style: JhText.mono(
          size: 24,
          color: filled ? JhColors.ink : JhColors.inkFaint,
        ),
      ),
    );
  }
}

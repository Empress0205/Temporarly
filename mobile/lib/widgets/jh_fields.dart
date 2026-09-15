import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Border colour for a control: neutral, or red on an actual error. A filled
/// field no longer gets a colour of its own -- a green "valid" border on
/// every field someone has typed into was noise, not information; error is
/// the only state worth a colour here.
Color jhFieldBorder({required bool hasError}) {
  if (hasError) return JhColors.dangerField;
  return JhColors.cardBorder;
}

/// The white 58px control shell shared by the text and phone fields.
class JhFieldShell extends StatelessWidget {
  const JhFieldShell({
    super.key,
    required this.child,
    required this.borderColor,
    this.height = 58,
  });

  final Widget child;
  final Color borderColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.control),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Label above a control, in its own sentence case rather than shouted in
/// small caps -- matching the plainer reference look (a label just reads as
/// a label, not as a block of tracked capitals).
class JhFieldLabel extends StatelessWidget {
  const JhFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: JhText.fieldLabel);
}

/// A labelled field with an optional error line beneath it.
class JhLabeledField extends StatelessWidget {
  const JhLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.error = '',
  });

  final String label;
  final Widget child;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JhFieldLabel(label),
        const SizedBox(height: 8),
        child,
        if (error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            error,
            style: JhText.ui(
              size: 13,
              weight: FontWeight.w600,
              color: JhColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}

/// Keeps a [TextEditingController] in step with a value owned by app state,
/// without stealing the caret while the user types.
mixin JhControllerSync<T extends StatefulWidget> on State<T> {
  final TextEditingController controller = TextEditingController();

  void syncController(String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Plain text control -- name and email on the registration page.
class JhTextField extends StatefulWidget {
  const JhTextField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.placeholder,
    required this.hasError,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
    this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool hasError;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final VoidCallback? onSubmitted;

  @override
  State<JhTextField> createState() => _JhTextFieldState();
}

class _JhTextFieldState extends State<JhTextField>
    with JhControllerSync<JhTextField> {
  @override
  Widget build(BuildContext context) {
    syncController(widget.value);
    return JhFieldShell(
      borderColor: jhFieldBorder(hasError: widget.hasError),
      child: Center(
        child: EditableTextField(
          controller: controller,
          onChanged: widget.onChanged,
          placeholder: widget.placeholder,
          style: JhText.input,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}

/// The phone control: a fixed `+255`, a hairline divider, then nine digits in
/// mono. The country code is display-only -- state stores the digits alone.
class JhPhoneField extends StatefulWidget {
  const JhPhoneField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hasError,
    this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final VoidCallback? onSubmitted;

  @override
  State<JhPhoneField> createState() => _JhPhoneFieldState();
}

class _JhPhoneFieldState extends State<JhPhoneField>
    with JhControllerSync<JhPhoneField> {
  @override
  Widget build(BuildContext context) {
    syncController(widget.value);
    return JhFieldShell(
      borderColor: jhFieldBorder(hasError: widget.hasError),
      child: Row(
        children: [
          Text(
            '+255',
            style: JhText.mono(size: 17, color: JhColors.inkMuted),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: JhColors.divider),
          const SizedBox(width: 10),
          Expanded(
            child: EditableTextField(
              controller: controller,
              onChanged: widget.onChanged,
              placeholder: '712 345 678',
              style: JhText.monoInput,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
              ],
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-line entry for the optional "instructions" / "description" inputs in
/// the Send a Package flow. Same border states as the single-line fields, but
/// grows with its content and aligns text to the top.
class JhTextArea extends StatefulWidget {
  const JhTextArea({
    super.key,
    required this.value,
    required this.onChanged,
    required this.placeholder,
    this.minLines = 3,
    this.maxLines = 5,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final int minLines;
  final int maxLines;

  @override
  State<JhTextArea> createState() => _JhTextAreaState();
}

class _JhTextAreaState extends State<JhTextArea>
    with JhControllerSync<JhTextArea> {
  @override
  Widget build(BuildContext context) {
    syncController(widget.value);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.control),
        border: Border.all(
          color: jhFieldBorder(hasError: false),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: widget.onChanged,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        style: JhText.input,
        cursorColor: JhColors.primary,
        cursorWidth: 1.6,
        cursorRadius: const Radius.circular(1),
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration.collapsed(
          hintText: widget.placeholder,
          hintStyle: JhText.input.copyWith(color: JhColors.inkPlaceholder),
        ),
      ),
    );
  }
}

/// A borderless text entry that inherits the surrounding shell's chrome. The
/// visible border, height and shadow belong to [JhFieldShell], so the control
/// itself is stripped of all decoration.
class EditableTextField extends StatelessWidget {
  const EditableTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.placeholder,
    required this.style,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final TextStyle style;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      enabled: enabled,
      style: style,
      cursorColor: JhColors.primary,
      cursorWidth: 1.6,
      cursorRadius: const Radius.circular(1),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      textInputAction:
          onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      decoration: InputDecoration.collapsed(
        hintText: placeholder,
        hintStyle: style.copyWith(color: JhColors.inkPlaceholder),
      ),
    );
  }
}

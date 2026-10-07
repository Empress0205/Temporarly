import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../l10n/dict.dart';
import '../../state/app_state.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_checkbox.dart';
import '../../widgets/jh_choice_chip_grid.dart';
import '../../widgets/jh_fields.dart';
import '../../widgets/jh_scope.dart';
import '../../widgets/jh_stepper.dart';
import '../order_models.dart';
import '../widgets/jh_wizard_controls.dart';
import '../widgets/jh_wizard_scaffold.dart';

/// Step 3 — what is being sent.
class JhPackageStep extends StatelessWidget {
  const JhPackageStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final draft = state.draft;

    return JhWizardScaffold(
      step: 3,
      stepCount: JhAppState.orderStepCount,
      crumb: t.stepTitlePackage,
      stepLabel: state.stepLabel(3),
      title: t.packageTitle,
      onBack: state.back,
      toastVisible: state.toast.isNotEmpty,
      body: [
        JhSectionLabel(t.packageTypeLabel),
        const SizedBox(height: 10),
        JhChoiceChipGrid<JhPackageType>(
          selected: draft.packageType,
          onSelected: state.setPackageType,
          options: [
            for (final type in JhPackageType.values)
              JhChoice(value: type, label: type.label(t), icon: type.icon),
          ],
        ),
        // Only "Other" needs a free-text clarification -- every other type
        // already says what it is.
        if (draft.packageType == JhPackageType.other) ...[
          const SizedBox(height: 18),
          JhSectionLabel(t.describeItemLabel, color: JhColors.primaryText),
          const SizedBox(height: 8),
          JhUnderlineField(
            value: draft.packageDescription,
            onChanged: state.setPackageDescription,
            placeholder: t.packageDescriptionHint,
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: JhSectionLabel(t.packageSizeLabel)),
            JhSectionLabel(t.quantityLabel),
            const SizedBox(width: 10),
            JhStepper(value: draft.quantity, onChanged: state.setQuantity),
          ],
        ),
        const SizedBox(height: 10),
        _SizeGrid(
          selected: draft.packageSize,
          onSelected: state.setPackageSize,
          t: t,
        ),
        const SizedBox(height: 20),
        const _PhotoAttach(),
        const SizedBox(height: 20),
        _HandlingNotes(
          value: draft.handlingInstructions,
          onChanged: state.setHandlingInstructions,
          t: t,
        ),
        const SizedBox(height: 20),
        _DeclarationBox(
          title: t.declarationTitle,
          body: t.declarationBody,
          agree: t.declarationAgree,
          checked: draft.declarationAccepted,
          error: state.declarationErr,
          onChanged: state.setDeclarationAccepted,
        ),
      ],
      footer: JhContinueCapsule(
        label: t.continueLabel,
        onPressed: state.nextOrderStep,
      ),
    );
  }
}

/// Three cards in a row -- an outline, not a fill, marks the selected size,
/// matching the mockup rather than the single-column radio list this used to
/// be.
class _SizeGrid extends StatelessWidget {
  const _SizeGrid({
    required this.selected,
    required this.onSelected,
    required this.t,
  });

  final JhPackageSize selected;
  final ValueChanged<JhPackageSize> onSelected;
  final JhStrings t;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final size in JhPackageSize.values) ...[
          if (size != JhPackageSize.values.first) const SizedBox(width: 10),
          Expanded(
            child: _SizeCard(
              label: size.label(t),
              subtitle: size.sub(t),
              selected: size == selected,
              onTap: () => onSelected(size),
            ),
          ),
        ],
      ],
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.control),
            border: Border.all(
              color: selected ? JhColors.primary : JhColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                JhIcons.box,
                size: 17,
                color: selected ? JhColors.primaryText : JhColors.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JhText.ui(size: 13, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JhText.ui(
                  size: 10.5,
                  weight: FontWeight.w500,
                  color: JhColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional evidence of what's being handed over -- useful to the courier at
/// pickup and, later, to either side in a dispute. Bytes only; there is
/// nowhere to upload it to yet.
class _PhotoAttach extends StatelessWidget {
  const _PhotoAttach();

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final photo = state.draft.packagePhoto;

    if (photo != null) {
      return _PhotoThumb(
        bytes: photo,
        removeLabel: t.removePhotoLabel,
        onRemove: state.removePackagePhoto,
      );
    }
    return Row(
      children: [
        Expanded(
          child: _PhotoPickButton(
            icon: JhIcons.camera,
            label: t.takePhoto,
            caption: t.optionalSuffix,
            onTap: () => state.pickPackagePhoto(fromCamera: true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PhotoPickButton(
            icon: JhIcons.gallery,
            label: t.chooseFromGallery,
            caption: t.optionalSuffix,
            onTap: () => state.pickPackagePhoto(fromCamera: false),
          ),
        ),
      ],
    );
  }
}

class _PhotoPickButton extends StatelessWidget {
  const _PhotoPickButton({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. $caption',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.control),
            border: Border.all(color: JhColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: JhColors.primaryText),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JhText.ui(size: 12, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: JhText.ui(
                  size: 10.5,
                  weight: FontWeight.w500,
                  color: JhColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.bytes,
    required this.removeLabel,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(JhRadii.control),
          child: Image.memory(
            bytes,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Semantics(
            button: true,
            label: removeLabel,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: JhColors.scrim,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  JhIcons.removePhoto,
                  size: 16,
                  color: JhColors.onDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The handling-notes textarea, a live character counter next to its label,
/// and a row of one-tap suggestion chips that add or remove themselves from
/// the text -- tapping "Fragile" twice leaves the note the way it started.
class _HandlingNotes extends StatelessWidget {
  const _HandlingNotes({
    required this.value,
    required this.onChanged,
    required this.t,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final JhStrings t;

  static const _maxLength = 140;

  void _toggle(String word) {
    final has = value
        .split(',')
        .map((w) => w.trim())
        .contains(word);
    final parts = value
        .split(',')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    if (has) {
      parts.remove(word);
    } else {
      parts.add(word);
    }
    onChanged(parts.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      t.handlingChipFragile,
      t.handlingChipUpright,
      t.handlingChipCold,
    ];
    final active = value.split(',').map((w) => w.trim()).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(JhIcons.edit, size: 13, color: JhColors.textFaint),
            const SizedBox(width: 6),
            JhSectionLabel(t.handlingLabel),
            const Spacer(),
            Text(
              '${value.length}/$_maxLength',
              style: JhText.mono(size: 10.5, color: JhColors.textFaint),
            ),
          ],
        ),
        const SizedBox(height: 8),
        JhTextArea(
          value: value,
          onChanged: (v) =>
              onChanged(v.length > _maxLength ? v.substring(0, _maxLength) : v),
          placeholder: t.handlingHint,
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              _SuggestionChip(
                label: chip,
                active: active.contains(chip),
                onTap: () => _toggle(chip),
              ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? JhColors.primaryTint : JhColors.surfaceMuted,
            borderRadius: BorderRadius.circular(JhRadii.pill),
          ),
          child: Text(
            label,
            style: JhText.ui(
              size: 12,
              weight: FontWeight.w700,
              color: active ? JhColors.primaryText : JhColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeclarationBox extends StatelessWidget {
  const _DeclarationBox({
    required this.title,
    required this.body,
    required this.agree,
    required this.checked,
    required this.error,
    required this.onChanged,
  });

  final String title;
  final String body;
  final String agree;
  final bool checked;
  final String error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JhColors.surfaceMuted,
        borderRadius: BorderRadius.circular(JhRadii.control),
        border: Border.all(
          color: error.isEmpty ? JhColors.cardBorder : JhColors.dangerField,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: JhText.ui(size: 13.5, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            body,
            style: JhText.ui(
              size: 12,
              weight: FontWeight.w500,
              color: JhColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          JhCheckbox(
            checked: checked,
            onChanged: onChanged,
            label: agree,
            hasError: error.isNotEmpty,
          ),
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
      ),
    );
  }
}

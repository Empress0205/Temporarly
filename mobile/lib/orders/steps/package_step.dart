import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../../theme/icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_buttons.dart';
import '../../widgets/jh_checkbox.dart';
import '../../widgets/jh_choice_chip_grid.dart';
import '../../widgets/jh_fields.dart';
import '../../widgets/jh_radio_card.dart';
import '../../widgets/jh_scope.dart';
import '../../widgets/jh_stepper.dart';
import '../order_models.dart';
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
      subtitle: t.packageSub,
      onBack: state.back,
      toastVisible: state.toast.isNotEmpty,
      body: [
        JhFieldLabel(t.packageTypeLabel),
        const SizedBox(height: 10),
        JhChoiceChipGrid<JhPackageType>(
          selected: draft.packageType,
          onSelected: state.setPackageType,
          options: [
            for (final type in JhPackageType.values)
              JhChoice(value: type, label: type.label(t), icon: type.icon),
          ],
        ),
        const SizedBox(height: 20),
        JhFieldLabel(t.packageSizeLabel),
        const SizedBox(height: 10),
        for (final size in JhPackageSize.values) ...[
          JhRadioCard(
            title: size.label(t),
            subtitle: size.sub(t),
            selected: draft.packageSize == size,
            onTap: () => state.setPackageSize(size),
          ),
          if (size != JhPackageSize.large) const SizedBox(height: 8),
        ],
        const SizedBox(height: 20),
        JhFieldLabel(t.quantityLabel),
        const SizedBox(height: 10),
        JhStepper(value: draft.quantity, onChanged: state.setQuantity),
        const SizedBox(height: 20),
        JhLabeledField(
          label: '${t.packageDescriptionLabel} (${t.optionalSuffix})',
          child: JhTextArea(
            value: draft.packageDescription,
            onChanged: state.setPackageDescription,
            placeholder: t.packageDescriptionHint,
          ),
        ),
        const SizedBox(height: 18),
        JhLabeledField(
          label: '${t.handlingLabel} (${t.optionalSuffix})',
          child: JhTextArea(
            value: draft.handlingInstructions,
            onChanged: state.setHandlingInstructions,
            placeholder: t.handlingHint,
            minLines: 1,
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 20),
        const _PhotoAttach(),
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
      footer: JhPrimaryButton(
        label: t.continueLabel,
        onPressed: state.nextOrderStep,
        radius: JhRadii.control,
        elevated: false,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JhFieldLabel('${t.attachPhotoLabel} (${t.optionalSuffix})'),
        const SizedBox(height: 10),
        if (photo != null)
          _PhotoThumb(
            bytes: photo,
            removeLabel: t.removePhotoLabel,
            onRemove: state.removePackagePhoto,
          )
        else ...[
          Text(
            t.attachPhotoHint,
            style: JhText.ui(
              size: 12,
              weight: FontWeight.w500,
              color: JhColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PhotoPickButton(
                  icon: JhIcons.camera,
                  label: t.takePhoto,
                  onTap: () => state.pickPackagePhoto(fromCamera: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PhotoPickButton(
                  icon: JhIcons.gallery,
                  label: t.chooseFromGallery,
                  onTap: () => state.pickPackagePhoto(fromCamera: false),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhotoPickButton extends StatelessWidget {
  const _PhotoPickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: JhColors.surface,
            borderRadius: BorderRadius.circular(JhRadii.control),
            boxShadow: JhShadows.card,
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

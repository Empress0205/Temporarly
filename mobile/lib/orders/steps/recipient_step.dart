import 'package:flutter/widgets.dart';

import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/jh_buttons.dart';
import '../../widgets/jh_fields.dart';
import '../../widgets/jh_scope.dart';
import '../widgets/jh_wizard_scaffold.dart';

/// Step 2 — who receives the package.
class JhRecipientStep extends StatelessWidget {
  const JhRecipientStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final draft = state.draft;

    return JhWizardScaffold(
      step: 2,
      stepCount: JhAppState.orderStepCount,
      crumb: t.stepTitleRecipient,
      stepLabel: state.stepLabel(2),
      title: t.recipientTitle,
      subtitle: t.recipientSub,
      onBack: state.back,
      toastVisible: state.toast.isNotEmpty,
      body: [
        JhLabeledField(
          label: t.recipientNameLabel,
          error: state.recipientNameErr,
          child: JhTextField(
            value: draft.recipientName,
            onChanged: state.setRecipientName,
            placeholder: t.recipientNameHint,
            hasError: state.recipientNameErr.isNotEmpty,
          ),
        ),
        const SizedBox(height: 18),
        JhLabeledField(
          label: t.recipientPhoneLabel,
          error: state.recipientPhoneErr,
          child: JhPhoneField(
            value: draft.recipientPhone,
            onChanged: state.setRecipientPhone,
            hasError: state.recipientPhoneErr.isNotEmpty,
          ),
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

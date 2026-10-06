import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/jh_auth_capsule_button.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_feedback.dart';
import '../widgets/jh_fields.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// Single-page registration: name, email and phone collected together.
///
/// This is the agreed deviation from the spec's section 6 recommendation. The
/// code goes out on submit and the account is created only once it verifies,
/// so nothing is persisted for an unverified number.
class JhRegisterScreen extends StatelessWidget {
  const JhRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final busy = state.loading == JhLoading.register;

    return JhAuthScaffold(
      toastVisible: state.toast.isNotEmpty,
      header: JhAuthHeader(
        onBack: state.back,
        title: t.registerTitle,
        subtitle: t.registerSubOne,
        showLockup: false,
      ),
      body: [
        JhLabeledField(
          label: t.fullName,
          error: state.nameErr,
          child: JhTextField(
            value: state.name,
            onChanged: state.setName,
            placeholder: t.namePlaceholder,
            hasError: state.nameErr.isNotEmpty,
          ),
        ),
        const SizedBox(height: 16),
        JhLabeledField(
          label: t.email,
          error: state.emailErr,
          child: JhTextField(
            value: state.email,
            onChanged: state.setEmail,
            placeholder: 'amina@example.com',
            hasError: state.emailErr.isNotEmpty,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
          ),
        ),
        const SizedBox(height: 16),
        JhLabeledField(
          label: t.phoneLabel,
          child: JhPhoneField(
            value: state.phone,
            onChanged: state.setPhone,
            hasError: state.err.isNotEmpty && state.errKind == JhErrKind.none,
            onSubmitted: state.submitRegister,
          ),
        ),
        JhInlineError(
          message: state.err,
          action: state.errAction,
          onAction: state.followErrAction,
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JhAuthCapsuleButton(
            label: busy ? t.sending : t.createAccount,
            busy: busy,
            enabled: state.loading == JhLoading.none,
            onPressed: state.submitRegister,
          ),
          const SizedBox(height: 13),
          JhSwitchPrompt(
            prompt: t.haveAccount,
            action: t.login,
            onPressed: state.goLogin,
          ),
        ],
      ),
    );
  }
}

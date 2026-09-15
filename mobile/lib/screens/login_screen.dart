import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_feedback.dart';
import '../widgets/jh_fields.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// Phone-only login. No password, and an unregistered number is never turned
/// into an account here -- it offers the way to registration instead
/// (spec 16-19).
class JhLoginScreen extends StatelessWidget {
  const JhLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final busy = state.loading == JhLoading.phone;
    final isLogin = state.mode == JhMode.login;

    return JhAuthScaffold(
      toastVisible: state.toast.isNotEmpty,
      header: JhAuthHeader(
        onBack: state.back,
        title: isLogin ? t.loginTitle : t.registerTitle,
        subtitle: isLogin ? t.loginSub : t.registerSub,
      ),
      body: [
        JhLabeledField(
          label: t.phoneLabel,
          child: JhPhoneField(
            value: state.phone,
            onChanged: state.setPhone,
            hasError: state.err.isNotEmpty && state.errKind == JhErrKind.none,
            onSubmitted: state.submitPhone,
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
          JhPrimaryButton(
            label: busy
                ? t.sending
                : isLogin
                ? t.sendOtp
                : t.continueLabel,
            busy: busy,
            enabled: state.enteredPhoneValid && state.loading == JhLoading.none,
            onPressed: state.submitPhone,
            radius: JhRadii.control,
            elevated: false,
          ),
          const SizedBox(height: 14),
          JhSwitchPrompt(
            prompt: isLogin ? t.noAccount : t.haveAccount,
            action: isLogin ? t.register : t.login,
            onPressed: state.goRegister,
          ),
        ],
      ),
    );
  }
}

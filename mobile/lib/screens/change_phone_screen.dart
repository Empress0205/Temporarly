import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_feedback.dart';
import '../widgets/jh_fields.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// Change of the number that identifies the account (spec 23-25).
///
/// The stored number moves only after the new one verifies; any failure on the
/// way leaves it untouched.
class JhChangePhoneScreen extends StatelessWidget {
  const JhChangePhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final busy = state.loading == JhLoading.phone;

    return JhAuthScaffold(
      toastVisible: state.toast.isNotEmpty,
      header: JhAuthHeader(
        onBack: state.back,
        title: t.changePhone,
        subtitle: t.changePhoneSub,
      ),
      body: [
        _CurrentNumberCard(
          label: t.currentNumber,
          value: state.prettyAccountPhone,
        ),
        const SizedBox(height: 20),
        JhLabeledField(
          label: t.newNumber,
          child: JhPhoneField(
            value: state.phone,
            onChanged: state.setPhone,
            hasError: state.err.isNotEmpty,
            onSubmitted: state.submitPhone,
          ),
        ),
        JhInlineError(message: state.err),
      ],
      footer: JhPrimaryButton(
        label: busy ? t.sending : t.sendOtp,
        busy: busy,
        enabled: state.enteredPhoneValid && state.loading == JhLoading.none,
        onPressed: state.submitPhone,
        radius: JhRadii.control,
        elevated: false,
      ),
    );
  }
}

class _CurrentNumberCard extends StatelessWidget {
  const _CurrentNumberCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: JhColors.surface,
        borderRadius: BorderRadius.circular(JhRadii.otpCell),
        border: Border.all(color: JhColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: JhText.ui(
              size: 12,
              weight: FontWeight.w700,
              color: JhColors.inkSubtle,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: JhText.mono(size: 15)),
        ],
      ),
    );
  }
}

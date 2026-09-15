import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_feedback.dart';
import '../widgets/jh_header.dart';
import '../widgets/jh_otp_input.dart';
import '../widgets/jh_scaffold.dart';
import '../widgets/jh_scope.dart';

/// One verification screen shared by registration, login and phone change
/// (spec 8-13). What a correct code does depends on `mode`, not on this
/// screen.
class JhOtpScreen extends StatelessWidget {
  const JhOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final busy = state.loading == JhLoading.otp;
    final complete = state.otp.length == state.otpConfig.length;

    return JhAuthScaffold(
      toastVisible: state.toast.isNotEmpty,
      footerGap: 0,
      header: JhAuthHeader(
        onBack: state.back,
        title: t.verifyTitle,
        subtitle: t.verifySub,
        extra: Text(
          state.prettyEnteredPhone,
          style: JhText.mono(size: 15.5, color: JhColors.ink),
        ),
      ),
      body: [
        JhOtpInput(
          value: state.otp,
          length: state.otpConfig.length,
          onChanged: state.setOtp,
          hasError: state.err.isNotEmpty,
          locked: state.blocked,
          onSubmitted: state.verifyOtp,
        ),
        const SizedBox(height: 15),
        _TimerRow(state: state),
        JhErrorBlock(message: state.err),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JhPrimaryButton(
            label: busy
                ? (state.mode == JhMode.register ? t.creating : t.verifying)
                : t.verify,
            busy: busy,
            enabled: complete && !state.blocked && state.loading == JhLoading.none,
            onPressed: state.verifyOtp,
            radius: JhRadii.control,
            elevated: false,
          ),
        ],
      ),
    );
  }
}

/// Countdown on the left, resend on the right. The countdown turns red the
/// moment the code expires; resend is inert until its cooldown runs out.
class _TimerRow extends StatelessWidget {
  const _TimerRow({required this.state});

  final JhAppState state;

  static String _clock(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final expired = state.ttl <= 0;
    final cooling = state.cooldown > 0;

    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              expired
                  ? t.codeExpired
                  : '${t.codeExpiresIn} ${_clock(state.ttl)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: JhText.mono(
                size: 12.5,
                color: expired ? JhColors.danger : JhColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: JhTextLink(
              label: cooling ? '${t.resendIn} ${state.cooldown}s' : t.resend,
              onPressed: state.resend,
              enabled: !cooling,
              fontSize: 13,
              color: cooling ? JhColors.inkFaint : JhColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

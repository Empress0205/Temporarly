import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/jh_auth_capsule_button.dart';
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

    final cooling = state.cooldown > 0;

    return JhAuthScaffold(
      toastVisible: state.toast.isNotEmpty,
      footerGap: 0,
      header: JhAuthHeader(
        onBack: state.back,
        title: t.verifyTitle,
        subtitle: null,
        showLockup: false,
        titleGap: 140,
        extra: Text(
          state.prettyEnteredPhone,
          style: JhText.mono(
            size: 15.5,
            weight: FontWeight.w700,
            color: JhColors.primaryText,
          ),
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
      footer: Row(
        children: [
          Expanded(
            child: _ResendCapsule(
              label: t.resend,
              onPressed: cooling ? null : state.resend,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: JhAuthCapsuleButton(
              label: busy
                  ? (state.mode == JhMode.register ? t.creating : t.verifying)
                  : t.verify,
              busy: busy,
              enabled:
                  complete && !state.blocked && state.loading == JhLoading.none,
              onPressed: state.verifyOtp,
            ),
          ),
        ],
      ),
    );
  }
}

/// The countdown only -- resend now lives in the footer as its own button,
/// so this row is informational text, not a tap target.
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
          if (cooling)
            Flexible(
              child: Text(
                '${t.resendIn} ${state.cooldown}s',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JhText.mono(size: 12.5, color: JhColors.inkFaint),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full capsule, neutral fill -- the secondary half of the footer pair next
/// to [JhAuthCapsuleButton]'s Verify. Inert while cooling down.
class _ResendCapsule extends StatelessWidget {
  const _ResendCapsule({required this.label, required this.onPressed});

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
            color: JhColors.surfaceMuted,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: JhText.ui(
              size: 14,
              weight: FontWeight.w800,
              color: enabled ? JhColors.ink : JhColors.inkFaint,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import '../widgets/jh_buttons.dart';
import '../widgets/jh_scope.dart';

/// Delete-account confirmation. Built the same way as [JhLogoutSheet] --
/// there is no backend support for deletion yet (Sprint 1 is authentication
/// only), so confirming here acknowledges the request rather than performing
/// an action the server cannot carry out.
class JhDeleteAccountSheet extends StatefulWidget {
  const JhDeleteAccountSheet({super.key});

  @override
  State<JhDeleteAccountSheet> createState() => _JhDeleteAccountSheetState();
}

class _JhDeleteAccountSheetState extends State<JhDeleteAccountSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: JhMotion.sheet,
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.ease,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);
    final t = state.t;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: state.closeSheet,
            behavior: HitTestBehavior.opaque,
            child: FadeTransition(
              opacity: _curve,
              child: const ColoredBox(color: JhColors.scrim),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_curve),
            child: Container(
              padding: EdgeInsets.fromLTRB(22, 24, 22, 38 + bottomInset),
              decoration: const BoxDecoration(
                color: JhColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(JhRadii.sheet),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: JhColors.outlineButton,
                        borderRadius: BorderRadius.circular(JhRadii.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: JhColors.dangerBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        JhIcons.delete,
                        size: 24,
                        color: JhColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.deleteAccountConfirm,
                    textAlign: TextAlign.center,
                    style: JhText.ui(
                      size: 20,
                      weight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.deleteAccountConfirmSub,
                    textAlign: TextAlign.center,
                    style: JhText.ui(
                      size: 13.5,
                      weight: FontWeight.w400,
                      color: JhColors.inkMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.deleteAccountWarning,
                    textAlign: TextAlign.center,
                    style: JhText.ui(
                      size: 13.5,
                      weight: FontWeight.w800,
                      color: JhColors.danger,
                    ),
                  ),
                  const SizedBox(height: 22),
                  JhDangerButton(
                    label: t.deleteAccountCta,
                    onPressed: state.confirmDeleteAccount,
                    filled: true,
                    radius: JhRadii.control,
                  ),
                  const SizedBox(height: 10),
                  JhSecondaryButton(
                    label: t.cancel,
                    onPressed: state.closeSheet,
                    height: 54,
                    fontSize: 15.5,
                    radius: JhRadii.control,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

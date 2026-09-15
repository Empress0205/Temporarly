import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/cancel_order_sheet.dart';
import 'screens/change_phone_screen.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/delete_account_sheet.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/logout_sheet.dart';
import 'screens/my_orders_screen.dart';
import 'screens/new_order_screen.dart';
import 'screens/order_created_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme/icons.dart';
import 'theme/tokens.dart';
import 'widgets/jh_feedback.dart';
import 'widgets/jh_scope.dart';
import 'widgets/jh_tab_bar.dart';

class JihudumieApp extends StatefulWidget {
  const JihudumieApp({super.key, this.state});

  /// Injected by tests so they can drive the machine directly -- for example
  /// to exercise the offline path. Production builds leave this null.
  final JhAppState? state;

  @override
  State<JihudumieApp> createState() => _JihudumieAppState();
}

class _JihudumieAppState extends State<JihudumieApp> {
  late final JhAppState _state = widget.state ?? JhAppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JhScope(
      state: _state,
      child: MaterialApp(
        title: 'Jihudumie',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Manrope',
          scaffoldBackgroundColor: JhColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: JhColors.primary,
            primary: JhColors.primary,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: JhColors.primary,
            selectionColor: JhColors.primaryTint,
            selectionHandleColor: JhColors.primary,
          ),
        ),
        home: const JhAppShell(),
      ),
    );
  }
}

/// Renders the screen the state machine is on, plus the chrome that floats
/// above it: the tab bar, the toast and the logout sheet.
class JhAppShell extends StatelessWidget {
  const JhAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = JhScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every screen's top band is dark green, so status bar content is light.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: const Color(0x00000000),
        systemNavigationBarColor: JhColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (state.logoutOpen ||
              state.deleteAccountOpen ||
              state.cancelOrderOpen) {
            state.closeSheet();
          } else if (state.canGoBack) {
            state.back();
          }
        },
        child: Scaffold(
          backgroundColor: JhColors.background,
          // The design's screens each own their scrolling and keep the primary
          // action pinned, so the view must not resize under the keyboard.
          resizeToAvoidBottomInset: false,
          body: _PhoneFrame(
            child: Stack(
              children: [
                Positioned.fill(child: _screenFor(state)),
                if (state.isAuthedScreen)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: JhTabBar(
                      current: state.tab,
                      strings: state.t,
                      onSelect: state.selectTab,
                    ),
                  ),
                if (state.toast.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: state.isAuthedScreen
                        ? JhTabBar.heightOf(context) + 12
                        : 20,
                    child: JhToast(message: state.toast),
                  ),
                if (state.logoutOpen) const Positioned.fill(child: JhLogoutSheet()),
                if (state.deleteAccountOpen)
                  const Positioned.fill(child: JhDeleteAccountSheet()),
                if (state.cancelOrderOpen)
                  const Positioned.fill(child: JhCancelOrderSheet()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _screenFor(JhAppState state) => switch (state.screen) {
    JhScreen.splash => const JhSplashScreen(),
    JhScreen.welcome => const JhWelcomeScreen(),
    JhScreen.register => const JhRegisterScreen(),
    JhScreen.phone => const JhLoginScreen(),
    JhScreen.otp => const JhOtpScreen(),
    JhScreen.home => const JhHomeScreen(),
    JhScreen.shop => JhComingSoonScreen(
      title: state.t.shop,
      icon: JhIcons.tabShop,
    ),
    JhScreen.orders => const JhMyOrdersScreen(),
    JhScreen.profile => const JhProfileScreen(),
    JhScreen.changePhone => const JhChangePhoneScreen(),
    JhScreen.newOrder => const JhNewOrderScreen(),
    JhScreen.orderCreated => const JhOrderCreatedScreen(),
    JhScreen.orderDetail => const JhOrderDetailScreen(),
  };
}

/// The layouts were drawn for a handset. In a wide desktop or browser window
/// the app is centred at phone width instead of being stretched across it.
///
/// This keys off the platform rather than the width: a handset in landscape is
/// also wider than a phone frame, and there the app should fill the screen as
/// it always has.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  static const double _maxWidth = 460;

  static bool get _isLargeFormatPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_isLargeFormatPlatform) return child;
    if (MediaQuery.sizeOf(context).width <= _maxWidth) return child;

    return ColoredBox(
      color: const Color(0xFFE7EBE6),
      child: Center(
        child: SizedBox(
          width: _maxWidth,
          child: ClipRect(
            child: ColoredBox(color: JhColors.background, child: child),
          ),
        ),
      ),
    );
  }
}

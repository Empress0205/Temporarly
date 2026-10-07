import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_models.dart';
import '../api/auth_api.dart';
import '../l10n/dict.dart';
import '../orders/google_places_location_service.dart';
import '../orders/image_picker_photo_service.dart';
import '../orders/location_service.dart';
import '../orders/order_models.dart';
import '../orders/orders_api.dart';
import '../orders/photo_service.dart';

/// The screens of the Sprint 1 module, matching the `screen` value in the
/// handoff's "State Management" section.
enum JhScreen {
  splash,
  welcome,
  register,
  phone,
  otp,
  home,
  shop,
  orders,
  profile,
  changePhone,
  newOrder,
  orderCreated,
  orderDetail,
}

/// Within the pickup half of the Route step. Search-first, like the
/// drop-off half: `manual` is the normal interactive form (search + map),
/// and `locating` is only the brief moment while "Use Current Location"
/// resolves.
enum JhPickupMode { locating, manual }

/// The Route step (step 1) captures both endpoints, one after the other.
enum JhRoutePhase { pickup, dropoff }

/// Why the current OTP was requested.
enum JhMode { register, login, change }

/// Which request-bound button is currently in flight. Doubles as the guard
/// against duplicate submissions (handoff, "Loading", spec 39).
enum JhLoading { none, register, phone, otp }

/// Which recovery action to offer alongside the shared error (spec 15).
enum JhErrKind { none, toLogin, toRegister }

enum JhTab { home, shop, orders, account }

@immutable
class JhUser {
  const JhUser({
    required this.name,
    required this.email,
    required this.phone,
    this.createdAt,
  });

  final String name;
  final String email;

  /// Nine significant digits, without the +255 country code.
  final String phone;

  /// When the server created the account. Null only for the placeholder user
  /// shown before a session exists.
  final DateTime? createdAt;

  JhUser copyWith({String? name, String? email, String? phone}) => JhUser(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    createdAt: createdAt,
  );
}

/// OTP rules (spec 8-13).
///
/// Spec 43 requires all four to be backend configuration rather than constants
/// in the app, so these values are **replaced from the server's response**
/// every time a code is issued. The defaults here only cover the moment before
/// the first response arrives.
class JhOtpConfig {
  const JhOtpConfig({
    this.length = 6,
    this.ttlSeconds = 300,
    this.cooldownSeconds = 60,
    this.maxAttempts = 3,
  });

  /// Builds the config from what the server just told us.
  factory JhOtpConfig.fromChallenge(JhOtpChallenge challenge) => JhOtpConfig(
    length: challenge.otpLength,
    ttlSeconds: challenge.expiresIn,
    cooldownSeconds: challenge.resendAvailableIn,
    maxAttempts: challenge.maxAttempts,
  );

  final int length;
  final int ttlSeconds;
  final int cooldownSeconds;
  final int maxAttempts;
}

/// The whole Sprint 1 state machine.
///
/// Screens read from this and call its intent methods; none of them hold
/// business state of their own. Every rule that matters -- whether a number is
/// registered, whether a code is correct, how many attempts remain -- is
/// decided by the server (spec 37); this object translates the answer into
/// what the screens render.
class JhAppState extends ChangeNotifier {
  JhAppState({
    JhAuthApi? api,
    JhLocationService? location,
    JhPhotoService? photos,
    JhOrdersApi? ordersApi,
    bool checkSessionOnStart = true,
  }) : api = api ?? JhHttpAuthApi(),
       location = location ?? JhGooglePlacesLocationService(),
       photos = photos ?? JhImagePickerPhotoService(),
       ordersApi = ordersApi ?? JhHttpOrdersApi() {
    if (checkSessionOnStart) {
      unawaited(_resolveSession());
    }
  }

  final JhAuthApi api;

  /// Device location + geocoding for the Pickup step. Injected like [clock] so
  /// tests supply fixed coordinates and never touch a real GPS.
  final JhLocationService location;

  /// Camera/gallery access for the Package step's optional photo. Injected
  /// the same way -- tests never touch a real camera or file picker.
  final JhPhotoService photos;

  /// Create/list/cancel/rate against the real backend. Injected the same way
  /// as [api] -- tests substitute a fake.
  final JhOrdersApi ordersApi;

  /// Timings and limits, as last reported by the server.
  JhOtpConfig otpConfig = const JhOtpConfig();

  // --- Navigation -----------------------------------------------------------
  JhScreen screen = JhScreen.splash;
  JhMode mode = JhMode.register;
  JhTab tab = JhTab.home;

  // --- Form fields ----------------------------------------------------------
  String phone = '';
  String otp = '';
  String name = '';
  String email = '';

  // --- Errors ---------------------------------------------------------------
  String err = '';
  JhErrKind errKind = JhErrKind.none;
  String nameErr = '';
  String emailErr = '';

  // --- Request / OTP lifecycle ---------------------------------------------
  JhLoading loading = JhLoading.none;
  int attempts = 0;
  bool blocked = false;
  int ttl = 0;
  int cooldown = 0;

  // --- Chrome ---------------------------------------------------------------
  String toast = '';
  bool logoutOpen = false;
  bool deleteAccountOpen = false;
  bool cancelOrderOpen = false;
  JhLang lang = JhLang.en;

  /// The authenticated customer, or null before sign-in.
  JhUser? user;

  // --- Orders ---------------------------------------------------------------
  // Fetched from the real backend (`ordersApi`); the local list is a cache
  // populated by `loadOrders()`, not the source of truth. Cleared on logout.

  /// What the wizard's progress bar and "Step N of 5" label show. Route,
  /// Recipient, Package, Delivery, Review.
  static const int orderStepCount = 5;

  /// The last step. Step 5 "Send Package" commits the order.
  static const int orderStepMax = 5;

  final List<JhOrder> orders = [];
  JhOrderBucket ordersBucket = JhOrderBucket.active;

  /// True while `loadOrders()` has a request in flight.
  bool ordersLoading = false;

  /// True while the Review step's "Send Package" has a request in flight --
  /// guards against a double submission and drives the button's `busy` state.
  bool orderSubmitting = false;

  /// Pickup/drop-off points from past orders, most-recent-first, offered at
  /// the top of the Route step so a repeat sender can tap instead of typing.
  /// Populated when an order commits; local like the rest of Sprint 2.
  final List<JhPlace> recentPlaces = [];
  static const int _maxRecentPlaces = 5;

  JhOrderDraft draft = JhOrderDraft();
  int orderStep = 1;
  JhRoutePhase routePhase = JhRoutePhase.pickup;
  JhPickupMode pickupMode = JhPickupMode.manual;
  String pickupError = '';
  String dropoffError = '';
  JhOrder? selectedOrder;

  /// True while a step is open because "Edit" was tapped on Review -- its
  /// confirm/continue action then returns to Review instead of walking on.
  bool _editingFromReview = false;

  /// Real `flutter_map` when true; a deterministic placeholder when false
  /// (tests and goldens set it false, like [clock]).
  bool liveMap = true;

  String recipientNameErr = '';
  String recipientPhoneErr = '';
  String declarationErr = '';

  Timer? _toastTimer;
  Timer? _tickTimer;

  JhStrings get t => JhStrings.of(lang);

  /// The account shown on authenticated screens.
  ///
  /// Empty rather than a placeholder customer: showing invented identity on a
  /// screen that is meant to be authenticated is exactly what spec 34 forbids.
  JhUser get account =>
      user ?? const JhUser(name: '', email: '', phone: '');

  /// Screens that sit behind the tab bar, and so require a session.
  bool get isAuthedScreen => const {
    JhScreen.home,
    JhScreen.shop,
    JhScreen.orders,
    JhScreen.profile,
  }.contains(screen);

  // --- Phone helpers --------------------------------------------------------

  /// Reduces any input to the nine significant digits, dropping an
  /// international prefix, the +255 country code, and a leading national 0.
  ///
  /// Must stay identical to `normalise` in `backend/authentication/phone.py`:
  /// if the two ever disagree, the same person can end up with two accounts --
  /// one created by typing `0712...` and one by typing `+255712...`. The same
  /// table of cases is asserted on both sides.
  static String digitsOf(String value) => value
      .replaceAll(RegExp(r'\D'), '')
      .replaceFirst(RegExp(r'^00'), '')
      .replaceFirst(RegExp(r'^255'), '')
      .replaceFirst(RegExp(r'^0'), '');

  static bool isValidPhone(String digits) =>
      RegExp(r'^[67]\d{8}$').hasMatch(digits);

  /// `712345678` -> `+255 712 345 678`.
  static String prettyPhone(String value) {
    final d = digitsOf(value);
    final parts = [d.substring(0, d.length.clamp(0, 3))];
    if (d.length > 3) parts.add(d.substring(3, d.length.clamp(0, 6)));
    if (d.length > 6) parts.add(d.substring(6, d.length.clamp(0, 9)));
    return '+255 ${parts.join(' ').trim()}'.trim();
  }

  String get enteredDigits => digitsOf(phone);
  bool get enteredPhoneValid => isValidPhone(enteredDigits);
  String get prettyEnteredPhone => prettyPhone(enteredDigits);
  String get prettyAccountPhone => prettyPhone(account.phone);

  String get initials => account.name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// `9 September 2026`, from the date the server created the account.
  String get prettyMemberSince {
    final d = account.createdAt?.toLocal();
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// Source of the current time.
  ///
  /// Injectable because the dashboard greeting depends on the hour: reading
  /// the real clock inside the widget makes its golden change its own expected
  /// output at noon, so the test fails for a reason that has nothing to do
  /// with the code. Tests pin this; production leaves it alone.
  DateTime Function() clock = DateTime.now;

  /// The name the dashboard greets. Falls back to a neutral word when there is
  /// no session, so the header never reads "Good morning ,".
  String get greetingName {
    final first = account.name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? t.greetingFallback : first;
  }

  /// The recovery action offered under the shared error, if any.
  String get errAction => switch (errKind) {
    JhErrKind.toLogin => t.errTakenCta,
    JhErrKind.toRegister => t.errUnknownCta,
    JhErrKind.none => '',
  };

  // --- Session --------------------------------------------------------------

  /// Decides where the splash screen hands over (spec 34).
  ///
  /// Authenticated screens are never rendered on a session the server has not
  /// confirmed, so this asks before routing rather than trusting that a token
  /// exists on the device.
  Future<void> _resolveSession() async {
    var destination = JhScreen.welcome;
    try {
      if (await api.hasValidSession()) {
        user = await api.me();
        destination = JhScreen.home;
      }
    } on JhApiException {
      // Unreachable server at start-up is not a signed-in state.
      destination = JhScreen.welcome;
    }
    screen = destination;
    tab = JhTab.home;
    notifyListeners();
  }

  // --- Internals ------------------------------------------------------------

  void _clearErrors() {
    err = '';
    errKind = JhErrKind.none;
  }

  void flash(String message) {
    _toastTimer?.cancel();
    toast = message;
    notifyListeners();
    _toastTimer = Timer(const Duration(milliseconds: 3200), () {
      toast = '';
      notifyListeners();
    });
  }

  /// Runs [action] behind a loading state. Returns early when a request is
  /// already in flight, which is what stops duplicate submissions.
  Future<void> _busy(JhLoading key, Future<void> Function() action) async {
    if (loading != JhLoading.none) return;
    loading = key;
    _clearErrors();
    notifyListeners();

    try {
      await action();
    } on JhApiException catch (error) {
      _applyError(error);
    } finally {
      loading = JhLoading.none;
      notifyListeners();
    }
  }

  /// Turns a server failure into the copy and state the screens render.
  ///
  /// The branch is on `code`, never on the server's message: that text is
  /// English-only and meant for logs, while the customer may be reading
  /// Swahili.
  void _applyError(JhApiException error) {
    switch (error.code) {
      case JhErrorCode.phoneAlreadyRegistered:
        err = t.errTaken;
        errKind = JhErrKind.toLogin;

      case JhErrorCode.phoneNotRegistered:
        err = t.errUnknown;
        errKind = JhErrKind.toRegister;

      case JhErrorCode.phoneSameAsCurrent:
        err = t.errSame;

      case JhErrorCode.phoneBelongsToOther:
        err = t.errOther;

      case JhErrorCode.accountSuspended:
        err = t.errSuspended;

      case JhErrorCode.otpIncorrect:
        otp = '';
        final remaining = error.attemptsRemaining;
        attempts = remaining == null
            ? attempts + 1
            : otpConfig.maxAttempts - remaining;
        err = remaining == null
            ? t.errOtp
            : '${t.errOtp} ($remaining ${t.attemptsLeft})';

      case JhErrorCode.otpExpired:
        otp = '';
        ttl = 0;
        err = t.errOtpExpired;

      case JhErrorCode.otpAttemptsExceeded:
        otp = '';
        blocked = true;
        attempts = otpConfig.maxAttempts;
        err = t.errAttempts;

      case JhErrorCode.otpNotFound:
        // The code was consumed, superseded or never issued. Sending the
        // customer back to re-enter their number is the only way forward.
        err = t.errOtpExpired;

      case JhErrorCode.otpResendTooSoon:
        cooldown = error.retryAfterSeconds ?? cooldown;
        err = t.errTooMany;

      case JhErrorCode.rateLimited:
        err = t.errTooMany;

      case JhErrorCode.smsSendFailed:
        err = t.errSmsFailed;

      case JhErrorCode.network:
        // Spec 36: input is preserved and no session is created.
        err = t.errNet;

      case JhErrorCode.tokenExpired:
      case JhErrorCode.tokenInvalid:
        _endSession();
        err = '';

      default:
        // A validation failure the server caught that the app did not, or a
        // code from a newer server. Neither should look like success.
        err = error.code == JhErrorCode.validationFailed
            ? t.errPhone
            : t.errNet;
    }
  }

  /// Turns an Orders failure into a toast. `ORDER_DECLARATION_REQUIRED` and
  /// `ORDER_VEHICLE_UNAVAILABLE` shouldn't be reachable -- the wizard already
  /// gates both locally -- so seeing either here means a race (the rules
  /// changed between the client's check and the server's), not a normal path.
  void _applyOrderError(JhApiException error) {
    final message = switch (error.code) {
      JhErrorCode.orderDeclarationRequired => t.errDeclaration,
      JhErrorCode.orderVehicleUnavailable => t.modeUnavailable,
      JhErrorCode.network => t.errNet,
      _ => t.orderActionFailed,
    };
    flash(message);
  }

  /// Moves to the OTP screen with the server's timings and a clean counter.
  void _startChallenge(JhOtpChallenge challenge) {
    otpConfig = JhOtpConfig.fromChallenge(challenge);
    screen = JhScreen.otp;
    otp = '';
    attempts = 0;
    blocked = false;
    ttl = challenge.expiresIn;
    cooldown = challenge.resendAvailableIn;
    _clearErrors();
    _startTicking();
    flash(t.toastSent);
  }

  /// One 1s interval, alive only while the OTP screen is on.
  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (screen != JhScreen.otp) return;
      if (ttl <= 0 && cooldown <= 0) return;
      if (ttl > 0) ttl--;
      if (cooldown > 0) cooldown--;
      notifyListeners();
    });
  }

  void _stopTicking() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// The purpose to quote when asking for a fresh code.
  String get _purpose => switch (mode) {
    JhMode.register => JhOtpPurpose.registration,
    JhMode.login => JhOtpPurpose.login,
    JhMode.change => JhOtpPurpose.phoneChange,
  };

  // --- Field intents --------------------------------------------------------

  void setPhone(String value) {
    phone = value.replaceAll(RegExp(r'[^\d\s]'), '');
    _clearErrors();
    notifyListeners();
  }

  void setOtp(String value) {
    otp = value.replaceAll(RegExp(r'\D'), '');
    if (otp.length > otpConfig.length) {
      otp = otp.substring(0, otpConfig.length);
    }
    err = '';
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    _clearErrors();
    notifyListeners();
  }

  void setEmail(String value) {
    email = value;
    _clearErrors();
    notifyListeners();
  }

  /// Switching language must not reset the screen or any form state.
  void setLang(JhLang value) {
    if (lang == value) return;
    lang = value;
    notifyListeners();
  }

  void toggleLang() => setLang(lang == JhLang.en ? JhLang.sw : JhLang.en);

  // --- Submissions ----------------------------------------------------------

  /// Login and change-phone both submit a bare number (spec 16-19, 23-25).
  Future<void> submitPhone() => _busy(JhLoading.phone, () async {
    final digits = enteredDigits;
    // Checked locally first only to save a round trip on an obvious typo; the
    // server validates it again regardless (spec 37).
    if (!isValidPhone(digits)) {
      err = t.errPhone;
      return;
    }

    final challenge = mode == JhMode.change
        ? await api.phoneChangeRequest(digits)
        : await api.loginRequestOtp(digits);
    _startChallenge(challenge);
  });

  /// Single-page registration: name, email and phone together (handoff, the
  /// agreed deviation from spec 6).
  Future<void> submitRegister() async {
    final nameOk = name.trim().length >= 2;
    final emailOk =
        RegExp(r'^[^\s@]+@[^\s@]+\.[a-z]{2,}$', caseSensitive: false)
            .hasMatch(email.trim());
    nameErr = nameOk ? '' : t.errName;
    emailErr = emailOk ? '' : t.errEmail;
    notifyListeners();
    if (!nameOk || !emailOk) return;

    await _busy(JhLoading.register, () async {
      final digits = enteredDigits;
      if (!isValidPhone(digits)) {
        err = t.errPhone;
        return;
      }
      _startChallenge(await api.registerRequestOtp(digits));
    });
  }

  Future<void> verifyOtp() async {
    if (blocked) return;
    await _busy(JhLoading.otp, () async {
      final digits = enteredDigits;

      switch (mode) {
        case JhMode.register:
          // The account is created by this call and not before, so nothing
          // was persisted for an unverified number (spec 14).
          final session = await api.registerVerifyOtp(
            phone: digits,
            code: otp,
            fullName: name.trim(),
            email: email.trim(),
          );
          _enterApp(session.customer);
          flash(t.toastWelcome);

        case JhMode.login:
          final session = await api.loginVerifyOtp(phone: digits, code: otp);
          _enterApp(session.customer);

        case JhMode.change:
          // The stored number moves only on success; a failure leaves the
          // account exactly as it was (spec 25).
          user = await api.phoneChangeVerify(phone: digits, code: otp);
          _stopTicking();
          _clearErrors();
          screen = JhScreen.profile;
          tab = JhTab.account;
          phone = '';
          otp = '';
          flash(t.toastPhone);
      }
    });
  }

  void _enterApp(JhUser customer) {
    _stopTicking();
    _clearErrors();
    user = customer;
    screen = JhScreen.home;
    tab = JhTab.home;
    otp = '';
    name = '';
    email = '';
  }

  Future<void> resend() async {
    if (cooldown > 0) return;
    await _busy(JhLoading.otp, () async {
      final challenge = await api.resendOtp(
        phone: enteredDigits,
        purpose: _purpose,
      );
      // A fresh code invalidates the previous one server-side, so the local
      // counters reset with it.
      otpConfig = JhOtpConfig.fromChallenge(challenge);
      otp = '';
      attempts = 0;
      blocked = false;
      ttl = challenge.expiresIn;
      cooldown = challenge.resendAvailableIn;
      _clearErrors();
      _startTicking();
      flash(t.toastSent);
    });
  }

  // --- Navigation intents ---------------------------------------------------

  void back() {
    if (screen == JhScreen.otp) {
      _stopTicking();
      screen = switch (mode) {
        JhMode.change => JhScreen.changePhone,
        JhMode.register => JhScreen.register,
        JhMode.login => JhScreen.phone,
      };
      otp = '';
      _clearErrors();
    } else if (screen == JhScreen.changePhone) {
      screen = JhScreen.profile;
      phone = '';
      _clearErrors();
    } else if (screen == JhScreen.newOrder) {
      _backInNewOrder();
      return;
    } else if (screen == JhScreen.orderDetail ||
        screen == JhScreen.orderCreated) {
      // The order is already placed; there is nowhere to go but the list.
      _showOrders();
    } else {
      screen = JhScreen.welcome;
      phone = '';
      _clearErrors();
    }
    notifyListeners();
  }

  /// Back within the wizard.
  void _backInNewOrder() {
    if (_editingFromReview) {
      // Abandon the edit and return to Review with whatever is there.
      _editingFromReview = false;
      orderStep = orderStepMax;
    } else if (orderStep > 1) {
      orderStep -= 1;
      // Landing back on the Route step shows its drop-off half, the last
      // thing that was set.
      if (orderStep == 1) routePhase = JhRoutePhase.dropoff;
    } else if (routePhase == JhRoutePhase.dropoff) {
      routePhase = JhRoutePhase.pickup;
    } else {
      // Backing out of the very start of the wizard: to the order list.
      _showOrders();
    }
    notifyListeners();
  }

  /// True when the current screen has somewhere to go back to.
  bool get canGoBack => switch (screen) {
    JhScreen.register ||
    JhScreen.phone ||
    JhScreen.otp ||
    JhScreen.changePhone ||
    JhScreen.newOrder ||
    JhScreen.orderCreated ||
    JhScreen.orderDetail => true,
    _ => false,
  };

  void goRegister() {
    screen = JhScreen.register;
    mode = JhMode.register;
    phone = '';
    name = '';
    email = '';
    nameErr = '';
    emailErr = '';
    _clearErrors();
    notifyListeners();
  }

  void goLogin() {
    screen = JhScreen.phone;
    mode = JhMode.login;
    phone = '';
    _clearErrors();
    notifyListeners();
  }

  /// The link under the shared error: to login when the number is taken, to
  /// registration when it is unknown (spec 15).
  void followErrAction() {
    if (errKind == JhErrKind.toLogin) {
      goLogin();
    } else if (errKind == JhErrKind.toRegister) {
      goRegister();
    }
  }

  void goChangePhone() {
    screen = JhScreen.changePhone;
    mode = JhMode.change;
    phone = '';
    _clearErrors();
    notifyListeners();
  }

  void selectTab(JhTab value) {
    if (value == JhTab.orders) {
      _showOrders();
      notifyListeners();
      return;
    }
    tab = value;
    screen = switch (value) {
      JhTab.home => JhScreen.home,
      JhTab.shop => JhScreen.shop,
      JhTab.orders => JhScreen.orders,
      JhTab.account => JhScreen.profile,
    };
    notifyListeners();
  }

  /// Acknowledges a tap on something Sprint 1 does not carry yet, rather than
  /// letting it fail silently.
  void showComingSoon(String what) => flash('$what — ${t.comingSoon}');

  // --- Orders -------------------------------------------------------------

  /// The one place `screen`/`tab` land on My Orders from -- also where a
  /// fresh fetch is kicked off, so every path that lands there is covered by
  /// one line instead of being repeated at each call site.
  void _showOrders() {
    screen = JhScreen.orders;
    tab = JhTab.orders;
    selectedOrder = null;
    unawaited(loadOrders());
  }

  /// Fetches the signed-in customer's orders. A failure leaves whatever was
  /// already showing rather than blanking the screen -- flashed, not fatal.
  Future<void> loadOrders() async {
    ordersLoading = true;
    notifyListeners();
    try {
      final fetched = await ordersApi.listOrders();
      orders
        ..clear()
        ..addAll(fetched);
    } on JhApiException {
      flash(t.errNet);
    } finally {
      ordersLoading = false;
      notifyListeners();
    }
  }

  List<JhOrder> ordersIn(JhOrderBucket bucket) =>
      orders.where((o) => o.status.bucket == bucket).toList();

  /// "Step 1 of 5".
  String stepLabel(int step) =>
      '${t.stepWord} $step ${t.stepConnector} $orderStepCount';

  String get stepTitle => switch (orderStep) {
    1 => t.stepTitleRoute,
    2 => t.stepTitleRecipient,
    3 => t.stepTitlePackage,
    4 => t.stepTitleDelivery,
    5 => t.stepTitleReview,
    _ => '',
  };

  void setOrdersBucket(JhOrderBucket bucket) {
    ordersBucket = bucket;
    notifyListeners();
  }

  void openMyOrders() {
    _showOrders();
    notifyListeners();
  }

  void startNewOrder() {
    draft = JhOrderDraft();
    orderStep = 1;
    routePhase = JhRoutePhase.pickup;
    pickupMode = JhPickupMode.manual;
    pickupError = '';
    dropoffError = '';
    recipientNameErr = '';
    recipientPhoneErr = '';
    declarationErr = '';
    _editingFromReview = false;
    screen = JhScreen.newOrder;
    tab = JhTab.orders;
    notifyListeners();
  }

  /// "Use Current Location": a shortcut on the search-first form, not a
  /// separate screen. Resolves back onto the same form either way -- filled
  /// in on success, with [pickupError] set on denial.
  Future<void> pickupAllowLocation() async {
    pickupMode = JhPickupMode.locating;
    pickupError = '';
    notifyListeners();
    try {
      final place = await location.currentPlace();
      draft.pickupLat = place.lat;
      draft.pickupLng = place.lng;
      draft.pickupAddress = place.address;
    } on JhLocationException {
      // A customer who declined the OS prompt still needs to place an order;
      // the search box and map are right there to do it by hand.
      pickupError = t.pickupDenied;
    }
    pickupMode = JhPickupMode.manual;
    notifyListeners();
  }

  void pickupSelectPlace(JhPlace place) {
    draft.pickupLat = place.lat;
    draft.pickupLng = place.lng;
    draft.pickupAddress = place.address;
    notifyListeners();
  }

  /// Spends a search suggestion: resolves it to a point, then applies it the
  /// same way [pickupSelectPlace] does. A failed lookup surfaces the same
  /// banner a declined GPS permission does, rather than silently doing
  /// nothing -- the customer typed a real address and tapped a real result.
  Future<void> pickupSelectPrediction(JhPlacePrediction prediction) async {
    try {
      pickupSelectPlace(await location.resolve(prediction));
    } catch (_) {
      pickupError = t.placeLookupFailed;
      notifyListeners();
    }
  }

  /// Remembers a point for next time -- most-recent-first, de-duplicated by
  /// address, capped so the list stays a shortcut rather than a second inbox.
  void _rememberPlace(JhPlace place) {
    if (place.address.trim().isEmpty) return;
    recentPlaces.removeWhere((p) => p.address == place.address);
    recentPlaces.insert(0, place);
    if (recentPlaces.length > _maxRecentPlaces) {
      recentPlaces.removeRange(_maxRecentPlaces, recentPlaces.length);
    }
  }

  Future<List<JhPlacePrediction>> pickupSearch(String query) =>
      location.search(query);

  Future<void> pickupPinMoved(double lat, double lng) async {
    draft.pickupLat = lat;
    draft.pickupLng = lng;
    notifyListeners();
    draft.pickupAddress = await location.addressOf(lat, lng);
    notifyListeners();
  }

  void setPickupLandmark(String v) {
    draft.pickupLandmark = v;
    notifyListeners();
  }

  void setPickupInstructions(String v) {
    draft.pickupInstructions = v;
    notifyListeners();
  }

  void setRecipientName(String v) {
    draft.recipientName = v;
    recipientNameErr = '';
    notifyListeners();
  }

  void setRecipientPhone(String v) {
    draft.recipientPhone = v.replaceAll(RegExp(r'[^\d\s]'), '');
    recipientPhoneErr = '';
    notifyListeners();
  }

  void setPackageType(JhPackageType type) {
    draft.packageType = type;
    notifyListeners();
  }

  void setPackageSize(JhPackageSize size) {
    draft.packageSize = size;
    notifyListeners();
  }

  void setQuantity(int quantity) {
    draft.quantity = quantity.clamp(1, 20);
    notifyListeners();
  }

  void setPackageDescription(String v) {
    draft.packageDescription = v;
    notifyListeners();
  }

  void setHandlingInstructions(String v) {
    draft.handlingInstructions = v;
    notifyListeners();
  }

  void setDeclarationAccepted(bool value) {
    draft.declarationAccepted = value;
    declarationErr = '';
    notifyListeners();
  }

  Future<void> pickPackagePhoto({required bool fromCamera}) async {
    final bytes = fromCamera
        ? await photos.pickFromCamera()
        : await photos.pickFromGallery();
    if (bytes == null) return; // cancelled -- leave whatever was there
    draft.packagePhoto = bytes;
    notifyListeners();
  }

  void removePackagePhoto() {
    draft.packagePhoto = null;
    notifyListeners();
  }

  // Step 1, dropoff phase -- the destination (no "current location", so it is
  // always the map/search form).

  void dropoffSelectPlace(JhPlace place) {
    draft.dropoffLat = place.lat;
    draft.dropoffLng = place.lng;
    draft.dropoffAddress = place.address;
    notifyListeners();
  }

  /// Mirrors [pickupSelectPrediction] for the drop-off half.
  Future<void> dropoffSelectPrediction(JhPlacePrediction prediction) async {
    try {
      dropoffSelectPlace(await location.resolve(prediction));
    } catch (_) {
      dropoffError = t.placeLookupFailed;
      notifyListeners();
    }
  }

  Future<List<JhPlacePrediction>> dropoffSearch(String query) =>
      location.search(query);

  Future<void> dropoffPinMoved(double lat, double lng) async {
    draft.dropoffLat = lat;
    draft.dropoffLng = lng;
    notifyListeners();
    draft.dropoffAddress = await location.addressOf(lat, lng);
    notifyListeners();
  }

  void setDropoffLandmark(String v) {
    draft.dropoffLandmark = v;
    notifyListeners();
  }

  void setDropoffInstructions(String v) {
    draft.dropoffInstructions = v;
    notifyListeners();
  }

  // Step 4 -- Delivery mode.

  void setDeliveryMode(JhVehicle vehicle) {
    if (!vehicle.available) return;
    draft.deliveryMode = vehicle;
    notifyListeners();
  }

  /// An "Edit" link on Review jumps back to the step that owns a field. The
  /// step's own confirm action then returns to Review (see [_editingFromReview]).
  void editOrderStep(int step, {JhRoutePhase? phase}) {
    _editingFromReview = true;
    orderStep = step.clamp(1, orderStepMax);
    if (phase != null) routePhase = phase;
    notifyListeners();
  }

  bool _returnedToReview() {
    if (!_editingFromReview) return false;
    _editingFromReview = false;
    orderStep = orderStepMax;
    notifyListeners();
    return true;
  }

  /// The Route step: "Use This Location" / "Confirm Location" moves from the
  /// pickup half to the drop-off half.
  void confirmPickup() {
    if (_returnedToReview()) return;
    routePhase = JhRoutePhase.dropoff;
    notifyListeners();
  }

  /// The Route step: "Confirm Destination" finishes step 1.
  void confirmDestination() {
    if (_returnedToReview()) return;
    orderStep = 2;
    notifyListeners();
  }

  /// The "Continue" button on steps 2, 3 and 4. Validates first; on the last
  /// step it commits the order.
  void nextOrderStep() {
    if (!_validateOrderStep()) {
      notifyListeners();
      return;
    }
    if (_returnedToReview()) return;
    if (orderStep < orderStepMax) {
      orderStep += 1;
      notifyListeners();
    } else {
      unawaited(_commitOrder());
    }
  }

  bool _validateOrderStep() {
    switch (orderStep) {
      case 2:
        final nameOk = draft.recipientName.trim().length >= 2;
        final phoneOk = isValidPhone(digitsOf(draft.recipientPhone));
        recipientNameErr = nameOk ? '' : t.errRecipientName;
        recipientPhoneErr = phoneOk ? '' : t.errPhone;
        return nameOk && phoneOk;
      case 3:
        final ok = draft.declarationAccepted;
        declarationErr = ok ? '' : t.errDeclaration;
        return ok;
      case 4:
        // The mode buttons default to nothing selected; the Continue button
        // is disabled until one is, so this is a backstop.
        return draft.deliveryMode != null;
      default:
        return true;
    }
  }

  Future<void> _commitOrder() async {
    if (orderSubmitting) return; // guards against a double tap/submission
    orderSubmitting = true;
    notifyListeners();
    try {
      final order = await ordersApi.createOrder(draft);
      orders.insert(0, order);
      // Remembered from the order the server actually created, not the
      // draft -- the same values today, but the order is the source of truth.
      if (order.pickupLat != null && order.pickupLng != null) {
        _rememberPlace(
          JhPlace(
            lat: order.pickupLat!,
            lng: order.pickupLng!,
            address: order.pickupAddress,
          ),
        );
      }
      if (order.dropoffLat != null && order.dropoffLng != null) {
        _rememberPlace(
          JhPlace(
            lat: order.dropoffLat!,
            lng: order.dropoffLng!,
            address: order.dropoffAddress,
          ),
        );
      }
      selectedOrder = order;
      ordersBucket = JhOrderBucket.active;
      screen = JhScreen.orderCreated;
      tab = JhTab.orders;
    } on JhApiException catch (error) {
      // Stays on Review -- nothing was lost, the customer can just try again.
      _applyOrderError(error);
    } finally {
      orderSubmitting = false;
      notifyListeners();
    }
  }

  void openOrderDetail(JhOrder order) {
    selectedOrder = order;
    screen = JhScreen.orderDetail;
    tab = JhTab.orders;
    notifyListeners();
  }

  /// A courier already carrying the package can't be waved off from the app;
  /// cancellation is only offered before pickup.
  bool get canCancelOrder {
    final order = selectedOrder;
    if (order == null) return false;
    return order.status == JhOrderStatus.inTransit &&
        order.stage.index < JhTrackingStage.pickedUp.index;
  }

  void askCancelOrder() {
    if (!canCancelOrder) return;
    cancelOrderOpen = true;
    notifyListeners();
  }

  Future<void> confirmCancelOrder() async {
    final order = selectedOrder;
    if (order == null) return;
    cancelOrderOpen = false;
    notifyListeners();
    try {
      final updated = await ordersApi.cancelOrder(order.serverId);
      _replaceOrder(updated);
      ordersBucket = JhOrderBucket.cancelled;
      _showOrders();
      flash(t.orderCancelledToast);
    } on JhApiException catch (error) {
      _applyOrderError(error);
    }
    notifyListeners();
  }

  /// Stars the customer leaves for a completed delivery.
  Future<void> rateOrder(JhOrder order, int stars) async {
    try {
      final updated = await ordersApi.rateOrder(
        order.serverId,
        stars.clamp(1, 5),
      );
      _replaceOrder(updated);
      if (selectedOrder?.id == order.id) selectedOrder = updated;
    } on JhApiException catch (error) {
      _applyOrderError(error);
    }
    notifyListeners();
  }

  void _replaceOrder(JhOrder updated) {
    final index = orders.indexWhere((o) => o.id == updated.id);
    if (index != -1) orders[index] = updated;
  }

  /// "Reorder" on a completed or cancelled order: the same route, recipient
  /// and package, ready to send again without retyping any of it.
  void reorderFrom(JhOrder order) {
    draft = JhOrderDraft.fromOrder(order);
    orderStep = orderStepMax;
    routePhase = JhRoutePhase.dropoff;
    pickupMode = JhPickupMode.manual;
    pickupError = '';
    dropoffError = '';
    recipientNameErr = '';
    recipientPhoneErr = '';
    declarationErr = '';
    _editingFromReview = false;
    selectedOrder = null;
    screen = JhScreen.newOrder;
    tab = JhTab.orders;
    notifyListeners();
  }

  void askLogout() {
    logoutOpen = true;
    notifyListeners();
  }

  void askDeleteAccount() {
    deleteAccountOpen = true;
    notifyListeners();
  }

  void closeSheet() {
    logoutOpen = false;
    deleteAccountOpen = false;
    cancelOrderOpen = false;
    notifyListeners();
  }

  /// Account deletion has no backend yet (Sprint 1 is authentication only),
  /// so this closes the confirmation and acknowledges the request rather than
  /// pretending the account was removed.
  void confirmDeleteAccount() {
    deleteAccountOpen = false;
    showComingSoon(t.deleteAccount);
  }

  /// Ends the session on the server, then locally (spec 22).
  ///
  /// The local state is cleared whatever the server says: a customer who has
  /// asked to sign out must not be left on an authenticated screen because a
  /// request failed.
  Future<void> doLogout() async {
    logoutOpen = false;
    notifyListeners();
    try {
      await api.logout();
    } on JhApiException {
      // Deliberately ignored -- see above.
    }
    _endSession();
    notifyListeners();
  }

  /// Drops every trace of the session and returns to Welcome.
  ///
  /// Also used when the server rejects our credentials mid-session: spec 35
  /// requires the app to stop looking authenticated rather than leaving the
  /// customer on a screen whose every request fails.
  void _endSession() {
    screen = JhScreen.welcome;
    mode = JhMode.register;
    tab = JhTab.home;
    user = null;
    phone = '';
    otp = '';
    name = '';
    email = '';
    nameErr = '';
    emailErr = '';
    attempts = 0;
    blocked = false;
    ttl = 0;
    cooldown = 0;
    orders.clear();
    ordersLoading = false;
    orderSubmitting = false;
    ordersBucket = JhOrderBucket.active;
    recentPlaces.clear();
    draft = JhOrderDraft();
    orderStep = 1;
    routePhase = JhRoutePhase.pickup;
    pickupMode = JhPickupMode.manual;
    pickupError = '';
    dropoffError = '';
    _editingFromReview = false;
    selectedOrder = null;
    cancelOrderOpen = false;
    recipientNameErr = '';
    recipientPhoneErr = '';
    declarationErr = '';
    _clearErrors();
    _stopTicking();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }
}

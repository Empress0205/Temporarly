import 'package:flutter/material.dart';

/// Design tokens transcribed from the Sprint 1 authentication handoff.
///
/// Every value here comes from `design_handoff_sprint1_auth/README.md`
/// ("Design Tokens"). Screens must reference these rather than inlining
/// literals, so a brand change stays a one-file edit.
class JhColors {
  JhColors._();

  // Flat and neutral on purpose -- no warm/cream cast, no gradient. Cards
  // stand off this purely through [JhShadows.card]'s elevation.
  static const background = Color(0xFFF5F5F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEFEFEC);
  static const cellEmpty = Color(0xFFF1F4F0);

  static const ink = Color(0xFF0F1A15);
  static const inkMuted = Color(0xB80F1A15); // rgba(15,26,21,.72)
  static const inkSubtle = Color(0xB30F1A15); // rgba(15,26,21,.70)
  static const inkFaint = Color(0x8C0F1A15); // rgba(15,26,21,.55)
  static const inkPlaceholder = Color(0x6B0F1A15); // rgba(15,26,21,.42)

  static const hairline = Color(0x140F1A15); // rgba(15,26,21,.08)
  static const hairlineSoft = Color(0x0F0F1A15); // rgba(15,26,21,.06)
  static const divider = Color(0x240F1A15); // rgba(15,26,21,.14)

  // --- Brand palette (client-supplied) --------------------------------------
  // Primary Orange, Charcoal, Operations Green, Warm Accent. Roles below are
  // the client's own: orange carries every action/selection/brand moment,
  // charcoal is reserved for headers and structural framing, green is now
  // strictly a "this is done" signal (never the brand colour), and the warm
  // accent is for soft badges/callouts.
  static const brandOrange = Color(0xFFF7941D);
  static const brandCharcoal = Color(0xFF2D2D2D);
  static const brandGreen = Color(0xFF2D8B4E);
  static const brandWarmAccent = Color(0xFFFDB95B);

  static const primary = brandOrange;
  static const primaryText = Color(0xFFC96A0F); // pressed-adjacent shade for text/contrast use
  static const primaryPressed = Color(0xFFB25F0C);
  static const primaryDisabled = Color(0x59F7941D); // rgba(247,148,29,.35)
  static const primaryTint = Color(0x1FF7941D); // rgba(247,148,29,.12)
  static const toastText = Color(0xFFB25F0C);

  /// True completion/success only -- an order marked Completed, a
  /// successful-action toast. Never used just because something is "the
  /// brand colour" -- that's [primary] now.
  static const success = brandGreen;
  static const successBg = Color(0x1F2D8B4E); // rgba(45,139,78,.12)

  static const onDark = Color(0xFFFFFFFF);
  static const onDarkMuted = Color(0xE0FFFFFF); // rgba(255,255,255,.88)
  static const onDarkSubtle = Color(0xD9FFFFFF); // rgba(255,255,255,.85)
  static const onDarkFaint = Color(0xB8FFFFFF); // rgba(255,255,255,.72)
  static const onDarkSurface = Color(0x33FFFFFF); // rgba(255,255,255,.20)
  static const onDarkSurfaceSoft = Color(0x2EFFFFFF); // rgba(255,255,255,.18)
  static const onDarkBorder = Color(0x57FFFFFF); // rgba(255,255,255,.34)
  static const onDarkBorderSoft = Color(0x4DFFFFFF); // rgba(255,255,255,.30)

  static const warningPillBg = Color(0x29D9971F); // rgba(217,151,31,.16)
  static const warningPillText = Color(0xFF8A5300);
  static const notificationDot = Color(0xFFFFD24A);

  static const danger = Color(0xFFC22A22);
  static const dangerBg = Color(0x14D9342B); // rgba(217,52,43,.08)
  static const dangerBorder = Color(0x3DD9342B); // rgba(217,52,43,.24)
  static const dangerBorderStrong = Color(0x52D9342B); // rgba(217,52,43,.32)
  static const dangerField = Color(0x80D9342B); // rgba(217,52,43,.50)

  static const fieldIdle = Color(0x170F1A15); // rgba(15,26,21,.09)
  static const outlineButton = Color(0x290F1A15); // rgba(15,26,21,.16)

  static const scrim = Color(0x660F1A15); // rgba(15,26,21,.40)

  // --- Second-pass look -----------------------------------------------------
  // The orange/charcoal rebrand supports the same lighter, flatter layout as
  // before: a photographic welcome hero, flat charcoal headers, and white
  // cards on a neutral ground.

  /// The lightning mark on the "Fast delivery" badge, and other soft
  /// callouts/badges -- the client's Warm Accent.
  static const accent = brandWarmAccent;

  /// Neutral secondary text on light surfaces -- a warm-leaning grey rather
  /// than the old green-leaning one, so it reads as chosen against orange.
  static const textMuted = Color(0xFF6B6560);
  static const textFaint = Color(0xFF9A948D);

  /// Card outline in the new look -- warm rather than the old cool hairline.
  /// Still used for internal dividers between rows in a grouped list, and an
  /// unselected control's border; outer card shells separate from the page
  /// with [JhShadows.card] instead of a stroke of this now.
  static const cardBorder = Color(0xFFE8E4E0);

  /// 12% wash of any accent, for the tile behind an icon -- used sparingly
  /// now that most rows/tiles take a neutral [ink] icon rather than a colour
  /// of their own; a wash of [ink] reads as a plain light-grey tile.
  static Color wash(Color accent) => accent.withValues(alpha: 0.12);
}

class JhRadii {
  JhRadii._();

  static const headerBottom = Radius.circular(30);
  static const sheetTop = Radius.circular(26);
  static const pill = 99.0;
  static const card = 20.0;
  static const heroCard = 22.0;
  static const tile = 18.0;
  static const field = 16.0;
  static const button = 17.0;
  static const row = 16.0;
  static const toast = 15.0;
  static const otpCell = 14.0;
  static const backButton = 13.0;
  static const errorBlock = 13.0;

  // Second-pass look.
  static const sheet = 28.0;
  static const control = 12.0;
  static const cardSmall = 14.0;
}

class JhShadows {
  JhShadows._();

  static const field = [
    BoxShadow(color: Color(0x0A0F1A15), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const button = [
    BoxShadow(color: Color(0x33F7941D), blurRadius: 18, offset: Offset(0, 8)),
  ];
  // Cards are shadow-only (no stroke) and genuinely lifted. Two layers, the
  // way real elevation is usually built: a tight, crisper shadow right at
  // the edge so the card reads as a distinct object, plus a big soft one
  // underneath for the ambient lift -- one layer alone read as barely-there
  // once the page background went flat/near-white and stopped supplying any
  // contrast of its own.
  static const card = [
    BoxShadow(color: Color(0x1A0F1A15), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x330F1A15), blurRadius: 32, offset: Offset(0, 16)),
  ];
  static const heroCard = [
    BoxShadow(color: Color(0x160F1A15), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const toast = [
    BoxShadow(color: Color(0x290F1A15), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const tabBar = [
    BoxShadow(color: Color(0x0A0F1A15), blurRadius: 20, offset: Offset(0, -6)),
  ];

  /// Soft lift under the white sheet on the welcome screen.
  static const sheetLift = [
    BoxShadow(color: Color(0x140F1A15), blurRadius: 30, offset: Offset(0, -8)),
  ];

  /// The floating status pills over the hero illustration.
  static const pill = [
    BoxShadow(color: Color(0x1F0F1A15), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

/// Type ramp. `Manrope` for UI, `JetBrainsMono` for numbers, ids and codes.
class JhText {
  JhText._();

  static const _ui = 'Manrope';
  static const _mono = 'JetBrainsMono';

  static TextStyle ui({
    required double size,
    required FontWeight weight,
    Color color = JhColors.ink,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: _ui,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = JhColors.ink,
    double? letterSpacing,
    double? height,
  }) => TextStyle(
    fontFamily: _mono,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Welcome headline — 33px/1.1 800, -1.3px.
  static const display = TextStyle(
    fontFamily: _ui,
    fontSize: 33,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.3,
    color: JhColors.onDark,
  );

  /// Screen titles — 27px 800.
  static TextStyle title({double letterSpacing = -0.9, Color color = JhColors.onDark}) =>
      ui(size: 27, weight: FontWeight.w800, color: color, letterSpacing: letterSpacing);

  /// Field label — plain sentence case, 13.5px 700, no tracking.
  static const fieldLabel = TextStyle(
    fontFamily: _ui,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: JhColors.ink,
  );

  /// Primary button label — 16px 800.
  static const button = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: JhColors.onDark,
  );

  /// Input text — 16px 600.
  static const input = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: JhColors.ink,
  );

  /// Phone / OTP entry — mono 17px 700, .5px.
  static const monoInput = TextStyle(
    fontFamily: _mono,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: JhColors.ink,
  );
}

/// Motion durations from the handoff (`jhspin`, `jhup`, `jhsheet`).
class JhMotion {
  JhMotion._();

  static const spin = Duration(milliseconds: 700);
  static const rise = Duration(milliseconds: 250);
  static const sheet = Duration(milliseconds: 220);
  static const splash = Duration(milliseconds: 1500);
  static const toast = Duration(milliseconds: 3200);
}

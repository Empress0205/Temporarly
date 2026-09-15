import 'package:flutter/widgets.dart';

import '../orders/order_models.dart';
import '../theme/tokens.dart';

/// A small illustrated scene for one onboarding slide: a courier figure
/// cradling a package, with a simplified vehicle drawn behind them.
///
/// Drawn rather than shipped as an asset -- the same reasoning as everything
/// else in this app that paints its own art (the old welcome hero, the brand
/// lockup's tile): no files to bundle, it recolours with the tokens for
/// free, and it stays reviewable in a diff. The figure is deliberately
/// faceless and without a skin tone -- a plain courier pictogram, not a
/// specific person -- so there is nothing about it that needs revisiting per
/// market the way drawn character art usually would.
class JhOnboardingIllustration extends StatelessWidget {
  const JhOnboardingIllustration({super.key, required this.vehicle});

  final JhVehicle vehicle;

  static const Size designSize = Size(300, 250);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : designSize.width;
        final scale = width / designSize.width;
        return SizedBox(
          width: width,
          height: designSize.height * scale,
          child: CustomPaint(painter: _IllustrationPainter(vehicle)),
        );
      },
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter(this.vehicle);

  final JhVehicle vehicle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.width / JhOnboardingIllustration.designSize.width;
    canvas.scale(scale);

    _paintBackdrop(canvas);
    _paintGroundShadow(canvas);
    _paintVehicle(canvas);
    _paintCourier(canvas);

    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas) {
    canvas.drawCircle(
      const Offset(150, 98),
      104,
      Paint()..color = JhColors.primaryTint,
    );
    final accent = Paint()
      ..color = JhColors.brandWarmAccent.withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(248, 34), 7, accent);
    canvas.drawCircle(const Offset(36, 56), 5, accent);
  }

  void _paintGroundShadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(150, 198), width: 196, height: 16),
      Paint()..color = JhColors.brandCharcoal.withValues(alpha: 0.08),
    );
  }

  Paint get _stroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = JhColors.brandCharcoal;

  Paint get _body => Paint()..color = JhColors.primary;

  void _wheel(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(centre, radius, Paint()..color = JhColors.surface);
    canvas.drawCircle(centre, radius, _stroke..strokeWidth = 2.6);
    canvas.drawCircle(
      centre,
      radius * 0.32,
      Paint()..color = JhColors.brandCharcoal,
    );
  }

  void _paintVehicle(Canvas canvas) {
    switch (vehicle) {
      case JhVehicle.motorcycle:
        _wheel(canvas, const Offset(196, 178), 17);
        _wheel(canvas, const Offset(258, 178), 17);
        canvas.drawLine(
          const Offset(196, 178),
          const Offset(224, 148),
          _stroke,
        );
        canvas.drawLine(
          const Offset(224, 148),
          const Offset(258, 178),
          _stroke,
        );
        final seat = RRect.fromRectAndRadius(
          const Rect.fromLTWH(204, 134, 42, 16),
          const Radius.circular(8),
        );
        canvas.drawRRect(seat, _body);
        canvas.drawRRect(seat, _stroke..strokeWidth = 2);
        break;

      case JhVehicle.bajaji:
        _wheel(canvas, const Offset(198, 180), 14);
        _wheel(canvas, const Offset(238, 180), 14);
        _wheel(canvas, const Offset(266, 180), 14);
        final cabin = RRect.fromRectAndRadius(
          const Rect.fromLTWH(196, 122, 78, 50),
          const Radius.circular(16),
        );
        canvas.drawRRect(cabin, _body);
        canvas.drawRRect(cabin, _stroke..strokeWidth = 2);
        canvas.drawArc(
          const Rect.fromLTWH(196, 100, 78, 42),
          3.4,
          2.6,
          false,
          _stroke..strokeWidth = 2.4,
        );
        break;

      case JhVehicle.car:
        _wheel(canvas, const Offset(206, 180), 16);
        _wheel(canvas, const Offset(262, 180), 16);
        final body = RRect.fromRectAndRadius(
          const Rect.fromLTWH(188, 140, 96, 34),
          const Radius.circular(14),
        );
        canvas.drawRRect(body, _body);
        canvas.drawRRect(body, _stroke..strokeWidth = 2);
        final cabin = RRect.fromRectAndRadius(
          const Rect.fromLTWH(206, 118, 54, 26),
          const Radius.circular(10),
        );
        canvas.drawRRect(cabin, _body);
        canvas.drawRRect(cabin, _stroke..strokeWidth = 2);
        break;

      case JhVehicle.van:
        _wheel(canvas, const Offset(202, 180), 15);
        _wheel(canvas, const Offset(256, 180), 15);
        final cab = RRect.fromRectAndRadius(
          const Rect.fromLTWH(186, 142, 34, 32),
          const Radius.circular(10),
        );
        canvas.drawRRect(cab, _body);
        canvas.drawRRect(cab, _stroke..strokeWidth = 2);
        final box = RRect.fromRectAndRadius(
          const Rect.fromLTWH(220, 118, 62, 56),
          const Radius.circular(10),
        );
        canvas.drawRRect(box, Paint()..color = JhColors.surface);
        canvas.drawRRect(box, _stroke..strokeWidth = 2);
        break;
    }
  }

  void _paintCourier(Canvas canvas) {
    // Head -- an outline only, deliberately faceless.
    canvas.drawCircle(
      const Offset(96, 94),
      20,
      Paint()..color = JhColors.surface,
    );
    canvas.drawCircle(const Offset(96, 94), 20, _stroke..strokeWidth = 2.6);
    // Cap.
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(96, 90), radius: 21),
      3.3,
      2.8,
      true,
      _body,
    );

    // Torso.
    final torso = RRect.fromRectAndRadius(
      const Rect.fromLTWH(74, 114, 44, 54),
      const Radius.circular(16),
    );
    canvas.drawRRect(torso, Paint()..color = JhColors.brandCharcoal);

    // Legs.
    canvas.drawLine(
      const Offset(84, 166),
      const Offset(80, 196),
      _stroke..strokeWidth = 5,
    );
    canvas.drawLine(
      const Offset(108, 166),
      const Offset(112, 196),
      _stroke..strokeWidth = 5,
    );

    // Arms cradling the package.
    canvas.drawLine(
      const Offset(78, 126),
      const Offset(58, 156),
      _stroke..strokeWidth = 5,
    );
    canvas.drawLine(
      const Offset(114, 126),
      const Offset(134, 156),
      _stroke..strokeWidth = 5,
    );

    // The package.
    final box = RRect.fromRectAndRadius(
      const Rect.fromLTWH(58, 148, 76, 46),
      const Radius.circular(8),
    );
    canvas.drawRRect(box, _body);
    canvas.drawRRect(box, _stroke..strokeWidth = 2);
    canvas.drawLine(
      const Offset(96, 148),
      const Offset(96, 194),
      _stroke..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(58, 171),
      const Offset(134, 171),
      _stroke..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) =>
      oldDelegate.vehicle != vehicle;
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The `jhspin` ring: a faint full circle with one solid quadrant, rotating
/// at a constant speed. Flutter's own CircularProgressIndicator sweeps its
/// arc, so it does not read as the same mark.
class JhSpinner extends StatefulWidget {
  const JhSpinner({
    super.key,
    this.size = 15,
    this.stroke = 2,
    this.color = JhColors.onDark,
    this.trackColor = const Color(0x59FFFFFF), // rgba(255,255,255,.35)
  });

  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  State<JhSpinner> createState() => _JhSpinnerState();
}

class _JhSpinnerState extends State<JhSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: JhMotion.spin,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _RingPainter(
          stroke: widget.stroke,
          color: widget.color,
          trackColor: widget.trackColor,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(inset, 0, math.pi * 2, false, base);

    // The lit segment stands in for CSS `border-top-color`: the top edge,
    // which spans a quarter turn centred on 12 o'clock.
    final lit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(inset, -math.pi * 0.75, math.pi / 2, false, lit);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.stroke != stroke || old.color != color || old.trackColor != trackColor;
}

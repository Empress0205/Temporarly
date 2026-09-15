import 'package:flutter/material.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';

/// The Jihudumie lockup: a rounded green tile carrying the mark, then the
/// wordmark.
///
/// [onDark] flips it for the green splash — white tile, green mark — so one
/// widget serves both grounds.
class JhBrandLockup extends StatelessWidget {
  const JhBrandLockup({
    super.key,
    this.tileSize = 38,
    this.wordSize = 20,
    this.onDark = false,
    this.axis = Axis.horizontal,
    this.showEyebrow = false,
  });

  /// The larger stacked lockup used on the splash screen.
  const JhBrandLockup.splash({super.key})
    : tileSize = 68,
      wordSize = 23,
      onDark = true,
      axis = Axis.vertical,
      showEyebrow = true;

  final double tileSize;
  final double wordSize;
  final bool onDark;
  final Axis axis;
  final bool showEyebrow;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: tileSize,
      height: tileSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onDark ? JhColors.surface : JhColors.primaryText,
        borderRadius: BorderRadius.circular(tileSize * 0.32),
      ),
      child: Icon(
        JhIcons.logo,
        size: tileSize * 0.54,
        color: onDark ? JhColors.primaryText : JhColors.onDark,
      ),
    );

    final wordmark = Text(
      'Jihudumie',
      style: JhText.ui(
        size: wordSize,
        weight: FontWeight.w800,
        letterSpacing: -0.5,
        color: onDark ? JhColors.onDark : JhColors.ink,
      ),
    );

    final words = showEyebrow
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: axis == Axis.vertical
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              wordmark,
              const SizedBox(height: 3),
              Text(
                'LOGISTICS',
                style: JhText.mono(
                  size: 10.5,
                  letterSpacing: 1.6,
                  color: onDark ? JhColors.onDarkFaint : JhColors.textMuted,
                ),
              ),
            ],
          )
        : wordmark;

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [tile, const SizedBox(height: 20), words],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [tile, const SizedBox(width: 10), words],
    );
  }
}

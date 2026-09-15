import 'dart:async';

import 'package:flutter/widgets.dart';

import '../l10n/dict.dart';
import '../orders/order_models.dart';
import '../theme/tokens.dart';
import 'jh_onboarding_illustration.dart';

class _Slide {
  const _Slide({
    required this.vehicle,
    required this.title,
    required this.subtitle,
  });

  final JhVehicle vehicle;
  final String title;
  final String subtitle;
}

/// The Welcome screen's onboarding sequence: one illustrated scene, headline
/// and subtitle per vehicle type, auto-advancing and swipeable, with a dot
/// indicator showing where you are -- replacing the old photo hero. There is
/// no Login/Create-account choice here any more; a single Continue button
/// (owned by the screen, not this widget) is the only way forward.
///
/// The test suite pumps fixed durations rather than calling `pumpAndSettle`
/// (see `test/auth_flow_test.dart`), so the periodic auto-advance timer here
/// is safe the same way `JhHeroCarousel` was -- it never blocks a test on an
/// animation that never finishes, as long as it is cancelled in `dispose`.
class JhOnboardingCarousel extends StatefulWidget {
  const JhOnboardingCarousel({super.key, required this.t});

  final JhStrings t;

  @override
  State<JhOnboardingCarousel> createState() => _JhOnboardingCarouselState();
}

class _JhOnboardingCarouselState extends State<JhOnboardingCarousel> {
  static const _slideDuration = Duration(seconds: 4);

  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  List<_Slide> _slidesFor(JhStrings t) => [
    _Slide(
      vehicle: JhVehicle.motorcycle,
      title: t.onboardTitle1,
      subtitle: t.onboardSub1,
    ),
    _Slide(
      vehicle: JhVehicle.car,
      title: t.onboardTitle2,
      subtitle: t.onboardSub2,
    ),
    _Slide(
      vehicle: JhVehicle.bajaji,
      title: t.onboardTitle3,
      subtitle: t.onboardSub3,
    ),
    _Slide(
      vehicle: JhVehicle.van,
      title: t.onboardTitle4,
      subtitle: t.onboardSub4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _slidesFor(widget.t).length;
      _controller.animateToPage(
        next,
        duration: JhMotion.sheet,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slidesFor(widget.t);
    final index = _index.clamp(0, slides.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A bounded height rather than Expanded: the carousel is one
        // naturally-sized block (illustration, headline, subtitle, dots)
        // that the screen centres in whatever space is left above the
        // Continue button -- not a block that stretches to fill it, which
        // is what left a huge gap between the text and the dots before.
        // Generous on purpose: the widget-test binding (unlike the golden
        // suite) doesn't load the real fonts, so text measures taller under
        // the fallback font than it does for real -- this needs enough
        // headroom to survive both, not just the real-font measurement.
        SizedBox(
          height: 460,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  JhOnboardingIllustration(vehicle: slide.vehicle),
                  const SizedBox(height: 20),
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: JhText.ui(
                      size: 24,
                      weight: FontWeight.w800,
                      letterSpacing: -0.7,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      slide.subtitle,
                      textAlign: TextAlign.center,
                      style: JhText.ui(
                        size: 14,
                        weight: FontWeight.w500,
                        color: JhColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _Dot(active: i == index),
            ],
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: JhMotion.rise,
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? JhColors.primary : JhColors.cardBorder,
        borderRadius: BorderRadius.circular(JhRadii.pill),
      ),
    );
  }
}

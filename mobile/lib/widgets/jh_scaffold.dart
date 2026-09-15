import 'package:flutter/material.dart';

import 'jh_tab_bar.dart';

/// Removes the scrollbar and overscroll glow, matching the prototype's
/// `[data-jhscroll]` rule.
class JhScrollBehavior extends ScrollBehavior {
  const JhScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// The four auth screens share one composition: a fixed header, then a
/// scrolling body whose fields sit at the top and whose primary action is
/// pinned to the bottom (`margin-top:auto`).
class JhAuthScaffold extends StatelessWidget {
  const JhAuthScaffold({
    super.key,
    required this.header,
    required this.body,
    required this.footer,
    required this.toastVisible,
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 30),
    this.footerGap = 28,
  });

  final Widget header;

  /// Fields and the error slot, laid out from the top.
  final List<Widget> body;

  /// The primary action and any supporting rows, pinned to the bottom.
  final Widget footer;

  /// While a toast is up the body's bottom padding grows so the toast can
  /// never cover the primary action.
  final bool toastVisible;

  /// Body padding at rest. The bottom value is replaced while a toast is up.
  final EdgeInsets padding;

  /// Space between the last body child and the pinned footer.
  final double footerGap;

  @override
  Widget build(BuildContext context) {
    final bottom = toastVisible ? 86.0 : padding.bottom;

    return Column(
      children: [
        header,
        Expanded(
          child: ScrollConfiguration(
            behavior: const JhScrollBehavior(),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: padding.copyWith(bottom: bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Clamped: on a short viewport the padding can exceed the
                    // height available, and a negative minimum is an assertion
                    // failure rather than a layout that merely looks wrong.
                    minHeight: (constraints.maxHeight - padding.top - bottom)
                        .clamp(0.0, double.infinity),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...body,
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.only(top: footerGap),
                          child: footer,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Home and Profile pull their body up over the header so the first card
/// overlaps the green band. A Stack gives that the same way the design's
/// negative margin plus `z-index:1` does.
class JhOverlapScaffold extends StatelessWidget {
  const JhOverlapScaffold({
    super.key,
    required this.header,
    required this.headerHeight,
    required this.overlap,
    required this.children,
  });

  final Widget header;

  /// Height of the green band. Known up front because its padding and content
  /// are both fixed.
  final double headerHeight;

  /// How far the body rises into the header.
  final double overlap;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: header,
        ),
        Positioned(
          top: headerHeight - overlap,
          left: 0,
          right: 0,
          bottom: 0,
          child: ScrollConfiguration(
            behavior: const JhScrollBehavior(),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                JhTabBar.heightOf(context) + 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

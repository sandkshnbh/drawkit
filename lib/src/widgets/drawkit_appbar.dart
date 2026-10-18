import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// A top bar over a paper surface: leading slot, title, actions — with the
/// heavier "shelf" rule along the bottom edge, exactly one pen stroke wide.
///
/// Direction-aware: the leading slot holds the start edge and actions gather
/// at the end, so Arabic screens mirror without any extra wiring.
class DrawkitAppBar extends StatelessWidget {
  const DrawkitAppBar({
    required this.title,
    this.leading,
    this.actions = const [],
    this.height = 56,
    this.titleStyle,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 14),
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget> actions;
  final double height;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final text = DefaultTextStyle.of(context).style
        .merge(
          TextStyle(
            color: resolved.palette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        )
        .merge(titleStyle);
    final topPadding = MediaQuery.viewPaddingOf(context).top;

    return Semantics(
      header: true,
      container: true,
      child: DrawkitSurface(
        builder: (size, options) => [
          DrawkitLayer(
            roughRoundedRect(0, 0, size.width, size.height, 0, options),
            drawkitFillPaint(resolved.paperColor),
          ),
          DrawkitLayer(
            roughLine(
              -2,
              size.height - 1.5,
              size.width + 2,
              size.height - 1.5,
              options,
            ),
            drawkitStroke(resolved, fallbackWidth: 1.5),
          ),
        ],
        style: resolved,
        seed: seed,
        animate: animate,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: text,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: title,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      actions[i],
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

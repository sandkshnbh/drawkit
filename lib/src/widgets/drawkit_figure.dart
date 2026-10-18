import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// An image (or any widget) in a sketched frame with an optional caption
/// beneath it — the drawing pinned into the sketchbook.
class DrawkitFigure extends StatelessWidget {
  const DrawkitFigure({
    required this.child,
    this.caption,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(8),
    this.captionSpacing = 8,
    this.captionStyle,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;

  /// Muted, centered, and captioned like a plate under the frame.
  final String? caption;

  /// Alt text for the figure; when null the caption carries the meaning.
  final String? semanticLabel;

  final EdgeInsetsGeometry padding;
  final double captionSpacing;
  final TextStyle? captionStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final captionText = DefaultTextStyle.of(context).style
        .merge(
          TextStyle(
            fontSize: 13,
            height: 1.4,
            color: resolved.palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        )
        .merge(captionStyle);

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawkitSurface(
            builder: (size, options) => [
              DrawkitLayer(
                roughRoundedRect(
                  3,
                  3,
                  size.width - 6,
                  size.height - 6,
                  8,
                  options,
                ),
                drawkitFillPaint(resolved.paperColor),
              ),
              DrawkitLayer(
                roughRoundedRect(
                  3,
                  3,
                  size.width - 6,
                  size.height - 6,
                  8,
                  options,
                ),
                drawkitStroke(resolved, fallbackWidth: 1.5),
              ),
            ],
            style: resolved,
            seed: seed,
            animate: animate,
            child: Padding(padding: padding, child: child),
          ),
          if (caption != null) ...[
            SizedBox(height: captionSpacing),
            Text(caption!, style: captionText, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

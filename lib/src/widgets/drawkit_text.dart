import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// Text decorations are measured with a [TextPainter] and drawn per line box,
/// the Flutter equivalent of the JS `lineBoxes` union: every wrapped line gets
/// its own stroke, while the seam between lines stays negotiable like a hand
/// that re-inks between words.
class DrawkitUnderline extends StatelessWidget {
  const DrawkitUnderline({
    required this.text,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final String text;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _TextChrome(
    text: text,
    textStyle: textStyle,
    textAlign: textAlign,
    style: style,
    seed: seed,
    animate: animate,
    resketchOnPointer: true,
    layer: (box, options, style) => DrawkitLayer(
      roughLine(box.left, box.bottom + 2, box.right, box.bottom + 2, options),
      drawkitStroke(style, fallbackWidth: 1.5),
    ),
  );
}

/// Marker wash behind body copy: the scribble hatch with a 6px stroke at 30%
/// opacity in multiply — legible text over one swipe of highlighter.
class DrawkitHighlight extends StatelessWidget {
  const DrawkitHighlight({
    required this.text,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final String text;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _TextChrome(
    text: text,
    textStyle: textStyle,
    textAlign: textAlign,
    style: style,
    seed: seed,
    animate: animate,
    resketchOnPointer: false,
    layer: (box, options, style) => DrawkitLayer(
      scribbleFill(box.left, box.top, box.width, box.height, options),
      Paint()
        ..color = style.effectiveFill.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.multiply,
    ),
  );
}

/// A hand loops around a word rather than tracing its edges: the ellipse
/// overshoots the box by the tuned pads (1.15x horizontal, 1.4x vertical).
class DrawkitCircle extends StatelessWidget {
  const DrawkitCircle({
    required this.text,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final String text;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _TextChrome(
    text: text,
    textStyle: textStyle,
    textAlign: textAlign,
    style: style,
    seed: seed,
    animate: animate,
    resketchOnPointer: true,
    layer: (box, options, style) => DrawkitLayer(
      roughEllipse(
        box.center.dx,
        box.center.dy,
        (box.width / 2) * 1.15 + 4,
        (box.height / 2) * 1.4 + 4,
        options,
      ),
      drawkitStroke(style, fallbackWidth: 1.5),
    ),
  );
}

typedef _BoxLayer = DrawkitLayer Function(
  Rect box,
  RoughOptions options,
  DrawkitStyle style,
);

class _TextChrome extends StatelessWidget {
  const _TextChrome({
    required this.text,
    required this.textStyle,
    required this.textAlign,
    required this.style,
    required this.seed,
    required this.animate,
    required this.resketchOnPointer,
    required this.layer,
  });

  final String text;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final bool resketchOnPointer;
  final _BoxLayer layer;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final effective = DefaultTextStyle.of(context).style.merge(textStyle);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) =>
          _build(context, constraints, resolved, effective, direction),
    );
  }

  Widget _build(
    BuildContext context,
    BoxConstraints constraints,
    DrawkitStyle resolved,
    TextStyle effective,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: effective),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: direction,
      textAlign: textAlign,
    )..layout(maxWidth: constraints.maxWidth);
    final boxes = text.isEmpty
        ? const <Rect>[]
        : painter
              .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: text.length),
              )
              .map((b) => b.toRect())
              .toList();

    // Selection boxes are line-relative, so the surface must keep the
    // painter's width; the directional start alignment then places it inside
    // wider constraints (a stretched quote) without shifting the strokes.
    // Both factors keep the box shrink-wrapped: without heightFactor the
    // Align would swallow every bounded height it is given (a row, a card),
    // drawing the decoration around empty space.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: painter.width,
        height: painter.height,
        child: DrawkitSurface(
          builder: (size, options) => [
            for (final box in boxes) layer(box, options, resolved),
          ],
          style: resolved,
          seed: seed,
          animate: animate,
          resketchOnPointer: resketchOnPointer,
          child: Text(
            text,
            style: effective,
            textAlign: textAlign,
            textDirection: direction,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

import '../engine/rough.dart';
import 'style.dart';
import 'surface.dart';

/// The smallest interactive box drawkit ships: Android asks for 48dp, iOS for
/// 44pt, and the controls take the stricter one everywhere. The drawing
/// itself keeps its own size — only the touch/semantics box grows.
const double drawkitMinTapTarget = 48;

/// Wraps a drawn control so its interactive box is at least
/// [drawkitMinTapTarget] on both axes, with the drawing centered inside.
/// Host it *inside* the gesture/semantics layer (so the tap action and the
/// semantics rect cover the full box), never around it.
class DrawkitTapTarget extends StatelessWidget {
  const DrawkitTapTarget({
    super.key,
    this.minWidth = drawkitMinTapTarget,
    this.minHeight = drawkitMinTapTarget,
    required this.child,
  });

  final double minWidth;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
    child: Center(widthFactor: 1, heightFactor: 1, child: child),
  );
}

/// The shared keyboard-focus ring: one extra rough outline drawn just outside
/// a widget's resting stroke, so focus reads as a second pass of the pen
/// instead of a diffuse glow. Widgets own the when (their `_focused` flag);
/// this owns the how, keeping every control's ring in the same hand.
///
/// [radius] should match the shape's own corner radius so the ring follows
/// its silhouette. The default `1px` gap keeps the two strokes close without
/// touching.
DrawkitLayer drawkitFocusRingRect({
  required Size size,
  required RoughOptions options,
  required DrawkitStyle style,
  Color? color,
  double radius = 10,
  double gapX = 1,
  double gapY = 1,
}) => DrawkitLayer(
  roughRoundedRect(
    -gapX,
    -gapY,
    size.width + 2 * gapX,
    size.height + 2 * gapY,
    radius,
    options,
  ),
  drawkitStroke(style, color: color, fallbackWidth: 1.5),
);

/// Circular variant of [drawkitFocusRingRect] for discs (radios, icon
/// buttons): a second circle at `radius + gap`.
DrawkitLayer drawkitFocusRingCircle({
  required Offset center,
  required double radius,
  required RoughOptions options,
  required DrawkitStyle style,
  Color? color,
  double gap = 1,
}) => DrawkitLayer(
  roughCircle(center.dx, center.dy, radius + gap, options),
  drawkitStroke(style, color: color, fallbackWidth: 1.5),
);

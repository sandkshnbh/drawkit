import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// The pen's idle shapes: purely decorative squiggles for corners, dividers,
/// and empty states. Always excluded from semantics and never interactive.
enum DrawkitDoodleKind { star, squiggle, spiral, burst, arrow }

/// A drawn doodle in a square box, boiling with the rest of the page.
class DrawkitDoodle extends StatelessWidget {
  const DrawkitDoodle({
    required this.kind,
    this.size = 40,
    this.color,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final DrawkitDoodleKind kind;
  final double size;

  /// Pen colour; defaults to the house ink.
  final Color? color;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  Path _starPath(Size size, RoughOptions options) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.shortestSide / 2 - 3;
    final inner = outer * 0.46;
    final points = [
      for (var k = 0; k < 10; k++)
        Offset(
          cx +
              math.cos(-math.pi / 2 + k * math.pi / 5) *
                  (k.isEven ? outer : inner),
          cy +
              math.sin(-math.pi / 2 + k * math.pi / 5) *
                  (k.isEven ? outer : inner),
        ),
    ];
    return doubleStroke(points, options, close: true);
  }

  Path _squigglePath(Size size, RoughOptions options) {
    final w = size.width - 6;
    final mid = size.height / 2;
    final amp = size.height * 0.18;
    final points = [
      for (var x = 0.0; x <= w; x += 2)
        Offset(3 + x, mid + math.sin(x / w * math.pi * 4) * amp),
    ];
    return smooth(points, close: false);
  }

  Path _spiralPath(Size size, RoughOptions options) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide / 2 - 3;
    final points = [
      for (var t = 0.0; t <= math.pi * 4.6; t += 0.14)
        Offset(
          cx + math.cos(t) * (maxR * t / (math.pi * 4.6)),
          cy + math.sin(t) * (maxR * t / (math.pi * 4.6)),
        ),
    ];
    return smooth(points, close: false);
  }

  List<Path> _burstPaths(Size size, RoughOptions options) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.shortestSide / 2 - 3;
    return [
      for (var k = 0; k < 8; k++)
        roughLine(
          cx + math.cos(k * math.pi / 4) * outer * 0.4,
          cy + math.sin(k * math.pi / 4) * outer * 0.4,
          cx + math.cos(k * math.pi / 4) * outer,
          cy + math.sin(k * math.pi / 4) * outer,
          options,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final ink = color ?? resolved.effectiveStroke;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: DrawkitSurface(
          size: Size.square(size),
          builder: (size, options) {
            final stroke = drawkitStroke(
              resolved,
              color: ink,
              fallbackWidth: 1.5,
            );
            final paths = switch (kind) {
              DrawkitDoodleKind.star => [_starPath(size, options)],
              DrawkitDoodleKind.squiggle => [_squigglePath(size, options)],
              DrawkitDoodleKind.spiral => [_spiralPath(size, options)],
              DrawkitDoodleKind.burst => _burstPaths(size, options),
              DrawkitDoodleKind.arrow => [
                roughArrow(4, size.height - 4, size.width - 4, 4, options),
              ],
            };
            return [for (final path in paths) DrawkitLayer(path, stroke)];
          },
          style: resolved,
          seed: seed,
          animate: animate,
        ),
      ),
    );
  }
}

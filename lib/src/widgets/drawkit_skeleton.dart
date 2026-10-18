import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// Placeholder strokes shown while content loads: faint pen lines with a
/// shading band sweeping along each one, offset a step per line.
///
/// [DrawkitSkeleton.circle] is the same idea for avatars. Purely decorative
/// (excluded from semantics), and reduced motion parks the bands.
class DrawkitSkeleton extends StatefulWidget {
  const DrawkitSkeleton({
    this.lines = 3,
    this.lineHeight = 12,
    this.spacing = 10,
    this.lastLineFactor = 0.62,
    this.size = 0,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : assert(lines > 0);

  const DrawkitSkeleton.circle({
    this.size = 44,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : lines = 0,
       lineHeight = 0,
       spacing = 0,
       lastLineFactor = 1;

  final int lines;
  final double lineHeight;
  final double spacing;
  final double lastLineFactor;
  final double size;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitSkeleton> createState() => _DrawkitSkeletonState();
}

class _DrawkitSkeletonState extends State<DrawkitSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(DrawkitSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) _syncMotion();
  }

  void _syncMotion() {
    final motion = widget.animate && !drawkitReduceMotion(context);
    if (motion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final faint = resolved.effectiveStroke.withValues(alpha: 0.35);
    final shade = resolved.effectiveStroke.withValues(alpha: 0.10);

    if (widget.lines == 0) {
      return ExcludeSemantics(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: DrawkitSurface(
            builder: (size, options) {
              final cx = size.width / 2;
              final cy = size.height / 2;
              final r = math.min(size.width, size.height) / 2 - 1;
              final rr = r - 2;
              const a0 = -0.5;
              const a1 = 1.18;
              return [
                DrawkitLayer(
                  roughCircle(cx, cy, r, options),
                  drawkitStroke(resolved, color: faint, fallbackWidth: 1.5),
                ),
                DrawkitLayer(
                  roughLine(
                    cx + rr * math.cos(a0),
                    cy + rr * math.sin(a0),
                    cx + rr * math.cos(a1),
                    cy + rr * math.sin(a1),
                    options,
                  ),
                  drawkitStroke(resolved, color: shade, fallbackWidth: 6),
                  matrix: () =>
                      Matrix4.translationValues(cx, cy, 0) *
                      Matrix4.rotationZ(2 * math.pi * _controller.value) *
                      Matrix4.translationValues(-cx, -cy, 0),
                ),
              ];
            },
            style: resolved,
            seed: widget.seed,
            animate: widget.animate,
            accent: _controller,
            size: Size.square(widget.size),
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final sweep = Directionality.maybeOf(context) == TextDirection.rtl
              ? -1.0
              : 1.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.lines; i++) ...[
                if (i > 0) SizedBox(height: widget.spacing),
                Builder(
                  builder: (context) {
                    final lineWidth = i == widget.lines - 1
                        ? width * widget.lastLineFactor
                        : width;
                    return SizedBox(
                      width: lineWidth,
                      height: widget.lineHeight,
                      child: DrawkitSurface(
                        builder: (size, options) {
                          final bandW = size.width * 0.35;
                          final travel = size.width - bandW;
                          return [
                            DrawkitLayer(
                              roughRoundedRect(
                                0,
                                0,
                                size.width,
                                size.height,
                                size.height / 2,
                                options,
                              ),
                              drawkitStroke(
                                resolved,
                                color: faint,
                                fallbackWidth: 1.5,
                              ),
                            ),
                            DrawkitLayer(
                              roughRoundedRect(
                                0,
                                1,
                                bandW,
                                size.height - 2,
                                size.height / 2 - 1,
                                options,
                              ),
                              drawkitFillPaint(shade),
                              matrix: () {
                                final phase =
                                    (_controller.value + i * 0.18) % 1.0;
                                final eased =
                                    0.5 - 0.5 * math.cos(2 * math.pi * phase);
                                return Matrix4.translationValues(
                                  sweep * eased * travel,
                                  0,
                                  0,
                                );
                              },
                            ),
                          ];
                        },
                        style: resolved,
                        seed: widget.seed == null ? null : widget.seed! + i,
                        animate: widget.animate,
                        accent: _controller,
                        size: Size(lineWidth, widget.lineHeight),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 2;

/// A sketch progress bar: ruled track, ink fill growing from the leading edge.
///
/// A [value] of null draws the indeterminate state — a shading band sweeping
/// the track back and forth on one clock. Both honour reduced motion (the
/// sweep parks in place) and RTL (the fill grows from the right).
class DrawkitProgressBar extends StatefulWidget {
  const DrawkitProgressBar({
    this.value,
    this.height = 12,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  /// 0..1, or null for the indeterminate sweep.
  final double? value;

  final double height;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitProgressBar> createState() => _DrawkitProgressBarState();
}

class _DrawkitProgressBarState extends State<DrawkitProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  bool get _indeterminate => widget.value == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _syncMotion();
  }

  @override
  void didUpdateWidget(DrawkitProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate ||
        _indeterminate != (oldWidget.value == null)) {
      _syncMotion();
    }
  }

  void _syncMotion() {
    final motion =
        widget.animate && _indeterminate && !drawkitReduceMotion(context);
    if (motion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _ink(DrawkitStyle style) => style.ink ?? style.effectiveStroke;

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
    bool rtl,
  ) {
    final w = size.width;
    final h = size.height;
    final inner = w - 2 * _inset;
    final radius = (h - 2 * _inset) / 2;
    final ink = _ink(style);
    final layers = <DrawkitLayer>[
      DrawkitLayer(
        roughRoundedRect(
          _inset,
          _inset,
          w - 2 * _inset,
          h - 2 * _inset,
          radius,
          options,
        ),
        drawkitStroke(style, fallbackWidth: 1.5),
      ),
    ];

    if (!_indeterminate) {
      final fraction = widget.value!.clamp(0.0, 1.0);
      final fillW = (inner - 2) * fraction;
      if (fillW > 1) {
        final x = rtl ? w - _inset - 1 - fillW : _inset + 1;
        layers.add(
          DrawkitLayer(
            roughRoundedRect(
              x,
              _inset + 1,
              fillW,
              h - 2 * _inset - 2,
              math.max(1, radius - 1),
              options,
            ),
            drawkitFillPaint(ink),
          ),
        );
      }
      return layers;
    }

    final bandW = (inner - 2) * 0.32;
    final travel = w - 2 * _inset - 2 - bandW;
    layers.add(
      DrawkitLayer(
        roughRoundedRect(
          _inset + 1,
          _inset + 2,
          bandW,
          h - 2 * _inset - 4,
          math.max(1, radius - 2),
          options,
        ),
        drawkitFillPaint(ink.withValues(alpha: 0.45)),
        matrix: () {
          final phase = _controller.value;
          final eased = 0.5 - 0.5 * math.cos(2 * math.pi * phase);
          return Matrix4.translationValues(
            rtl ? (1 - eased) * travel : eased * travel,
            0,
            0,
          );
        },
      ),
    );
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final fraction = widget.value?.clamp(0.0, 1.0);
    return Semantics(
      label: widget.semanticLabel,
      value: fraction == null ? null : '${(fraction * 100).round()}%',
      child: DrawkitSurface(
        builder: (size, options) => _layers(size, options, resolved, rtl),
        style: resolved,
        seed: widget.seed,
        animate: widget.animate,
        accent: _indeterminate ? _controller : null,
        child: SizedBox(height: widget.height, width: double.infinity),
      ),
    );
  }
}

/// A pencil-drawn loading circle: eight chord dashes turning on one clock.
///
/// Pure rotation, so the loop never pops; reduced motion parks the dashes.
class DrawkitSpinner extends StatefulWidget {
  const DrawkitSpinner({
    this.size = 24,
    this.semanticLabel = 'loading',
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final double size;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitSpinner> createState() => _DrawkitSpinnerState();
}

class _DrawkitSpinnerState extends State<DrawkitSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _syncMotion();
  }

  @override
  void didUpdateWidget(DrawkitSpinner oldWidget) {
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

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
  ) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 4;
    const dashes = 8;
    const span = 0.55; // share of each slot that carries ink
    final layers = <DrawkitLayer>[];
    for (var i = 0; i < dashes; i++) {
      final a0 = 2 * math.pi * (i / dashes - span / 4);
      final a1 = 2 * math.pi * ((i + span) / dashes - span / 4);
      final weight = 0.35 + 0.65 * (i / (dashes - 1));
      layers.add(
        DrawkitLayer(
          roughLine(
            cx + r * math.cos(a0),
            cy + r * math.sin(a0),
            cx + r * math.cos(a1),
            cy + r * math.sin(a1),
            options,
          ),
          drawkitStroke(style)..strokeWidth = style.strokeWidth(2.4) * weight,
          matrix: () {
            final angle = 2 * math.pi * _controller.value;
            return Matrix4.translationValues(cx, cy, 0) *
                Matrix4.rotationZ(angle) *
                Matrix4.translationValues(-cx, -cy, 0);
          },
        ),
      );
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    return Semantics(
      label: widget.semanticLabel,
      child: DrawkitSurface(
        builder: (size, options) => _layers(size, options, resolved),
        style: resolved,
        seed: widget.seed,
        animate: widget.animate,
        accent: _controller,
        size: Size.square(widget.size),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../engine/prng.dart';
import '../engine/rough.dart';
import 'motion.dart';
import 'style.dart';

/// One painted path with its paint, the Dart analogue of a `<path>` element.
///
/// [trimTo] and [matrix] are the two CSS animations that aren't the boil:
/// `stroke-dashoffset` draw-on (check) and `transform` transitions (dot,
/// knob). They are read at paint time so frames never need rebuilding.
class DrawkitLayer {
  const DrawkitLayer(this.path, this.paint, {this.trimTo, this.matrix});

  final Path path;
  final Paint paint;

  /// Draw-on fraction 0..1 (`pathLength: 1` + `stroke-dashoffset` in the CSS).
  final Animation<double>? trimTo;

  /// Applied around the layer before drawing (the dot's scale, the knob's
  /// travel). Must be the surface's [DrawkitSurface.accent] when it animates,
  /// so repaints are subscribed.
  final Matrix4 Function()? matrix;
}

/// Builds the sketch layers for a box of [size]. Called once per boil frame,
/// so it must not read mutable widget state that changes per animation tick.
typedef DrawkitLayerBuilder = List<DrawkitLayer> Function(
  Size size,
  RoughOptions options,
);

/// A pen-stroked stroke paint. Controls default to 2px, decorations to 1.5.
Paint drawkitStroke(
  DrawkitStyle style, {
  Color? color,
  double fallbackWidth = 2,
}) => Paint()
  ..color = color ?? style.effectiveStroke
  ..style = PaintingStyle.stroke
  ..strokeWidth = style.strokeWidth(fallbackWidth)
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint drawkitFillPaint(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

/// Paints a sketch behind its child, exactly like drawably's absolutely
/// positioned SVG: real content on top, decoration behind, never interactive.
///
/// Animation is one shared step clock over pre-built frames instead of the
/// CSS `step-end` keyframes; all layers swap frames together, so strokes can
/// never sample out of step (the bug the JS comment warns about).
class DrawkitSurface extends StatefulWidget {
  const DrawkitSurface({
    super.key,
    required this.builder,
    this.child,
    this.style,
    this.seed,
    this.animate = true,
    this.resketchOnPointer = false,
    this.enabled = true,
    this.cursor,
    this.onTap,
    this.onHoverChanged,
    this.onPressedChanged,
    this.duration = const Duration(milliseconds: 1200),
    this.boilClock,
    this.accent,
    this.size,
  }) : assert(size == null || child == null);

  final DrawkitLayerBuilder builder;
  final Widget? child;
  final DrawkitStyle? style;

  /// Fixed seed; when null the surface draws one, and re-draws on hover/down
  /// when [resketchOnPointer] is set (the attacher's default behaviour).
  final int? seed;
  final bool animate;
  final bool resketchOnPointer;
  final bool enabled;
  final MouseCursor? cursor;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onPressedChanged;

  /// Boil cycle; the loading button shortens it (450ms in the CSS).
  final Duration duration;

  /// Shared boil clock. Controls with several painted pieces (the check
  /// accents) own one controller and pass it here so every stroke steps
  /// frames together — the guarantee the single CSS animation gives.
  final Animation<double>? boilClock;

  /// Secondary repaint driver for trim/matrix layers (the check draw-on, the
  /// radio dot, the toggle knob). Frames stay cached; only the paint pass
  /// re-runs while this animates.
  final Listenable? accent;

  /// Required when there is no child: CustomPaint sizes itself from one.
  final Size? size;

  @override
  State<DrawkitSurface> createState() => DrawkitSurfaceState();
}

class DrawkitSurfaceState extends State<DrawkitSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late int _seed = widget.seed ?? randomSeed();
  bool _boiling = false;
  bool _hovered = false;

  /// New pen stroke: a fresh seed unless one is forced. Same contract as
  /// `resketch(seed?)` on the JS handle.
  void resketch([int? seed]) => setState(() => _seed = seed ?? randomSeed());

  @override
  void didUpdateWidget(DrawkitSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
    if (oldWidget.enabled && !widget.enabled) {
      final wasHovered = _hovered;
      _hovered = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.enabled) return;
        if (wasHovered) widget.onHoverChanged?.call(false);
        widget.onPressedChanged?.call(false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncBoil(bool shouldBoil) {
    if (shouldBoil == _boiling) return;
    _boiling = shouldBoil;
    if (shouldBoil) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  void _onPointerEnter(PointerEnterEvent event) {
    setState(() => _hovered = true);
    widget.onHoverChanged?.call(true);
    if (widget.resketchOnPointer &&
        widget.enabled &&
        !drawkitReduceMotion(context)) {
      resketch();
    }
  }

  void _onPointerExit(PointerExitEvent event) {
    setState(() => _hovered = false);
    widget.onHoverChanged?.call(false);
  }

  void _onPointerDown(PointerDownEvent event) {
    widget.onPressedChanged?.call(true);
    if (widget.resketchOnPointer &&
        widget.enabled &&
        !drawkitReduceMotion(context)) {
      resketch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final reduceMotion = drawkitReduceMotion(context);
    final boil = widget.animate && style.boil > 0 && !reduceMotion;
    _syncBoil(boil && widget.boilClock == null);

    final painter = _DrawkitSurfacePainter(
      builder: widget.builder,
      style: style,
      seed: _seed,
      frameCount: boil ? 3 : 1,
      animation: boil ? widget.boilClock ?? _controller : null,
      accent: widget.accent,
      sketchTrim: DrawkitSketchScope.maybeOf(context),
    );

    Widget painted = RepaintBoundary(
      child: CustomPaint(
        painter: painter,
        size: widget.size ?? Size.zero,
        isComplex: false,
        willChange: boil,
        child: widget.child,
      ),
    );

    if (!widget.enabled) {
      return Opacity(
        opacity: 0.45,
        child: MouseRegion(
          cursor: widget.cursor ?? MouseCursor.defer,
          child: painted,
        ),
      );
    }

    return MouseRegion(
      cursor:
          widget.cursor ??
          (_hovered ? SystemMouseCursors.click : MouseCursor.defer),
      onEnter: _onPointerEnter,
      onExit: _onPointerExit,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: (_) => widget.onPressedChanged?.call(false),
        onPointerCancel: (_) => widget.onPressedChanged?.call(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: painted,
        ),
      ),
    );
  }
}

class _DrawkitSurfacePainter extends CustomPainter {
  _DrawkitSurfacePainter({
    required this.builder,
    required this.style,
    required this.seed,
    required this.frameCount,
    required Animation<double>? animation,
    required Listenable? accent,
    required Animation<double>? sketchTrim,
  }) : _animation = animation,
       _accent = accent,
       _sketchTrim = sketchTrim,
       super(repaint: _mergeRepaint([animation, accent, sketchTrim]));

  final DrawkitLayerBuilder builder;
  final DrawkitStyle style;
  final int seed;
  final int frameCount;
  final Animation<double>? _animation;
  final Listenable? _accent;

  /// Ambient draw-on progress from a [DrawkitSketchScope]; strokes trim to it
  /// at paint time, frames never rebuild.
  final Animation<double>? _sketchTrim;

  Size? _cachedSize;
  List<List<DrawkitLayer>> _frames = const [];

  void _buildFrames(Size size) {
    _cachedSize = size;
    final base = RoughOptions(
      seed: seed,
      roughness: style.roughness,
      boil: style.boil,
    );
    _frames = variants((o) => builder(size, o), base, frameCount);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedSize != size) _buildFrames(size);
    if (_frames.isEmpty) return;
    final index = _animation == null
        ? 0
        : (_animation.value * _frames.length).floor() % _frames.length;
    final sketch = _sketchTrim?.value.clamp(0.0, 1.0) ?? 1.0;
    for (final layer in _frames[index]) {
      var trim = sketch;
      if (layer.trimTo != null) trim *= layer.trimTo!.value.clamp(0.0, 1.0);
      if (trim <= 0) continue;
      var path = layer.path;
      if (trim < 1) {
        // PathMetrics caches its iterator: probe once with firstOrNull.
        final metric = path.computeMetrics().firstOrNull;
        if (metric == null) continue;
        path = metric.extractPath(0, metric.length * trim);
      }
      canvas.save();
      if (layer.matrix != null) canvas.transform(layer.matrix!.call().storage);
      canvas.drawPath(path, layer.paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DrawkitSurfacePainter oldDelegate) =>
      builder != oldDelegate.builder ||
      seed != oldDelegate.seed ||
      style != oldDelegate.style ||
      frameCount != oldDelegate.frameCount ||
      _animation != oldDelegate._animation ||
      _accent != oldDelegate._accent ||
      _sketchTrim != oldDelegate._sketchTrim;
}

Listenable? _mergeRepaint(List<Listenable?> drivers) {
  final active = [for (final driver in drivers) ?driver];
  return active.isEmpty ? null : Listenable.merge(active);
}

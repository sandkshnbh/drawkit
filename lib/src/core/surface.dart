import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../engine/prng.dart';
import '../engine/rough.dart';
import 'style.dart';

/// One painted path with its paint, the Dart analogue of a `<path>` element.
class DrawkitLayer {
  const DrawkitLayer(this.path, this.paint);

  final Path path;
  final Paint paint;
}

/// Builds the sketch layers for a box of [size]. Called once per boil frame,
/// so it must not read mutable widget state that changes per animation tick.
typedef DrawkitLayerBuilder = List<DrawkitLayer> Function(Size size, RoughOptions options);

/// A pen-stroked stroke paint. Controls default to 2px, decorations to 1.5.
Paint drawkitStroke(DrawkitStyle style, {Color? color, double fallbackWidth = 2}) => Paint()
  ..color = color ?? style.effectiveStroke
  ..style = PaintingStyle.stroke
  ..strokeWidth = style.strokeWidth(fallbackWidth)
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint drawkitFillPaint(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

/// True when the platform asks for reduced motion. Mirrors the CSS
/// `prefers-reduced-motion` block: boil freezes on frame 0, transitions and
/// pointer re-sketches are skipped.
bool drawkitReduceMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media != null && media.disableAnimations) return true;
  return PlatformDispatcher.instance.accessibilityFeatures.reduceMotion;
}

/// Paints a sketch behind its child, exactly like drawably's absolutely
/// positioned SVG: real content on top, decoration behind, never interactive.
///
/// Animation is one shared step clock over pre-built frames instead of the
/// CSS `step-end` keyframes; all layers swap frames together, so strokes can
/// never sample out of step (the bug the JS comment warns about).
class DrawkitSurface extends StatefulWidget {
  const DrawkitSurface({
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
    this.size,
    super.key,
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

  /// Required when there is no child: CustomPaint sizes itself from one.
  final Size? size;

  @override
  State<DrawkitSurface> createState() => DrawkitSurfaceState();
}

class DrawkitSurfaceState extends State<DrawkitSurface> with SingleTickerProviderStateMixin {
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
    if (widget.seed != null && widget.seed != oldWidget.seed) _seed = widget.seed!;
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
    if (widget.resketchOnPointer && widget.enabled && !drawkitReduceMotion(context)) resketch();
  }

  void _onPointerExit(PointerExitEvent event) {
    setState(() => _hovered = false);
    widget.onHoverChanged?.call(false);
  }

  void _onPointerDown(PointerDownEvent event) {
    widget.onPressedChanged?.call(true);
    if (widget.resketchOnPointer && widget.enabled && !drawkitReduceMotion(context)) resketch();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final reduceMotion = drawkitReduceMotion(context);
    final boil = widget.animate && style.boil > 0 && !reduceMotion;
    _syncBoil(boil);

    final painter = _DrawkitSurfacePainter(
      builder: widget.builder,
      style: style,
      seed: _seed,
      frameCount: boil ? 3 : 1,
      animation: boil ? _controller : null,
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
        child: MouseRegion(cursor: widget.cursor ?? MouseCursor.defer, child: painted),
      );
    }

    return MouseRegion(
      cursor: widget.cursor ?? (_hovered ? SystemMouseCursors.click : MouseCursor.defer),
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
  }) : _animation = animation,
       super(repaint: animation);

  final DrawkitLayerBuilder builder;
  final DrawkitStyle style;
  final int seed;
  final int frameCount;
  final Animation<double>? _animation;

  Size? _cachedSize;
  List<List<DrawkitLayer>> _frames = const [];

  void _buildFrames(Size size) {
    _cachedSize = size;
    final base = RoughOptions(seed: seed, roughness: style.roughness, boil: style.boil);
    _frames = variants((o) => builder(size, o), base, frameCount);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedSize != size) _buildFrames(size);
    if (_frames.isEmpty) return;
    final index = _animation == null
        ? 0
        : (_animation.value * _frames.length).floor() % _frames.length;
    for (final layer in _frames[index]) {
      canvas.drawPath(layer.path, layer.paint);
    }
  }

  @override
  bool shouldRepaint(_DrawkitSurfacePainter oldDelegate) =>
      seed != oldDelegate.seed ||
      style != oldDelegate.style ||
      frameCount != oldDelegate.frameCount ||
      _animation != oldDelegate._animation;
}

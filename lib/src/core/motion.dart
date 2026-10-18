import 'dart:math' as math;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'style.dart';

/// True when the platform asks for reduced motion. Mirrors the CSS
/// `prefers-reduced-motion` block: boil freezes on frame 0, transitions and
/// pointer re-sketches are skipped.
bool drawkitReduceMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media != null && media.disableAnimations) return true;
  return PlatformDispatcher.instance.accessibilityFeatures.reduceMotion;
}

/// Carries a draw-on progress down to every [DrawkitSurface] below it.
///
/// Surfaces read the animation at paint time and trim each stroke to it, so
/// the whole subtree traces itself in together, the way one pen would. Ticks
/// never rebuild anything: the scope only changes when the animation object
/// does.
class DrawkitSketchScope extends InheritedWidget {
  const DrawkitSketchScope({
    required this.progress,
    required super.child,
    super.key,
  });

  /// 0 = bare paper, 1 = fully drawn.
  final Animation<double> progress;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DrawkitSketchScope>()
      ?.progress;

  @override
  bool updateShouldNotify(DrawkitSketchScope oldWidget) =>
      progress != oldWidget.progress;
}

/// Traces the sketch of everything below it when it first mounts.
///
/// Wrap any subtree; every [DrawkitSurface] inside trims its strokes from 0
/// to full over [duration]. Reduced-motion platforms start at a full drawing.
class DrawkitSketchIn extends StatefulWidget {
  const DrawkitSketchIn({
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.curve = drawkitEase,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<DrawkitSketchIn> createState() => _DrawkitSketchInState();
}

class _DrawkitSketchInState extends State<DrawkitSketchIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = drawkitReduceMotion(context);
    if (!_started) {
      _started = true;
      if (reduced) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      return;
    }
    if (reduced && _controller.value < 1) _controller.value = 1;
  }

  @override
  void didUpdateWidget(DrawkitSketchIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    _progress.curve = widget.curve;
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      DrawkitSketchScope(progress: _progress, child: widget.child);
}

/// Draws a list of children in one after another, [step] apart.
///
/// One shared clock drives every child through its own [Interval]; count a
/// new run by rebuilding with a fresh [Key].
class DrawkitStagger extends StatefulWidget {
  const DrawkitStagger({
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.step = const Duration(milliseconds: 90),
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  final List<Widget> children;

  /// Draw-on time of a single child.
  final Duration duration;

  /// Delay between one child's start and the next.
  final Duration step;

  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<DrawkitStagger> createState() => _DrawkitStaggerState();
}

class _DrawkitStaggerState extends State<DrawkitStagger>
    with SingleTickerProviderStateMixin {
  late Duration _total = _computeTotal();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );
  late List<Animation<double>> _progress = _computeProgress();
  bool _started = false;

  Duration _computeTotal() =>
      widget.duration + widget.step * math.max(0, widget.children.length - 1);

  List<Animation<double>> _computeProgress() => [
    for (var i = 0; i < widget.children.length; i++) _intervalFor(i),
  ];

  Animation<double> _intervalFor(int i) {
    if (_total.inMicroseconds <= 0) return kAlwaysCompleteAnimation;
    final total = _total.inMicroseconds;
    final begin = widget.step.inMicroseconds * i / total;
    final end = begin + widget.duration.inMicroseconds / total;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        begin.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: drawkitEase,
      ),
    );
  }

  @override
  void didUpdateWidget(DrawkitStagger oldWidget) {
    super.didUpdateWidget(oldWidget);
    final total = _computeTotal();
    if (total == _total &&
        widget.children.length == oldWidget.children.length) {
      return;
    }
    _disposeProgress();
    _total = total;
    _controller.duration = _total;
    _progress = _computeProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = drawkitReduceMotion(context);
    if (!_started) {
      _started = true;
      if (reduced) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      return;
    }
    if (reduced && _controller.value < 1) _controller.value = 1;
  }

  void _disposeProgress() {
    for (final progress in _progress) {
      if (progress is CurvedAnimation) progress.dispose();
    }
  }

  @override
  void dispose() {
    _disposeProgress();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: widget.spacing,
    crossAxisAlignment: widget.crossAxisAlignment,
    children: [
      for (var i = 0; i < widget.children.length; i++)
        DrawkitSketchScope(progress: _progress[i], child: widget.children[i]),
    ],
  );
}

/// The trigger half of [DrawkitShake]: call [shake] to replay the wiggle on
/// every listening [DrawkitShake].
class DrawkitShakeController extends ChangeNotifier {
  int _ticks = 0;

  /// How many times [shake] was called; widgets watch for changes.
  int get ticks => _ticks;

  void shake() {
    _ticks++;
    notifyListeners();
  }
}

/// The "wrong!" wiggle: a damped horizontal shake around the child, replayed
/// whenever its [controller] fires. Reduced-motion platforms stay still.
class DrawkitShake extends StatefulWidget {
  const DrawkitShake({
    required this.controller,
    required this.child,
    this.amplitude = 6,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final DrawkitShakeController controller;
  final Widget child;

  /// Peak horizontal travel in pixels.
  final double amplitude;

  final Duration duration;

  @override
  State<DrawkitShake> createState() => _DrawkitShakeState();
}

class _DrawkitShakeState extends State<DrawkitShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  int _seen = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _seen = widget.controller.ticks;
    widget.controller.addListener(_onShake);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = drawkitReduceMotion(context);
  }

  @override
  void didUpdateWidget(DrawkitShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onShake);
      _seen = widget.controller.ticks;
      widget.controller.addListener(_onShake);
    }
  }

  void _onShake() {
    if (!mounted || _reduced) return;
    if (widget.controller.ticks == _seen) return;
    _seen = widget.controller.ticks;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onShake);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = _controller.value;
      final dx = t == 0
          ? 0.0
          : math.sin(t * math.pi * 3) * (1 - t) * widget.amplitude;
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
    child: widget.child,
  );
}

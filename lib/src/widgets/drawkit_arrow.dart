import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/prng.dart';
import '../engine/rough.dart';

/// Breathing room between an anchor's box edge and the arrow's end.
const double _arrowGap = 6;

/// An arrow between two widgets, the Dart port of `drawablyArrow`.
///
/// The JS version lives on `<body>` in document coordinates and redraws on
/// resize; here the widget paints outside its own box (never clipped — put it
/// in a [Stack] with `clipBehavior: Clip.none`) and a post-frame poll watches
/// both anchor rects, rebuilding when either moves. Same seed, same arrow.
class DrawkitArrow extends StatefulWidget {
  const DrawkitArrow({
    required this.from,
    required this.to,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final GlobalKey from;
  final GlobalKey to;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitArrow> createState() => _DrawkitArrowState();
}

class _DrawkitArrowState extends State<DrawkitArrow> {
  final GlobalKey _selfKey = GlobalKey();
  final _AnchorPoll _anchorPoll = _AnchorPoll();

  int get _seed => widget.seed ?? _fallbackSeed;
  late final int _fallbackSeed = randomSeed();

  @override
  void initState() {
    super.initState();
    _configurePoll();
    _anchorPoll.addListener(_onAnchorsMoved);
    SchedulerBinding.instance.addPostFrameCallback(_anchorPoll.tick);
  }

  /// A repaint alone would reuse the frames the painter cached for its size,
  /// still holding the pre-layout rects. Rebuilding hands the painter a fresh
  /// cache, so the arrow appears as soon as the anchors land.
  void _onAnchorsMoved() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(DrawkitArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configurePoll();
  }

  @override
  void dispose() {
    _anchorPoll.removeListener(_onAnchorsMoved);
    _anchorPoll.dispose();
    super.dispose();
  }

  void _configurePoll() => _anchorPoll
    ..from = widget.from
    ..to = widget.to
    ..self = _selfKey;

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    return IgnorePointer(
      child: DrawkitSurface(
        key: _selfKey,
        builder: (size, options) => [_arrowLayer(size, options, style)],
        style: style,
        seed: _seed,
        animate: widget.animate,
        resketchOnPointer: false,
        child: const SizedBox.expand(),
      ),
    );
  }

  DrawkitLayer _arrowLayer(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
  ) {
    final a = _anchorPoll.rectOf(widget.from);
    final b = _anchorPoll.rectOf(widget.to);
    if (a == null || b == null) {
      return DrawkitLayer(Path(), drawkitStroke(style));
    }
    final ax = a.center.dx;
    final ay = a.center.dy;
    final bx = b.center.dx;
    final by = b.center.dy;
    final dx = bx - ax;
    final dy = by - ay;
    final hypot = math.sqrt(dx * dx + dy * dy);
    final len = hypot == 0 ? 1.0 : hypot;
    final ux = dx / len;
    final uy = dy / len;

    // distance from a box's centre to its edge along the centre line; the
    // JS `|| 0` turns the 0/0 of a zero-size box into "no inset"
    double exit(Rect r) {
      final result = math.min(r.width / 2 / ux.abs(), r.height / 2 / uy.abs());
      return result.isNaN ? 0.0 : result;
    }

    final t0 = math.min(exit(a) + _arrowGap, len / 2);
    final t1 = math.min(exit(b) + _arrowGap, len / 2);
    return DrawkitLayer(
      roughArrow(
        ax + ux * t0,
        ay + uy * t0,
        bx - ux * t1,
        by - uy * t1,
        options,
      ),
      drawkitStroke(style),
    );
  }
}

/// Polls both anchor rects after every frame and notifies when they move.
class _AnchorPoll extends ChangeNotifier {
  GlobalKey? from;
  GlobalKey? to;
  GlobalKey? self;
  Rect? _lastA;
  Rect? _lastB;
  Offset _selfOrigin = Offset.zero;
  bool _disposed = false;

  Rect? _globalRect(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Anchor rect relative to the arrow's own origin.
  Rect? rectOf(GlobalKey key) => _globalRect(key)?.shift(-_selfOrigin);

  void tick(Duration _) {
    if (_disposed) return;
    final selfBox = self?.currentContext?.findRenderObject() as RenderBox?;
    if (selfBox != null && selfBox.hasSize) {
      _selfOrigin = selfBox.localToGlobal(Offset.zero);
    }
    final a = _globalRect(from);
    final b = _globalRect(to);
    if (a != _lastA || b != _lastB) {
      _lastA = a;
      _lastB = b;
      notifyListeners();
    }
    SchedulerBinding.instance.addPostFrameCallback(tick);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

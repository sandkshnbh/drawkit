import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/style.dart';
import 'drawkit_doodle.dart';
import 'drawkit_progress.dart';

/// Pull-to-refresh, drawn with the same pen: while the user drags an
/// over-scrolled top edge, an arrow doodle rotates with the pull; past
/// [threshold] it has flipped all the way and releasing hands off to
/// [onRefresh], with a spinning pencil standing in until the future settles.
///
/// The child must be a scrollable with room to overscroll (a [ListView] with
/// [AlwaysScrollableScrollPhysics] when the content can be shorter than the
/// viewport). Both clamping (Android) and bouncing (iOS) physics are
/// supported, since the indicator listens to the notifications each of them
/// produces. Reduced motion snaps instead of sliding.
class DrawkitRefresh extends StatefulWidget {
  const DrawkitRefresh({
    required this.onRefresh,
    required this.child,
    this.threshold = 72,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  /// Runs when a pull passes the threshold; the indicator stays up until the
  /// returned future completes.
  final Future<void> Function() onRefresh;

  final Widget child;

  /// Pull distance in logical pixels that arms the refresh.
  final double threshold;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitRefresh> createState() => _DrawkitRefreshState();
}

class _DrawkitRefreshState extends State<DrawkitRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  double _pull = 0;
  double _settleFrom = 0;
  bool _refreshing = false;

  double get _progress => (_pull / widget.threshold).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _settle.addListener(_onSettleTick);
  }

  void _onSettleTick() => setState(() {
    _pull = _settleFrom * (1 - Curves.easeOut.transform(_settle.value));
  });

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  bool _atTop(ScrollMetrics metrics) =>
      metrics.extentBefore <= 0 && metrics.pixels <= metrics.minScrollExtent;

  void _setPull(double value) {
    final next = value.clamp(0.0, widget.threshold);
    if (next == _pull) return;
    setState(() => _pull = next);
  }

  bool _onNotification(ScrollNotification notification) {
    if (_refreshing) return false;
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) _settle.stop();
      return false;
    }
    if (notification is OverscrollNotification) {
      if (notification.dragDetails != null &&
          notification.overscroll < 0 &&
          _atTop(notification.metrics)) {
        _setPull(_pull - notification.overscroll);
      }
      return false;
    }
    // Bouncing physics move pixels below the top during the drag itself.
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (notification.dragDetails != null &&
          metrics.pixels < metrics.minScrollExtent) {
        _setPull(metrics.minScrollExtent - metrics.pixels);
      }
      return false;
    }
    if (notification is ScrollEndNotification) {
      if (_progress >= 1) {
        _trigger();
      } else if (_pull > 0) {
        _settleBack(clearing: false);
      }
    }
    return false;
  }

  Future<void> _trigger() async {
    setState(() {
      _refreshing = true;
      _pull = widget.threshold;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) await _settleBack(clearing: true);
    }
  }

  Future<void> _settleBack({required bool clearing}) async {
    _settleFrom = _pull;
    if (drawkitReduceMotion(context)) {
      if (mounted) {
        setState(() {
          _pull = 0;
          if (clearing) _refreshing = false;
        });
      }
      return;
    }
    try {
      await _settle.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted) {
      setState(() {
        _pull = 0;
        if (clearing) _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final progress = _progress;

    final Widget indicator = _refreshing
        ? DrawkitSpinner(size: 22, animate: widget.animate, style: style)
        : Transform.rotate(
            angle: math.pi * progress,
            child: DrawkitDoodle(
              kind: DrawkitDoodleKind.arrow,
              size: 22,
              style: style,
              seed: widget.seed,
              animate: widget.animate,
            ),
          );

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          widget.child,
          if (_pull > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: SizedBox(
                  height: _pull,
                  child: Center(
                    child: _refreshing
                        ? Semantics(
                            liveRegion: true,
                            label: 'refreshing',
                            child: ExcludeSemantics(child: indicator),
                          )
                        : ExcludeSemantics(child: indicator),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

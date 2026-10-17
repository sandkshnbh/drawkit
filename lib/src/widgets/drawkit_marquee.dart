import 'package:flutter/widgets.dart';

import '../core/motion.dart';

/// A ticker: [child] slides past forever, the copy behind it closing the
/// seam. Motion flows start→end, so it walks leftward in LTR and rightward
/// in RTL; hovering pauses it, reduced motion parks it.
///
/// Decorative: the track never absorbs pointers.
class DrawkitMarquee extends StatefulWidget {
  const DrawkitMarquee({
    required this.child,
    this.speed = 40,
    this.gap = 48,
    this.pauseOnHover = true,
    this.animate = true,
    super.key,
  }) : assert(speed > 0, 'a marquee needs a direction');

  final Widget child;

  /// Pixels per second.
  final double speed;

  /// Blank space between the child and its copy.
  final double gap;

  final bool pauseOnHover;
  final bool animate;

  @override
  State<DrawkitMarquee> createState() => _DrawkitMarqueeState();
}

class _DrawkitMarqueeState extends State<DrawkitMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  final GlobalKey _childKey = GlobalKey();
  double? _childWidth;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final width = _childKey.currentContext?.size?.width;
    if (width != null && width != _childWidth) {
      setState(() {
        _childWidth = width;
        _controller.duration = Duration(
          milliseconds: (((width + widget.gap) / widget.speed) * 1000).round(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final reduceMotion = drawkitReduceMotion(context);
    final running =
        widget.animate && !reduceMotion && !(widget.pauseOnHover && _paused);

    if (running && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!running && _controller.isAnimating) {
      _controller.stop();
    }

    final cycle = _childWidth == null ? null : _childWidth! + widget.gap;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        if (cycle != null) ...[SizedBox(width: widget.gap), widget.child],
      ],
    );

    if (cycle != null) {
      content = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dx = (rtl ? 1 : -1) * _controller.value * cycle;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _paused = true),
      onExit: (_) => setState(() => _paused = false),
      child: IgnorePointer(
        child: ClipRect(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: content,
          ),
        ),
      ),
    );
  }
}

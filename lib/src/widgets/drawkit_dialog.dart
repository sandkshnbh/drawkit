import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// The sketch-framed modal panel: paper fill, pen outline, rounded corners.
///
/// Use it inside [showDrawkitDialog], or standalone anywhere a framed panel
/// is wanted. The frame is drawn on mount so the dialog traces itself in.
class DrawkitDialog extends StatelessWidget {
  const DrawkitDialog({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth = 420,
    this.routeSemantics = false,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  /// Emits `scopesRoute`/`namesRoute`/label itself. Off by default: inside a
  /// dialog route the route already scopes the subtree, and doubling it
  /// announces the panel twice.
  final bool routeSemantics;

  /// The route's announced name when [routeSemantics] is on.
  final String? semanticLabel;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final panel = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DrawkitSurface(
        builder: (size, options) => [
          DrawkitLayer(
            roughRoundedRect(
              3,
              3,
              size.width - 6,
              size.height - 6,
              10,
              options,
            ),
            drawkitFillPaint(resolved.paperColor),
          ),
          DrawkitLayer(
            roughRoundedRect(
              3,
              3,
              size.width - 6,
              size.height - 6,
              10,
              options,
            ),
            drawkitStroke(resolved),
          ),
        ],
        style: resolved,
        seed: seed,
        animate: animate,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (!routeSemantics) return panel;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: semanticLabel,
      child: panel,
    );
  }
}

/// Opens [child] (usually a [DrawkitDialog]) as a modal route over a soft scrim.
///
/// The route fades and lifts the panel while the sketch traces itself in;
/// honourable motion settings skip straight to the finished drawing. Tapping
/// the scrim pops with `null` when [barrierDismissible] is set. The future
/// completes with whatever the dialog pops with. Tall content scrolls inside
/// the panel instead of overflowing the route.
Future<T?> showDrawkitDialog<T extends Object?>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? scrimColor,
  DrawkitStyle? style,
  int? seed,
  bool animate = true,
  double maxWidth = 420,
  EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  bool requestFocus = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Duration? transitionDuration,
  Offset? anchorPoint,
  bool fullscreenDialog = false,
}) {
  final reduceMotion = drawkitReduceMotion(context);
  final motion = animate && !reduceMotion;
  final resolved = style ?? DrawkitTheme.of(context);
  final duration = transitionDuration ?? const Duration(milliseconds: 220);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'drawkit dialog',
    barrierColor: scrimColor ?? resolved.palette.ink.withValues(alpha: 0.30),
    transitionDuration: motion ? duration : Duration.zero,
    requestFocus: requestFocus,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    pageBuilder: (context, animation, secondaryAnimation) => DrawkitTheme(
      data: resolved,
      child: DefaultTextStyle(
        style: drawkitRouteTextStyle(resolved),
        child: Align(
          alignment: fullscreenDialog ? Alignment.topCenter : Alignment.center,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: DrawkitSketchIn(
                  duration: motion
                      ? const Duration(milliseconds: 700)
                      : Duration.zero,
                  child: DrawkitDialog(
                    maxWidth: maxWidth,
                    padding: padding,
                    seed: seed,
                    animate: animate,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (!motion) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          alignment: anchorPoint == null
              ? Alignment.center
              : Alignment(anchorPoint.dx * 2 - 1, anchorPoint.dy * 2 - 1),
          child: child,
        ),
      );
    },
  );
}

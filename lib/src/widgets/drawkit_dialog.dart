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
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: 'dialog',
      child: ConstrainedBox(
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
      ),
    );
  }
}

/// Opens [child] (usually a [DrawkitDialog]) as a modal route over a soft scrim.
///
/// The route fades and lifts the panel while the sketch traces itself in;
/// honourable motion settings skip straight to the finished drawing. Tapping
/// the scrim pops with `null` when [barrierDismissible] is set. The future
/// completes with whatever the dialog pops with.
Future<T?> showDrawkitDialog<T extends Object?>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
  Color? scrimColor,
  DrawkitStyle? style,
  int? seed,
  bool animate = true,
}) {
  final reduceMotion = drawkitReduceMotion(context);
  final motion = animate && !reduceMotion;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'drawkit dialog',
    barrierColor: scrimColor ?? DrawkitPalette.ink.withValues(alpha: 0.30),
    transitionDuration: motion
        ? const Duration(milliseconds: 220)
        : Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => Center(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DrawkitSketchIn(
            duration: motion
                ? const Duration(milliseconds: 700)
                : Duration.zero,
            child: DrawkitDialog(
              style: style,
              seed: seed,
              animate: animate,
              child: child,
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
          child: child,
        ),
      );
    },
  );
}

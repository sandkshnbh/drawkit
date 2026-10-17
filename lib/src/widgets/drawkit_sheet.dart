import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

enum DrawkitSheetEdge { bottom, end }

/// The sketch panel behind [showDrawkitSheet]: paper fill, pen frame, and —
/// when it slides up from the bottom — a grab handle that can be dragged
/// down to dismiss (hook [onDismiss] to close the route).
class DrawkitSheet extends StatelessWidget {
  const DrawkitSheet({
    required this.child,
    this.edge = DrawkitSheetEdge.bottom,
    this.width = 420,
    this.maxHeightFactor = 0.8,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
    this.onDismiss,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final DrawkitSheetEdge edge;

  /// Panel width for the bottom and end edges alike.
  final double width;

  /// The bottom sheet never grows past this share of the viewport.
  final double maxHeightFactor;

  final EdgeInsetsGeometry padding;

  /// Called when the grab handle is flung down (typically `Navigator.pop`).
  final VoidCallback? onDismiss;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final bottom = edge == DrawkitSheetEdge.bottom;

    final panel = DrawkitSurface(
      builder: (size, options) {
        final frame = roughRoundedRect(
          3,
          3,
          size.width - 6,
          size.height - 6,
          12,
          options,
        );
        return [
          DrawkitLayer(frame, drawkitFillPaint(resolved.paperColor)),
          DrawkitLayer(frame, drawkitStroke(resolved)),
          if (bottom)
            DrawkitLayer(
              roughLine(
                size.width / 2 - 18,
                12,
                size.width / 2 + 18,
                12,
                options,
              ),
              drawkitStroke(resolved, fallbackWidth: 1.5),
            ),
        ];
      },
      style: resolved,
      seed: seed,
      animate: animate,
      child: Padding(
        padding: bottom ? padding.add(const EdgeInsets.only(top: 8)) : padding,
        child: child,
      ),
    );

    final trimmed = MediaQuery.removePadding(
      context: context,
      removeTop: bottom,
      child: panel,
    );

    return Align(
      alignment: bottom
          ? Alignment.bottomCenter
          : (rtl ? Alignment.centerLeft : Alignment.centerRight),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: bottom
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.sizeOf(context).height * maxHeightFactor,
                  ),
                  child: Stack(
                    children: [
                      trimmed,
                      if (onDismiss != null)
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          end: 0,
                          height: 26,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragEnd: (details) {
                              if ((details.primaryVelocity ?? 0) > 250) {
                                onDismiss!();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                )
              : trimmed,
        ),
      ),
    );
  }
}

/// Opens [child] (usually a [DrawkitSheet]) as a modal panel over a soft scrim.
///
/// [edge] picks the corner it slides from — [DrawkitSheetEdge.bottom] for the
/// classic sheet, [DrawkitSheetEdge.end] for a side drawer (direction-aware:
/// right in LTR, left in RTL). The future completes with whatever the sheet
/// pops with; the grab handle calls [Navigator.maybePop] on a downward fling.
Future<T?> showDrawkitSheet<T extends Object?>({
  required BuildContext context,
  required Widget child,
  DrawkitSheetEdge edge = DrawkitSheetEdge.bottom,
  double width = 420,
  bool showHandle = true,
  bool barrierDismissible = true,
  Color? scrimColor,
  DrawkitStyle? style,
  int? seed,
  bool animate = true,
}) {
  final reduceMotion = drawkitReduceMotion(context);
  final motion = animate && !reduceMotion;
  final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
  final begin = switch (edge) {
    DrawkitSheetEdge.bottom => const Offset(0, 1),
    DrawkitSheetEdge.end => Offset(rtl ? -1 : 1, 0),
  };
  final draggable = showHandle && edge == DrawkitSheetEdge.bottom;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'drawkit sheet',
    barrierColor:
        scrimColor ?? DrawkitPalette.light.ink.withValues(alpha: 0.30),
    transitionDuration: motion
        ? const Duration(milliseconds: 240)
        : Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => DrawkitSheet(
      edge: edge,
      width: width,
      onDismiss: draggable ? () => Navigator.of(context).maybePop() : null,
      style: style,
      seed: seed,
      animate: animate,
      child: child,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (!motion) return child;
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
  );
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

enum DrawkitSheetEdge { bottom, end }

/// The sketch panel behind [showDrawkitSheet]: paper fill, pen frame, and —
/// when it slides up from the bottom — a grab handle that follows the finger
/// and dismisses the route on a downward fling (hook [onDismiss] to close).
class DrawkitSheet extends StatefulWidget {
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
  State<DrawkitSheet> createState() => _DrawkitSheetState();
}

class _DrawkitSheetState extends State<DrawkitSheet> {
  double _dragOffset = 0;

  void _settle() => setState(() => _dragOffset = 0);

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final bottom = widget.edge == DrawkitSheetEdge.bottom;
    final viewInsets = MediaQuery.viewInsetsOf(context);

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
      seed: widget.seed,
      animate: widget.animate,
      child: Padding(
        padding: bottom
            ? widget.padding.add(const EdgeInsets.only(top: 8))
            : widget.padding,
        child: widget.child,
      ),
    );

    final trimmed = MediaQuery.removePadding(
      context: context,
      removeTop: bottom,
      child: panel,
    );

    Widget constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.width),
      child: bottom
          ? ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.sizeOf(context).height * widget.maxHeightFactor,
              ),
              child: Stack(
                children: [
                  trimmed,
                  if (widget.onDismiss != null)
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      height: 32,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) => setState(() {
                          _dragOffset = math.max(
                            0,
                            _dragOffset + details.delta.dy,
                          );
                        }),
                        onVerticalDragEnd: (details) {
                          final flung = (details.primaryVelocity ?? 0) > 250;
                          final dragged =
                              _dragOffset >
                              MediaQuery.sizeOf(context).height * 0.3;
                          if (flung || dragged) {
                            widget.onDismiss!();
                            return;
                          }
                          _settle();
                        },
                        onVerticalDragCancel: _settle,
                      ),
                    ),
                ],
              ),
            )
          : trimmed,
    );

    // The Transform stays in the tree even at rest: swapping the shape when
    // the drag starts would dispose the live recognizer mid-gesture.
    if (bottom) {
      constrained = Transform.translate(
        offset: Offset(0, _dragOffset),
        child: constrained,
      );
    }

    return Align(
      alignment: bottom
          ? Alignment.bottomCenter
          : (rtl ? Alignment.centerLeft : Alignment.centerRight),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: constrained,
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
  String? barrierLabel,
  bool enableDrag = true,
  bool isScrollControlled = false,
  double maxHeightFactor = 0.8,
  Color? scrimColor,
  DrawkitStyle? style,
  int? seed,
  bool animate = true,
  bool requestFocus = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Duration? transitionDuration,
}) {
  final reduceMotion = drawkitReduceMotion(context);
  final motion = animate && !reduceMotion;
  final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
  final begin = switch (edge) {
    DrawkitSheetEdge.bottom => const Offset(0, 1),
    DrawkitSheetEdge.end => Offset(rtl ? -1 : 1, 0),
  };
  final draggable = showHandle && enableDrag && edge == DrawkitSheetEdge.bottom;
  final resolved = style ?? DrawkitTheme.of(context);
  final duration = transitionDuration ?? const Duration(milliseconds: 240);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'drawkit sheet',
    barrierColor: scrimColor ?? resolved.palette.ink.withValues(alpha: 0.30),
    transitionDuration: motion ? duration : Duration.zero,
    requestFocus: requestFocus,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    pageBuilder: (context, animation, secondaryAnimation) => DrawkitTheme(
      data: resolved,
      child: DefaultTextStyle(
        style: drawkitRouteTextStyle(resolved),
        child: DrawkitSheet(
          edge: edge,
          width: width,
          maxHeightFactor: isScrollControlled ? 1 : maxHeightFactor,
          onDismiss: draggable ? () => Navigator.of(context).maybePop() : null,
          seed: seed,
          animate: animate,
          child: child,
        ),
      ),
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

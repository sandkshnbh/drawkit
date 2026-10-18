import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/prng.dart';
import '../engine/rough.dart';

/// Marker geometry in the list's left padding, the Dart side of
/// `.drawably-list { padding-left: 24px }` and the marker constants.
const double _markerLeft = -18;
const double _markerW = 10;

enum DrawkitListMarker { dash, check }

/// A sketch-marked list: each item carries its own pen stroke (seed + index,
/// like the JS attacher's per-`li` sketches) drawn in the 24px gutter.
///
/// Markers centre on the item's first line box, measured from the inherited
/// text style and the system text scale; pass [lineHeight] to pin a box
/// instead of measuring.
class DrawkitList extends StatefulWidget {
  const DrawkitList({
    required this.children,
    this.marker = DrawkitListMarker.dash,
    this.style,
    this.seed,
    this.animate = true,
    this.lineHeight,
    super.key,
  });

  final List<Widget> children;
  final DrawkitListMarker marker;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  /// Pins the marker's line box; measured from the text when null.
  final double? lineHeight;

  @override
  State<DrawkitList> createState() => _DrawkitListState();
}

class _DrawkitListState extends State<DrawkitList> {
  /// Resolved once so every item is stable across rebuilds (the JS seed is
  /// also fixed at attach time).
  late int _seed = widget.seed ?? randomSeed();

  @override
  void didUpdateWidget(DrawkitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final baseStyle = DefaultTextStyle.of(context).style;
    final scaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final lineBox =
        widget.lineHeight ??
        scaler.scale(baseStyle.fontSize ?? 14) * (baseStyle.height ?? 1.4);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            DrawkitSurface(
              builder: (size, options) {
                // Mirrored gutter: -18..-8 in LTR, w+8..w+18 in RTL.
                final markerX = rtl
                    ? size.width - _markerLeft - _markerW
                    : _markerLeft;
                final centreY = math.min(size.height, lineBox) / 2;
                return [
                  DrawkitLayer(
                    widget.marker == DrawkitListMarker.check
                        ? roughCheckmark(
                            markerX,
                            centreY - _markerW / 2,
                            _markerW,
                            _markerW,
                            options,
                          )
                        : roughLine(
                            markerX,
                            centreY,
                            markerX + _markerW,
                            centreY,
                            options,
                          ),
                    drawkitStroke(style),
                  ),
                ];
              },
              style: style,
              seed: _seed + i,
              animate: widget.animate,
              resketchOnPointer: false,
              child: DefaultTextStyle(
                style: DefaultTextStyle.of(context).style.copyWith(height: 1.4),
                child: widget.children[i],
              ),
            ),
        ],
      ),
    );
  }
}

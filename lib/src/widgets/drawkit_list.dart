import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/prng.dart';
import '../engine/rough.dart';

/// Marker geometry in the list's left padding, the Dart side of
/// `.drawably-list { padding-left: 24px }` and the marker constants.
const double _markerLeft = -18;
const double _markerW = 10;
const double _markerLine = 22;

enum DrawkitListMarker { dash, check }

/// A sketch-marked list: each item carries its own pen stroke (seed + index,
/// like the JS attacher's per-`li` sketches) drawn in the 24px gutter.
class DrawkitList extends StatefulWidget {
  const DrawkitList({
    required this.children,
    this.marker = DrawkitListMarker.dash,
    this.style,
    this.seed,
    this.animate = true,
    this.lineHeight = _markerLine,
    super.key,
  });

  final List<Widget> children;
  final DrawkitListMarker marker;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final double lineHeight;

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
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            DrawkitSurface(
              builder: (size, options) => [
                DrawkitLayer(
                  widget.marker == DrawkitListMarker.check
                      ? roughCheckmark(
                          _markerLeft,
                          widget.lineHeight / 2 - _markerW / 2,
                          _markerW,
                          _markerW,
                          options,
                        )
                      : roughLine(
                          _markerLeft,
                          widget.lineHeight / 2,
                          _markerLeft + _markerW,
                          widget.lineHeight / 2,
                          options,
                        ),
                  drawkitStroke(style),
                ),
              ],
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

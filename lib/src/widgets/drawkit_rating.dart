import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/intents.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// Whole-star rating: tap a star to set it, tap the current value to clear
/// back one. Read-only when [onChanged] is null.
///
/// One [DrawkitSurface] paints every star, so the boil steps them together
/// and a tap redraws the whole row with a fresh seed. The row is one tab stop:
/// the arrow keys move the rating (following the reading direction) and a
/// rough focus ring marks it while focused.
class DrawkitRating extends StatefulWidget {
  const DrawkitRating({
    required this.value,
    this.count = 5,
    this.onChanged,
    this.starSize = 26,
    this.spacing = 4,
    this.semanticLabel = 'rating',
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(value >= 0 && value <= count, 'value must sit within count'),
       assert(count > 0, 'a rating draws at least one star');

  final int value;
  final int count;

  /// Reports the new star count; null makes the row read-only.
  final ValueChanged<int>? onChanged;

  final double starSize;
  final double spacing;
  final String semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<DrawkitRating> createState() => _DrawkitRatingState();
}

class _DrawkitRatingState extends State<DrawkitRating> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _attachFocusNode();
  }

  void _attachFocusNode() {
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(DrawkitRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _attachFocusNode();
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  List<Offset> _star(int index, double width, bool rtl) {
    final slot = index * (widget.starSize + widget.spacing);
    final cx = rtl
        ? width - slot - widget.starSize / 2
        : slot + widget.starSize / 2;
    final cy = widget.starSize / 2;
    final outer = widget.starSize / 2 - 3;
    final inner = outer * 0.46;
    return [
      for (var k = 0; k < 10; k++)
        Offset(
          cx +
              math.cos(-math.pi / 2 + k * math.pi / 5) *
                  (k.isEven ? outer : inner),
          cy +
              math.sin(-math.pi / 2 + k * math.pi / 5) *
                  (k.isEven ? outer : inner),
        ),
    ];
  }

  void _set(int next) => widget.onChanged?.call(next.clamp(0, widget.count));

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final enabled = widget.onChanged != null;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final width = math.max(
      0.0,
      widget.count * (widget.starSize + widget.spacing) - widget.spacing,
    );
    final fill = Paint()
      ..color = resolved.effectiveStroke
      ..style = PaintingStyle.fill;
    final horizontal = rtl ? -1 : 1;

    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: '${widget.value} of ${widget.count} stars',
      increasedValue: widget.value < widget.count
          ? '${widget.value + 1} of ${widget.count} stars'
          : null,
      decreasedValue: widget.value > 0
          ? '${widget.value - 1} of ${widget.count} stars'
          : null,
      onIncrease: enabled && widget.value < widget.count
          ? () => _set(widget.value + 1)
          : null,
      onDecrease: enabled && widget.value > 0
          ? () => _set(widget.value - 1)
          : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          enabled: enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: {
            SingleActivator(LogicalKeyboardKey.arrowRight): DrawkitMoveIntent(
              horizontal,
            ),
            SingleActivator(LogicalKeyboardKey.arrowLeft): DrawkitMoveIntent(
              -horizontal,
            ),
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                const DrawkitMoveIntent(1),
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                const DrawkitMoveIntent(-1),
            const SingleActivator(LogicalKeyboardKey.space):
                const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.enter):
                const ActivateIntent(),
          },
          actions: {
            DrawkitMoveIntent: CallbackAction<DrawkitMoveIntent>(
              onInvoke: (intent) {
                _set(widget.value + intent.delta);
                return null;
              },
            ),
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                _set(widget.value < widget.count ? widget.value + 1 : 0);
                return null;
              },
            ),
          },
          child: SizedBox(
            width: width,
            height: widget.starSize,
            child: DrawkitSurface(
              builder: (size, options) {
                final layers = <DrawkitLayer>[];
                for (var i = 0; i < widget.count; i++) {
                  final points = _star(i, size.width, rtl);
                  if (i < widget.value) {
                    layers.add(
                      DrawkitLayer(Path()..addPolygon(points, true), fill),
                    );
                  }
                  layers.add(
                    DrawkitLayer(
                      doubleStroke(points, options, close: true),
                      drawkitStroke(resolved, fallbackWidth: 1.5),
                    ),
                  );
                }
                if (_focused) {
                  layers.add(
                    drawkitFocusRingRect(
                      size: size,
                      radius: 6,
                      options: options,
                      style: resolved,
                    ),
                  );
                }
                return layers;
              },
              style: resolved,
              seed: widget.seed,
              animate: widget.animate,
              enabled: enabled,
              resketchOnPointer: true,
              child: Row(
                children: [
                  for (var i = 0; i < widget.count; i++)
                    SizedBox(
                      width:
                          widget.starSize +
                          (i == widget.count - 1 ? 0 : widget.spacing),
                      height: widget.starSize,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: enabled
                            ? () {
                                if (enabled) _focusNode.requestFocus();
                                widget.onChanged!(
                                  widget.value == i + 1 ? i : i + 1,
                                );
                              }
                            : null,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

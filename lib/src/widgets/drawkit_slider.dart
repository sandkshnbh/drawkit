import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/intents.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 10;
const double _thumbRadius = 8;

/// A sketched slider: thin track, bolder filled run, a paper-filled thumb.
///
/// Drag or tap anywhere on the track, or focus it and use the arrow keys —
/// step is one division when [divisions] is set, 5% of the range otherwise.
/// Home/End jump to the ends, PageUp/PageDown move five steps, and the
/// horizontal arrows follow the reading direction (in RTL, right decreases),
/// matching Flutter's own sliders. The fill grows from the leading edge, so
/// RTL fills right to left, and a tap maps to the value under the finger,
/// never the x coordinate.
class DrawkitSlider extends StatefulWidget {
  const DrawkitSlider({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    this.height = 40,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final double value;

  /// Null disables the slider (drawn at 45% like every disabled control).
  final ValueChanged<double>? onChanged;

  final double min;
  final double max;

  /// Snap points across the range; null is continuous.
  final int? divisions;

  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final double height;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<DrawkitSlider> createState() => _DrawkitSliderState();
}

class _DrawkitSliderState extends State<DrawkitSlider> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  bool get _enabled => widget.onChanged != null;

  double get _range => widget.max > widget.min ? widget.max - widget.min : 1.0;

  double get _step =>
      widget.divisions != null ? _range / widget.divisions! : _range / 20;

  double get _fraction =>
      ((widget.value - widget.min) / _range).clamp(0.0, 1.0);

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
  void didUpdateWidget(DrawkitSlider oldWidget) {
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

  double _snap(double raw) {
    var fraction = raw.clamp(0.0, 1.0);
    if (widget.divisions != null) {
      fraction = (fraction * widget.divisions!).round() / widget.divisions!;
    }
    return (widget.min + fraction * _range).clamp(widget.min, widget.max);
  }

  void _report(double next) {
    if (!_enabled) return;
    if ((next - widget.value).abs() < 1e-9) return;
    widget.onChanged!(next);
  }

  void _nudge(double delta) => _report(_snap(_fraction + delta / _range));

  void _setFromX(double x, double width, bool rtl) {
    final inner = width - 2 * _inset;
    if (inner <= 0) return;
    final fromStart = rtl ? width - x : x;
    _report(_snap((fromStart - _inset) / inner));
  }

  Color _resolvedInk(DrawkitStyle style) => style.ink ?? style.effectiveStroke;

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
    Color ink,
    bool rtl,
  ) {
    final cy = size.height / 2;
    final inner = size.width - 2 * _inset;
    final x = rtl
        ? size.width - _inset - inner * _fraction
        : _inset + inner * _fraction;
    final layers = <DrawkitLayer>[
      DrawkitLayer(
        roughLine(_inset, cy, size.width - _inset, cy, options),
        drawkitStroke(style, color: ink),
      ),
      if (_fraction > 0)
        DrawkitLayer(
          roughLine(rtl ? size.width - _inset : _inset, cy, x, cy, options),
          drawkitStroke(style, color: ink, fallbackWidth: 4),
        ),
      DrawkitLayer(
        roughCircle(x, cy, _thumbRadius, options),
        drawkitFillPaint(style.paperColor),
      ),
    ];
    final ringPaint = drawkitStroke(style, color: ink);
    if ((_hovered || _pressed) && _enabled) {
      ringPaint.strokeWidth = style.strokeWidth(2) * 1.4;
    }
    layers.add(
      DrawkitLayer(roughCircle(x, cy, _thumbRadius, options), ringPaint),
    );
    if (_focused) {
      layers.add(
        drawkitFocusRingRect(
          size: size,
          radius: 8,
          gapY: 0,
          color: ink,
          options: options,
          style: style,
        ),
      );
    }
    return layers;
  }

  String _pretty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = widget.style ?? DrawkitTheme.of(context);
    final ink = _resolvedInk(resolvedStyle);
    final style = resolvedStyle.copyWith(strokeColor: ink, fillColor: ink);
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final horizontal = rtl ? -1.0 : 1.0;

    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const DrawkitAdjustIntent(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const DrawkitAdjustIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): DrawkitAdjustIntent(
          horizontal,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): DrawkitAdjustIntent(
          -horizontal,
        ),
        const SingleActivator(LogicalKeyboardKey.home): const DrawkitEdgeIntent(
          false,
        ),
        const SingleActivator(LogicalKeyboardKey.end): const DrawkitEdgeIntent(
          true,
        ),
        const SingleActivator(LogicalKeyboardKey.pageUp):
            const DrawkitAdjustIntent(5),
        const SingleActivator(LogicalKeyboardKey.pageDown):
            const DrawkitAdjustIntent(-5),
      },
      child: FocusableActionDetector(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: _enabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          DrawkitAdjustIntent: CallbackAction<DrawkitAdjustIntent>(
            onInvoke: (intent) {
              _nudge(intent.delta * _step);
              return null;
            },
          ),
          DrawkitEdgeIntent: CallbackAction<DrawkitEdgeIntent>(
            onInvoke: (intent) {
              _report(intent.end ? widget.max : widget.min);
              return null;
            },
          ),
        },
        child: Semantics(
          slider: true,
          enabled: _enabled,
          label: widget.semanticLabel,
          value: _pretty(widget.value),
          increasedValue: _pretty(_snap(_fraction + _step / _range)),
          decreasedValue: _pretty(_snap(_fraction - _step / _range)),
          onIncrease: _enabled ? () => _nudge(_step) : null,
          onDecrease: _enabled ? () => _nudge(-_step) : null,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapDown: (details) => _setFromX(
                details.localPosition.dx,
                constraints.maxWidth,
                rtl,
              ),
              onHorizontalDragStart: (details) => _setFromX(
                details.localPosition.dx,
                constraints.maxWidth,
                rtl,
              ),
              onHorizontalDragUpdate: (details) => _setFromX(
                details.localPosition.dx,
                constraints.maxWidth,
                rtl,
              ),
              child: DrawkitTapTarget(
                child: DrawkitSurface(
                  builder: (size, options) =>
                      _layers(size, options, style, ink, rtl),
                  style: style,
                  seed: widget.seed,
                  animate: widget.animate,
                  enabled: _enabled,
                  resketchOnPointer: true,
                  onHoverChanged: (v) => setState(() => _hovered = v),
                  onPressedChanged: (v) => setState(() => _pressed = v),
                  child: SizedBox(
                    width: double.infinity,
                    height: widget.height,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

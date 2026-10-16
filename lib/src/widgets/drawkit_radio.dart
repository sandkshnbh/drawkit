import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;

/// The 22x22 sketch radio. Siblings share a group value, the picked one shows
/// a dot that scales in from 0.5 over 160ms (`visibility` + `transform` in
/// the CSS — an unpicked radio hides the dot with no exit animation).
class DrawkitRadio<T> extends StatefulWidget {
  const DrawkitRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    super.key,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  bool get selected => value == groupValue;

  bool get enabled => onChanged != null;

  static const Size size = Size(22, 22);

  @override
  State<DrawkitRadio<T>> createState() => _DrawkitRadioState<T>();
}

class _DrawkitRadioState<T> extends State<DrawkitRadio<T>>
    with TickerProviderStateMixin {
  late final AnimationController _boil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _dot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    value: widget.selected ? 1 : 0,
  );
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _focused = false;
  bool _pressed = false;
  bool _reduceMotion = false;

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
  void didUpdateWidget(DrawkitRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (_reduceMotion) {
        _dot.value = widget.selected ? 1 : 0;
      } else {
        _dot.animateTo(
          widget.selected ? 1 : 0,
          duration: _dot.duration,
          curve: drawkitEase,
        );
      }
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) _focusNode.dispose();
      _attachFocusNode();
    }
  }

  @override
  void dispose() {
    _boil.dispose();
    _dot.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _select() => widget.onChanged?.call(widget.value);

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
  ) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    final layers = <DrawkitLayer>[];
    final outlinePaint = drawkitStroke(style);
    if (_pressed && widget.enabled) {
      outlinePaint.strokeWidth = style.strokeWidth(2) * 1.4;
    }
    layers.add(
      DrawkitLayer(
        roughCircle(center.dx, center.dy, r - _inset, options),
        outlinePaint,
      ),
    );
    if (widget.selected) {
      final dot = roughCircle(
        center.dx,
        center.dy,
        math.min(size.width, size.height) * 0.18,
        options,
      );
      final dotInk = style.effectiveFill;
      Matrix4 dotScale() {
        final t = 0.5 + 0.5 * _dot.value;
        return Matrix4.identity()
          ..translateByDouble(center.dx, center.dy, 0, 1)
          ..scaleByDouble(t, t, 1, 1)
          ..translateByDouble(-center.dx, -center.dy, 0, 1);
      }

      // the CSS dot paints fill and stroke on one path; two layers here
      layers.add(DrawkitLayer(dot, drawkitFillPaint(dotInk), matrix: dotScale));
      layers.add(
        DrawkitLayer(
          dot,
          drawkitStroke(style, color: dotInk),
          matrix: dotScale,
        ),
      );
    }
    if (_focused) {
      layers.add(
        DrawkitLayer(
          roughCircle(center.dx, center.dy, r + 1, options),
          drawkitStroke(style, fallbackWidth: 1.5),
        ),
      );
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    _reduceMotion = drawkitReduceMotion(context);

    final boil = widget.animate && style.boil > 0 && !_reduceMotion;
    if (boil && !_boil.isAnimating) _boil.repeat();
    if (!boil && _boil.value != 0) {
      _boil.stop();
      _boil.value = 0;
    }

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            _select();
            return null;
          },
        ),
      },
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Semantics(
        checked: widget.selected,
        enabled: widget.enabled,
        inMutuallyExclusiveGroup: true,
        label: widget.semanticLabel,
        onTap: widget.enabled ? _select : null,
        child: DrawkitSurface(
          builder: (size, options) => _layers(size, options, style),
          style: style,
          seed: widget.seed,
          animate: widget.animate,
          enabled: widget.enabled,
          resketchOnPointer: true,
          boilClock: _boil,
          accent: _dot,
          size: DrawkitRadio.size,
          onTap: widget.enabled ? _select : null,
          onPressedChanged: (v) => setState(() => _pressed = v),
        ),
      ),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;

/// The 44x24 sketch toggle: pill outline plus a blob knob that travels the
/// width-minus-height on a 160ms ease (the CSS `translateX(20px)` at the
/// default size, scaled to whatever size the widget is given).
class DrawkitToggle extends StatefulWidget {
  const DrawkitToggle({
    required this.value,
    required this.onChanged,
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  bool get enabled => onChanged != null;

  static const Size size = Size(44, 24);

  @override
  State<DrawkitToggle> createState() => _DrawkitToggleState();
}

class _DrawkitToggleState extends State<DrawkitToggle>
    with TickerProviderStateMixin {
  late final AnimationController _boil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _knob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    value: widget.value ? 1 : 0,
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
  void didUpdateWidget(DrawkitToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (_reduceMotion) {
        _knob.value = widget.value ? 1 : 0;
      } else {
        _knob.animateTo(
          widget.value ? 1 : 0,
          duration: _knob.duration,
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
    _knob.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
    TextDirection direction,
  ) {
    final w = size.width;
    final h = size.height;
    final rtl = direction == TextDirection.rtl;
    final r = (h - 2 * _inset) / 2;
    final outline = roughRoundedRect(
      _inset,
      _inset,
      w - 2 * _inset,
      h - 2 * _inset,
      r,
      options,
    );
    final layers = <DrawkitLayer>[];
    final outlinePaint = drawkitStroke(style);
    if (_pressed && widget.enabled) {
      outlinePaint.strokeWidth = style.strokeWidth(2) * 1.4;
    }
    layers.add(DrawkitLayer(outline, outlinePaint));

    final knob = roughCircle(h / 2, h / 2, h / 2 - _inset - 3, options);
    final knobInk = style.effectiveFill;
    final travel = w - h;
    // RTL rests the knob on the right and travels left when on.
    Matrix4 knobTravel() => Matrix4.identity()
      ..translateByDouble(
        travel * (rtl ? 1 - _knob.value : _knob.value),
        0,
        0,
        1,
      );

    // blob knob: fill and stroke in the one ink, 4px like `.drawably-blob`
    layers.add(
      DrawkitLayer(knob, drawkitFillPaint(knobInk), matrix: knobTravel),
    );
    layers.add(
      DrawkitLayer(
        knob,
        drawkitStroke(style, color: knobInk, fallbackWidth: 4),
        matrix: knobTravel,
      ),
    );

    if (_focused) {
      layers.add(
        drawkitFocusRingRect(
          size: Size(w, h),
          radius: 12,
          options: options,
          style: style,
        ),
      );
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
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
            _toggle();
            return null;
          },
        ),
      },
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: widget.enabled ? _toggle : null,
        child: Semantics(
          checked: widget.value,
          enabled: widget.enabled,
          label: widget.semanticLabel,
          onTap: widget.enabled ? _toggle : null,
          child: DrawkitTapTarget(
            child: DrawkitSurface(
              builder: (size, options) =>
                  _layers(size, options, style, direction),
              style: style,
              seed: widget.seed,
              animate: widget.animate,
              enabled: widget.enabled,
              resketchOnPointer: true,
              boilClock: _boil,
              accent: _knob,
              size: DrawkitToggle.size,
              onPressedChanged: (v) => setState(() => _pressed = v),
            ),
          ),
        ),
      ),
    );
  }
}

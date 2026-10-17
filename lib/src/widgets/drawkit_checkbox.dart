import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;

/// The 22x22 sketch box: outline + check + focus layers, a fresh pen stroke
/// on hover/down. The check draws on with a 240ms `stroke-dashoffset`
/// transition (trimmed path) and boils with the outline on one clock.
class DrawkitCheckbox extends StatefulWidget {
  const DrawkitCheckbox({
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

  static const Size size = Size(22, 22);

  @override
  State<DrawkitCheckbox> createState() => _DrawkitCheckboxState();
}

class _DrawkitCheckboxState extends State<DrawkitCheckbox>
    with TickerProviderStateMixin {
  late final AnimationController _boil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _check = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
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
  void didUpdateWidget(DrawkitCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (_reduceMotion) {
        _check.value = widget.value ? 1 : 0;
      } else {
        _check.animateTo(
          widget.value ? 1 : 0,
          duration: _check.duration,
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
    _check.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
  ) {
    final w = size.width;
    final h = size.height;
    final outline = roughRoundedRect(
      _inset,
      _inset,
      w - 2 * _inset,
      h - 2 * _inset,
      5,
      options,
    );
    final layers = <DrawkitLayer>[];
    final outlinePaint = drawkitStroke(style);
    if (_pressed && widget.enabled) {
      outlinePaint.strokeWidth = style.strokeWidth(2) * 1.4;
    }
    layers.add(DrawkitLayer(outline, outlinePaint));
    layers.add(
      DrawkitLayer(
        roughCheckmark(w * 0.24, h * 0.2, w * 0.52, h * 0.5, options),
        drawkitStroke(style),
        trimTo: _check,
      ),
    );
    if (_focused) {
      layers.add(
        drawkitFocusRingRect(
          size: Size(w, h),
          radius: 7,
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
              builder: (size, options) => _layers(size, options, style),
              style: style,
              seed: widget.seed,
              animate: widget.animate,
              enabled: widget.enabled,
              resketchOnPointer: true,
              boilClock: _boil,
              accent: _check,
              size: DrawkitCheckbox.size,
              onPressedChanged: (v) => setState(() => _pressed = v),
            ),
          ),
        ),
      ),
    );
  }
}

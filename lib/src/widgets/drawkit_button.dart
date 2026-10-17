import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

enum DrawkitButtonVariant { outline, solid, scribble }

enum DrawkitButtonState { idle, loading, error, success }

const double _inset = 3;

/// Real widget out front, pen chrome behind. Pointer enter and press draw a
/// fresh sketch; hover lifts it a pixel, press sinks it and thickens the
/// outline; states recolour the ink (error/success) or slow the boil to
/// 450ms (loading). Everything mirrors `.drawably-button` in the CSS.
class DrawkitButton extends StatefulWidget {
  const DrawkitButton({
    required this.child,
    this.onPressed,
    this.variant = DrawkitButtonVariant.outline,
    this.state = DrawkitButtonState.idle,
    this.tone = DrawkitTone.accent,
    this.style,
    this.seed,
    this.animate = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final DrawkitButtonVariant variant;
  final DrawkitButtonState state;
  final DrawkitTone tone;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final EdgeInsetsGeometry padding;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  bool get enabled => onPressed != null && state != DrawkitButtonState.loading;

  @override
  State<DrawkitButton> createState() => _DrawkitButtonState();
}

class _DrawkitButtonState extends State<DrawkitButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

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
  void didUpdateWidget(DrawkitButton oldWidget) {
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

  Color _resolvedInk(DrawkitStyle style) =>
      switch ((widget.state, widget.tone)) {
        (DrawkitButtonState.error, _) => style.palette.error,
        (DrawkitButtonState.success, _) => style.palette.success,
        (_, DrawkitTone.accent) => style.ink ?? style.palette.pen,
        (_, DrawkitTone.neutral) => style.palette.neutral,
        (_, DrawkitTone.danger) => style.palette.error,
      };

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
    Color ink,
  ) {
    final w = size.width;
    final h = size.height;
    final layers = <DrawkitLayer>[];
    final outline = roughRoundedRect(
      _inset,
      _inset,
      w - 2 * _inset,
      h - 2 * _inset,
      8,
      options,
    );
    final hoverWash =
        _hovered &&
        widget.enabled &&
        widget.variant != DrawkitButtonVariant.solid;

    if (widget.variant == DrawkitButtonVariant.solid) {
      // the blob paints fill and stroke in one ink, so draw the path twice
      layers.add(DrawkitLayer(outline, drawkitFillPaint(ink)));
      layers.add(
        DrawkitLayer(
          outline,
          drawkitStroke(style, color: ink, fallbackWidth: 4),
        ),
      );
    }
    if (widget.variant == DrawkitButtonVariant.scribble) {
      layers.add(
        DrawkitLayer(
          scribbleFill(
            _inset + 2,
            _inset + 2,
            w - 2 * _inset - 4,
            h - 2 * _inset - 4,
            options,
          ),
          drawkitStroke(style, color: ink, fallbackWidth: 1.5),
        ),
      );
    }
    if (hoverWash) {
      layers.add(
        DrawkitLayer(outline, drawkitFillPaint(ink.withValues(alpha: 0.10))),
      );
    }
    final outlinePaint = drawkitStroke(style, color: ink);
    if (_pressed && widget.enabled) {
      outlinePaint.strokeWidth = style.strokeWidth(2) * 1.4;
    }
    layers.add(DrawkitLayer(outline, outlinePaint));
    if (_focused) {
      layers.add(
        drawkitFocusRingRect(
          size: Size(w, h),
          radius: 10,
          color: ink,
          options: options,
          style: style,
        ),
      );
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = widget.style ?? DrawkitTheme.of(context);
    final ink = _resolvedInk(themeStyle);
    final style = themeStyle.copyWith(strokeColor: ink, fillColor: ink);
    final textColor = widget.variant == DrawkitButtonVariant.solid
        ? themeStyle.paperColor
        : drawkitReadableInk(ink, themeStyle.palette.paper);
    final reduceMotion = drawkitReduceMotion(context);
    final duration = widget.state == DrawkitButtonState.loading
        ? const Duration(milliseconds: 450)
        : const Duration(milliseconds: 1200);

    final offsetY = !widget.enabled
        ? 0.0
        : _pressed
        ? 1.0
        : _hovered && widget.state != DrawkitButtonState.loading
        ? -1.0
        : 0.0;
    final scale = _pressed && widget.enabled ? 0.98 : 1.0;

    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, offsetY, 0)
        ..scaleByDouble(scale, scale, 1, 1),
      child: Shortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.enter):
              const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.space):
              const ActivateIntent(),
        },
        child: FocusableActionDetector(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          mouseCursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            excludeFromSemantics: true,
            onTap: widget.enabled ? widget.onPressed : null,
            child: Semantics(
              button: true,
              enabled: widget.enabled,
              label: widget.semanticLabel,
              onTap: widget.enabled ? widget.onPressed : null,
              child: DrawkitTapTarget(
                child: DrawkitSurface(
                  builder: (size, options) =>
                      _layers(size, options, style, ink),
                  style: style,
                  seed: widget.seed,
                  animate: widget.animate,
                  enabled: widget.enabled,
                  resketchOnPointer: true,
                  duration: duration,
                  onHoverChanged: (v) => setState(() => _hovered = v),
                  onPressedChanged: (v) => setState(() => _pressed = v),
                  child: DefaultTextStyle(
                    style: DefaultTextStyle.of(context).style
                        .copyWith(color: textColor),
                    child: Padding(
                      padding: widget.padding,
                      child: Align(
                        alignment: AlignmentDirectional.center,
                        widthFactor: 1,
                        heightFactor: 1,
                        child: widget.child,
                      ),
                    ),
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

/// A square icon button: [DrawkitButton] with icon padding and a required
/// accessibility label (there is no text to announce).
class DrawkitIconButton extends StatelessWidget {
  const DrawkitIconButton({
    required this.child,
    required this.semanticLabel,
    this.onPressed,
    this.variant = DrawkitButtonVariant.outline,
    this.state = DrawkitButtonState.idle,
    this.tone = DrawkitTone.accent,
    this.size = 34,
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final DrawkitButtonVariant variant;
  final DrawkitButtonState state;
  final DrawkitTone tone;
  final double size;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => DrawkitButton(
    onPressed: onPressed,
    variant: variant,
    state: state,
    tone: tone,
    style: style,
    seed: seed,
    animate: animate,
    padding: EdgeInsets.zero,
    focusNode: focusNode,
    autofocus: autofocus,
    semanticLabel: semanticLabel,
    child: SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    ),
  );
}

/// The round sibling of [DrawkitButton]: a floating pen circle for the one
/// action that never scrolls away. Same lift, sink, hover wash, and focus
/// ring, drawn around a circle instead of a rounded rect.
class DrawkitFab extends StatefulWidget {
  const DrawkitFab({
    required this.child,
    this.onPressed,
    this.tone = DrawkitTone.accent,
    this.style,
    this.seed,
    this.animate = true,
    this.size = 56,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final DrawkitTone tone;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final double size;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  bool get enabled => onPressed != null;

  @override
  State<DrawkitFab> createState() => _DrawkitFabState();
}

class _DrawkitFabState extends State<DrawkitFab> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

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
  void didUpdateWidget(DrawkitFab oldWidget) {
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

  Color _resolvedInk(DrawkitStyle style) => switch (widget.tone) {
    DrawkitTone.accent => style.ink ?? style.palette.pen,
    DrawkitTone.neutral => style.palette.neutral,
    DrawkitTone.danger => style.palette.error,
  };

  List<DrawkitLayer> _layers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
    Color ink,
  ) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - _inset;
    final layers = <DrawkitLayer>[];
    if (_hovered && widget.enabled) {
      layers.add(
        DrawkitLayer(
          roughCircle(cx, cy, r, options),
          drawkitFillPaint(ink.withValues(alpha: 0.10)),
        ),
      );
    }
    final outlinePaint = drawkitStroke(style, color: ink);
    if (_pressed && widget.enabled) {
      outlinePaint.strokeWidth = style.strokeWidth(2) * 1.4;
    }
    layers.add(DrawkitLayer(roughCircle(cx, cy, r, options), outlinePaint));
    if (_focused) {
      layers.add(
        drawkitFocusRingCircle(
          center: Offset(cx, cy),
          radius: r,
          gap: 2,
          color: ink,
          options: options,
          style: style,
        ),
      );
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = widget.style ?? DrawkitTheme.of(context);
    final ink = _resolvedInk(themeStyle);
    final style = themeStyle.copyWith(strokeColor: ink, fillColor: ink);
    final reduceMotion = drawkitReduceMotion(context);

    final offsetY = !widget.enabled
        ? 0.0
        : _pressed
        ? 1.0
        : _hovered
        ? -1.0
        : 0.0;

    return AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, offsetY, 0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Shortcuts(
          shortcuts: {
            const SingleActivator(LogicalKeyboardKey.enter):
                const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.space):
                const ActivateIntent(),
          },
          child: FocusableActionDetector(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) {
                  widget.onPressed?.call();
                  return null;
                },
              ),
            },
            mouseCursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Semantics(
              button: true,
              enabled: widget.enabled,
              label: widget.semanticLabel,
              child: DrawkitSurface(
                builder: (size, options) => _layers(size, options, style, ink),
                style: style,
                seed: widget.seed,
                animate: widget.animate,
                enabled: widget.enabled,
                resketchOnPointer: true,
                onHoverChanged: (v) => setState(() => _hovered = v),
                onPressedChanged: (v) => setState(() => _pressed = v),
                onTap: widget.enabled ? widget.onPressed : null,
                child: DefaultTextStyle(
                  style: DefaultTextStyle.of(context).style
                      .copyWith(color: themeStyle.paperColor),
                  child: Center(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

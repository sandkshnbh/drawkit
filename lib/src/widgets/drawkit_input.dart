import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;

/// Single-line field: sketch outline behind a real [EditableText] (no
/// Material anywhere). The field body pads 8x12 like the CSS, text colour
/// inherits, and focus reveals the 1.5px ring — the same geometry as
/// `.drawably-inputbox`.
///
/// When [error] is non-null the outline (and focus ring) recolour to
/// error tone and the message below the field shows in the error
/// tone as a semantic live region, announced when it appears. [helper] is the
/// quiet counterpart; an error replaces it rather than stacking.
class DrawkitInput extends StatelessWidget {
  const DrawkitInput({
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.placeholder,
    this.error,
    this.helper,
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    this.minWidth = 120,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final String? placeholder;
  final String? error;
  final String? helper;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final double minWidth;

  @override
  Widget build(BuildContext context) => _DrawkitField(
    controller: controller,
    focusNode: focusNode,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    enabled: enabled,
    autofocus: autofocus,
    placeholder: placeholder,
    error: error,
    helper: helper,
    textStyle: textStyle,
    style: style,
    seed: seed,
    animate: animate,
    minWidth: minWidth,
    maxLines: 1,
    minLines: 1,
    multiline: false,
  );
}

/// Multi-line field: same chrome, an [EditableText] that grows with its
/// content (the CSS textarea resizes vertically; here [minLines] sets the
/// resting height and growth is unbounded). [error] and [helper] behave
/// exactly like on [DrawkitInput].
class DrawkitTextarea extends StatelessWidget {
  const DrawkitTextarea({
    this.controller,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.placeholder,
    this.error,
    this.helper,
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    this.minLines = 3,
    this.minWidth = 160,
    super.key,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final String? placeholder;
  final String? error;
  final String? helper;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final int minLines;
  final double minWidth;

  @override
  Widget build(BuildContext context) => _DrawkitField(
    controller: controller,
    focusNode: focusNode,
    onChanged: onChanged,
    enabled: enabled,
    autofocus: autofocus,
    placeholder: placeholder,
    error: error,
    helper: helper,
    textStyle: textStyle,
    style: style,
    seed: seed,
    animate: animate,
    minWidth: minWidth,
    maxLines: null,
    minLines: minLines,
    multiline: true,
  );
}

class _DrawkitField extends StatefulWidget {
  const _DrawkitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onSubmitted,
    required this.enabled,
    required this.autofocus,
    required this.placeholder,
    required this.error,
    required this.helper,
    required this.textStyle,
    required this.style,
    required this.seed,
    required this.animate,
    required this.minWidth,
    required this.maxLines,
    required this.minLines,
    required this.multiline,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final String? placeholder;
  final String? error;
  final String? helper;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final double minWidth;
  final int? maxLines;
  final int minLines;
  final bool multiline;

  @override
  State<_DrawkitField> createState() => _DrawkitFieldState();
}

class _DrawkitFieldState extends State<_DrawkitField> {
  late TextEditingController _controller;
  late bool _ownsController;
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _attachController();
    _attachFocusNode();
  }

  void _attachController() {
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _attachFocusNode() {
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focused = _focusNode.hasFocus;
    _focusNode.canRequestFocus = widget.enabled;
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  void _onTextChanged() => setState(() {});

  @override
  void didUpdateWidget(_DrawkitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      if (_ownsController) _controller.dispose();
      _attachController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      _attachFocusNode();
    }
    if (widget.enabled != oldWidget.enabled) {
      _focusNode.canRequestFocus = widget.enabled;
      if (!widget.enabled) _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final palette = style.palette;
    final textStyle = DefaultTextStyle.of(context).style
        .merge(TextStyle(color: palette.ink))
        .merge(widget.textStyle);
    final hint = widget.placeholder;
    final hasError = widget.error != null;
    final strokeColor = hasError ? palette.error : style.effectiveStroke;
    final message = widget.error ?? widget.helper;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth),
          child: DrawkitSurface(
            builder: (size, options) => [
              DrawkitLayer(
                roughRoundedRect(
                  _inset,
                  _inset,
                  size.width - 2 * _inset,
                  size.height - 2 * _inset,
                  6,
                  options,
                ),
                drawkitStroke(style, color: strokeColor),
              ),
              if (_focused)
                DrawkitLayer(
                  roughRoundedRect(
                    -1,
                    -1,
                    size.width + 2,
                    size.height + 2,
                    8,
                    options,
                  ),
                  drawkitStroke(style, color: strokeColor, fallbackWidth: 1.5),
                ),
            ],
            style: style,
            seed: widget.seed,
            animate: widget.animate,
            enabled: widget.enabled,
            resketchOnPointer: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                children: [
                  if (hint != null && _controller.text.isEmpty)
                    Semantics(
                      enabled: widget.enabled,
                      child: Text(
                        hint,
                        style: textStyle.copyWith(color: palette.inkMuted),
                      ),
                    ),
                  EditableText(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: textStyle,
                    cursorColor: strokeColor,
                    backgroundCursorColor: const Color(0x00000000),
                    cursorWidth: 1.5,
                    selectionColor: style.effectiveStroke.withValues(
                      alpha: 0.20,
                    ),
                    autofocus: widget.autofocus,
                    readOnly: !widget.enabled,
                    showCursor: widget.enabled,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    keyboardType: widget.multiline
                        ? TextInputType.multiline
                        : TextInputType.text,
                    textInputAction: widget.multiline
                        ? TextInputAction.newline
                        : TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 2, end: 2),
            child: hasError
                ? Semantics(
                    liveRegion: true,
                    child: Text(
                      widget.error!,
                      style: textStyle.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: palette.error,
                      ),
                    ),
                  )
                : Text(
                    message,
                    style: textStyle.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: palette.inkMuted,
                    ),
                  ),
          ),
      ],
    );
  }
}

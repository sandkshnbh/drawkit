import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;
const double _glyphCentre = 17;
const double _glyphRadius = 5;

/// A sketched search box: the pen-drawn magnifier sits in the leading gutter,
/// a small × appears once there is text to clear.
///
/// Same real [EditableText] contract as [DrawkitInput] — controller, focus,
/// desktop shortcuts — with the glyphs drawn by the same surface (one seed,
/// one boil). The × reports through [onChanged] with an empty string.
class DrawkitSearchField extends StatefulWidget {
  const DrawkitSearchField({
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.placeholder,
    this.clearLabel = 'clear',
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

  /// Announced by the clear control (and its tooltip text).
  final String clearLabel;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final double minWidth;

  @override
  State<DrawkitSearchField> createState() => _DrawkitSearchFieldState();
}

class _DrawkitSearchFieldState extends State<DrawkitSearchField> {
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
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void didUpdateWidget(DrawkitSearchField oldWidget) {
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
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final textStyle = DefaultTextStyle.of(context).style
        .merge(TextStyle(color: style.palette.ink))
        .merge(widget.textStyle);
    final hint = widget.placeholder;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final glyphX = rtl ? 0.0 : 1.0;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth),
      child: DrawkitSurface(
        builder: (size, options) {
          final cy = size.height / 2;
          final cx = glyphX == 0 ? size.width - _glyphCentre : _glyphCentre;
          final dir = glyphX == 0 ? -1.0 : 1.0;
          return [
            DrawkitLayer(
              roughRoundedRect(
                _inset,
                _inset,
                size.width - 2 * _inset,
                size.height - 2 * _inset,
                6,
                options,
              ),
              drawkitStroke(style),
            ),
            DrawkitLayer(
              roughCircle(cx, cy - 1, _glyphRadius, options),
              drawkitStroke(style, fallbackWidth: 1.5),
            ),
            DrawkitLayer(
              roughLine(
                cx + dir * (_glyphRadius - 1.8),
                cy - 1 + (_glyphRadius - 1.8),
                cx + dir * (_glyphRadius + 1.6),
                cy - 1 + (_glyphRadius + 1.6),
                options,
              ),
              drawkitStroke(style, fallbackWidth: 1.5),
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
                drawkitStroke(style, fallbackWidth: 1.5),
              ),
          ];
        },
        style: style,
        seed: widget.seed,
        animate: widget.animate,
        enabled: widget.enabled,
        resketchOnPointer: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 32,
            end: 6,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (hint != null && _controller.text.isEmpty)
                      Text(
                        hint,
                        style: textStyle.copyWith(
                          color: style.palette.inkMuted,
                        ),
                      ),
                    EditableText(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: textStyle,
                      cursorColor: style.effectiveStroke,
                      backgroundCursorColor: const Color(0x00000000),
                      cursorWidth: 1.5,
                      selectionColor: style.effectiveStroke.withValues(
                        alpha: 0.20,
                      ),
                      autofocus: widget.autofocus,
                      readOnly: !widget.enabled,
                      showCursor: widget.enabled,
                      maxLines: 1,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                    ),
                  ],
                ),
              ),
              if (widget.enabled)
                _DrawkitSearchClearButton(
                  label: widget.clearLabel,
                  onPressed: _controller.text.isEmpty ? null : _clear,
                  style: style,
                  seed: widget.seed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The drawn ✕ trailing the field: a full 48px target that Tab reaches and
/// Enter/Space activate, sitting invisible until there is text to clear.
class _DrawkitSearchClearButton extends StatefulWidget {
  const _DrawkitSearchClearButton({
    required this.label,
    required this.onPressed,
    required this.style,
    required this.seed,
  });

  final String label;
  final VoidCallback? onPressed;
  final DrawkitStyle style;
  final int? seed;

  @override
  State<_DrawkitSearchClearButton> createState() =>
      _DrawkitSearchClearButtonState();
}

class _DrawkitSearchClearButtonState extends State<_DrawkitSearchClearButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final visible = widget.onPressed != null;
    return SizedBox(
      width: 48,
      child: !visible
          ? null
          : FocusableActionDetector(
              enabled: true,
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              shortcuts: {
                const SingleActivator(LogicalKeyboardKey.space):
                    const ActivateIntent(),
                const SingleActivator(LogicalKeyboardKey.enter):
                    const ActivateIntent(),
              },
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (intent) {
                    widget.onPressed?.call();
                    return null;
                  },
                ),
              },
              mouseCursor: SystemMouseCursors.click,
              child: Semantics(
                button: true,
                label: widget.label,
                onTap: widget.onPressed,
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onPressed,
                    child: DrawkitTapTarget(
                      child: DrawkitSurface(
                        builder: (size, options) => [
                          DrawkitLayer(
                            roughLine(
                              2,
                              2,
                              size.width - 2,
                              size.height - 2,
                              options,
                            ),
                            drawkitStroke(widget.style, fallbackWidth: 1.5),
                          ),
                          DrawkitLayer(
                            roughLine(
                              size.width - 2,
                              2,
                              2,
                              size.height - 2,
                              options,
                            ),
                            drawkitStroke(widget.style, fallbackWidth: 1.5),
                          ),
                          if (_focused)
                            DrawkitLayer(
                              roughRoundedRect(
                                -3,
                                -3,
                                size.width + 6,
                                size.height + 6,
                                4,
                                options,
                              ),
                              drawkitStroke(widget.style, fallbackWidth: 1),
                            ),
                        ],
                        style: widget.style,
                        seed: widget.seed,
                        animate: false,
                        size: const Size(13, 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

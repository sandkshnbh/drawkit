import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;
const double _chevronW = 12;
const double _chevronH = 6;
const double _chevronRight = 12;
const double _chevronRoughness = 0.4;
const double _menuGap = 2;
const double _menuMaxHeight = 280;

class DrawkitSelectOption<T> {
  const DrawkitSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Sketch field plus chevron in the reserved right gutter, opening a real
/// overlay menu ([RawMenuAnchor]) with a sketched frame and check on the
/// chosen row — the Flutter stand-in for Chromium's `base-select` picker,
/// which is the one engine where the JS version can draw the popup too.
class DrawkitSelect<T> extends StatefulWidget {
  const DrawkitSelect({
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder = 'choose…',
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.minWidth = 160,
    super.key,
  });

  final List<DrawkitSelectOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String placeholder;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final double minWidth;

  bool get enabled => onChanged != null;

  @override
  State<DrawkitSelect<T>> createState() => _DrawkitSelectState<T>();
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);

  final int delta;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent(this.end);

  final bool end;
}

class _NoopIntent extends Intent {
  const _NoopIntent();
}

class _DrawkitSelectState<T> extends State<DrawkitSelect<T>> {
  final MenuController _menu = MenuController();
  final GlobalKey _fieldKey = GlobalKey();
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  List<FocusNode> _optionNodes = const [];
  bool _focused = false;

  /// Captured when the menu opens: reading the anchor's size during overlay
  /// layout is out of scope, so the rect is frozen at open time.
  Rect _anchorRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _attachFocusNode();
    _syncOptionNodes();
  }

  void _attachFocusNode() {
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void didUpdateWidget(DrawkitSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      _attachFocusNode();
    }
    if (widget.options.length != _optionNodes.length) _syncOptionNodes();
  }

  @override
  void dispose() {
    for (final node in _optionNodes) {
      node.dispose();
    }
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _syncOptionNodes() {
    for (final node in _optionNodes) {
      node.dispose();
    }
    _optionNodes = [
      for (var i = 0; i < widget.options.length; i++)
        FocusNode(skipTraversal: true),
    ];
  }

  void _focusOption(int index) {
    if (index < 0 || index >= _optionNodes.length) return;
    _optionNodes[index].requestFocus();
  }

  void _move(int delta) {
    final count = _optionNodes.length;
    if (count == 0) return;
    final current = _optionNodes.indexWhere((n) => n.hasFocus);
    final at = current < 0 ? (delta > 0 ? -1 : 0) : current;
    _focusOption((at + delta + count) % count);
  }

  void _edge(bool end) => _focusOption(end ? _optionNodes.length - 1 : 0);

  void _opened() {
    final selected = widget.options.indexWhere((o) => o.value == widget.value);
    final target = selected >= 0 ? selected : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _menu.isOpen) _focusOption(target);
    });
  }

  void _closed() {
    if (!_optionNodes.any((n) => n.hasFocus)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _toggleMenu() {
    if (!widget.enabled) return;
    if (_menu.isOpen) {
      _menu.close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _anchorRect = box.localToGlobal(Offset.zero) & box.size;
    }
    _menu.open();
  }

  void _pick(T value) {
    _menu.close();
    widget.onChanged?.call(value);
    _focusNode.requestFocus();
  }

  String get _label {
    for (final option in widget.options) {
      if (option.value == widget.value) return option.label;
    }
    return widget.placeholder;
  }

  List<DrawkitLayer> _fieldLayers(
    Size size,
    RoughOptions options,
    DrawkitStyle style,
    bool placeholder,
    TextDirection direction,
  ) {
    final w = size.width;
    final h = size.height;
    final layers = <DrawkitLayer>[
      DrawkitLayer(
        roughRoundedRect(
          _inset,
          _inset,
          w - 2 * _inset,
          h - 2 * _inset,
          6,
          options,
        ),
        drawkitStroke(style),
      ),
    ];
    // full roughness turns the chevron into noise, so it takes a fraction
    final chevronOptions = RoughOptions(
      seed: options.seed,
      roughness: options.roughness * _chevronRoughness,
      boil: options.boil,
    );
    final x = direction == TextDirection.rtl
        ? _chevronRight
        : w - _chevronRight - _chevronW;
    final y = h / 2 - _chevronH / 2;
    layers.add(
      DrawkitLayer(
        roughLine(x, y, x + _chevronW / 2, y + _chevronH, chevronOptions),
        drawkitStroke(
          style,
          color: placeholder ? style.palette.inkMuted : null,
        ),
      ),
    );
    layers.add(
      DrawkitLayer(
        roughLine(
          x + _chevronW / 2,
          y + _chevronH,
          x + _chevronW,
          y,
          RoughOptions(
            seed: options.seed + 1,
            roughness: chevronOptions.roughness,
            boil: options.boil,
          ),
        ),
        drawkitStroke(
          style,
          color: placeholder ? style.palette.inkMuted : null,
        ),
      ),
    );
    if (_focused) {
      layers.add(
        drawkitFocusRingRect(
          size: Size(w, h),
          radius: 8,
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
    final palette = style.palette;
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final textStyle = DefaultTextStyle.of(context).style
        .merge(TextStyle(color: palette.ink))
        .merge(widget.textStyle);
    final isPlaceholder = _label == widget.placeholder;

    return RawMenuAnchor(
      controller: _menu,
      consumeOutsideTaps: true,
      childFocusNode: _focusNode,
      onOpen: _opened,
      onClose: _closed,
      overlayBuilder: (context, info) => TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (event) => _menu.close(),
        child: CustomSingleChildLayout(
          delegate: _MenuPositionDelegate(
            anchorRect: _anchorRect,
            textDirection: Directionality.maybeOf(context) ?? direction,
          ),
          child: _menuPanel(context, style, textStyle),
        ),
      ),
      builder: (context, controller, child) => FocusableActionDetector(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
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
              _toggleMenu();
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
          onTap: _toggleMenu,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _toggleMenu,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: widget.minWidth),
              child: DrawkitSurface(
                key: _fieldKey,
                builder: (size, options) => _fieldLayers(
                  size,
                  options,
                  style,
                  isPlaceholder,
                  direction,
                ),
                style: style,
                seed: widget.seed,
                animate: widget.animate,
                enabled: widget.enabled,
                resketchOnPointer: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 12,
                    end: 34,
                    top: 8,
                    bottom: 8,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        _label,
                        style: textStyle.copyWith(
                          color: isPlaceholder ? palette.inkMuted : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _menuPanel(
    BuildContext context,
    DrawkitStyle style,
    TextStyle textStyle,
  ) {
    final panelStyle = style.copyWith(width: 2);
    return DrawkitSurface(
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
          drawkitStroke(panelStyle),
        ),
      ],
      style: panelStyle,
      seed: widget.seed,
      animate: widget.animate,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _menuMaxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: SingleChildScrollView(
            child: Shortcuts(
              shortcuts: {
                const SingleActivator(LogicalKeyboardKey.arrowDown):
                    const _MoveIntent(1),
                const SingleActivator(LogicalKeyboardKey.arrowUp):
                    const _MoveIntent(-1),
                const SingleActivator(LogicalKeyboardKey.arrowLeft):
                    const _NoopIntent(),
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    const _NoopIntent(),
                const SingleActivator(LogicalKeyboardKey.home):
                    const _EdgeIntent(false),
                const SingleActivator(LogicalKeyboardKey.end):
                    const _EdgeIntent(true),
              },
              child: Actions(
                actions: {
                  _MoveIntent: CallbackAction<_MoveIntent>(
                    onInvoke: (intent) {
                      _move(intent.delta);
                      return null;
                    },
                  ),
                  _EdgeIntent: CallbackAction<_EdgeIntent>(
                    onInvoke: (intent) {
                      _edge(intent.end);
                      return null;
                    },
                  ),
                  _NoopIntent: CallbackAction<_NoopIntent>(
                    onInvoke: (intent) => null,
                  ),
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.options.length; i++)
                      _SelectRow(
                        label: widget.options[i].label,
                        selected: widget.options[i].value == widget.value,
                        textStyle: textStyle,
                        ink: style.effectiveStroke,
                        seed: widget.seed,
                        focusNode: _optionNodes[i],
                        onPick: () => _pick(widget.options[i].value),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Positions the panel under the anchor, same width, clamped to the viewport.
/// The panel's inline-start edge tracks the anchor's: left in LTR, right in RTL.
class _MenuPositionDelegate extends SingleChildLayoutDelegate {
  _MenuPositionDelegate({
    required this.anchorRect,
    required this.textDirection,
  });

  final Rect anchorRect;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: anchorRect.width,
        maxWidth: anchorRect.width,
        maxHeight: _menuMaxHeight + 12,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = anchorRect.bottom + _menuGap;
    final fitsBelow = below + childSize.height <= size.height;
    final y = fitsBelow ? below : anchorRect.top - _menuGap - childSize.height;
    final rawX = textDirection == TextDirection.rtl
        ? anchorRect.right - childSize.width
        : anchorRect.left;
    final x = rawX.clamp(
      0.0,
      (size.width - childSize.width).clamp(0.0, double.infinity),
    );
    return Offset(
      x,
      y.clamp(
        0.0,
        (size.height - childSize.height).clamp(0.0, double.infinity),
      ),
    );
  }

  @override
  bool shouldRelayout(_MenuPositionDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      textDirection != oldDelegate.textDirection;
}

class _SelectRow extends StatefulWidget {
  const _SelectRow({
    required this.label,
    required this.selected,
    required this.textStyle,
    required this.ink,
    required this.seed,
    required this.onPick,
    this.focusNode,
  });

  final String label;
  final bool selected;
  final TextStyle textStyle;
  final Color ink;
  final int? seed;
  final VoidCallback onPick;
  final FocusNode? focusNode;

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final wash = (_hovered || _focused) && !widget.selected;
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPick();
            return null;
          },
        ),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        selected: widget.selected,
        onTap: widget.onPick,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onPick,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: wash ? widget.ink.withValues(alpha: 0.10) : null,
              ),
              child: DrawkitTapTarget(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: widget.selected
                            ? CustomPaint(
                                painter: _CheckPainter(
                                  seed: widget.seed ?? 1,
                                  ink: widget.ink,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: widget.textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

/// The picker's chosen-mark: a 14px box with the same 2px-inset check the
/// CSS mask builds, so it lands at the checkbox's ~11px check size.
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.seed, required this.ink});

  final int seed;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      roughCheckmark(
        2,
        2,
        size.width - 4,
        size.height - 4,
        RoughOptions(seed: seed),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      seed != oldDelegate.seed || ink != oldDelegate.ink;
}

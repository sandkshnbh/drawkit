import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart';

const double _panelMaxHeight = 320;
const double _panelGap = 6;

/// One row of a [DrawkitMenu]. Use [DrawkitMenuItem.divider] for a rule.
class DrawkitMenuItem {
  const DrawkitMenuItem({
    required this.label,
    this.onSelected,
    this.enabled = true,
    this.checked = false,
    this.hint,
  }) : divider = false;

  const DrawkitMenuItem.divider()
    : label = '',
      onSelected = null,
      enabled = false,
      checked = false,
      hint = null,
      divider = true;

  final String label;
  final VoidCallback? onSelected;
  final bool enabled;
  final bool checked;

  /// Trailing shortcut label, e.g. `⌘ K`.
  final String? hint;
  final bool divider;

  bool get active => enabled && onSelected != null;
}

/// A generic floating panel anchored under [trigger]: tap or activate the
/// trigger to toggle it, taps outside fold it away ([RawMenuAnchor]'s
/// behaviour).
///
/// Give the trigger no gesture of its own — the popover owns its taps — or
/// blank it with [DrawkitMenu], which wires a whole button.
class DrawkitPopover extends StatefulWidget {
  const DrawkitPopover({
    required this.trigger,
    required this.child,
    this.width,
    this.gap = _panelGap,
    this.padding = const EdgeInsets.all(12),
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    super.key,
  });

  final Widget trigger;
  final Widget child;

  /// Fixed panel width; null matches the trigger's width (min 180).
  final double? width;
  final double gap;
  final EdgeInsetsGeometry padding;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<DrawkitPopover> createState() => _DrawkitPopoverState();
}

class _DrawkitPopoverState extends State<DrawkitPopover> {
  final MenuController _menu = MenuController();
  final GlobalKey _anchorKey = GlobalKey();
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  Rect _anchorRect = Rect.zero;

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
  void didUpdateWidget(DrawkitPopover oldWidget) {
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

  void _toggle() {
    if (_menu.isOpen) {
      _menu.close();
    } else {
      final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _anchorRect = box.localToGlobal(Offset.zero) & box.size;
      }
      _menu.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    return RawMenuAnchor(
      controller: _menu,
      consumeOutsideTaps: true,
      childFocusNode: _focusNode,
      overlayBuilder: (context, info) => TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (event) => _menu.close(),
        child: CustomSingleChildLayout(
          delegate: _PopoverPositionDelegate(
            anchorRect: _anchorRect,
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            width: widget.width,
            gap: widget.gap,
          ),
          child: _PopoverPanel(
            style: style,
            seed: widget.seed,
            animate: widget.animate,
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
      builder: (context, controller, child) => FocusableActionDetector(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.space):
              const ActivateIntent(),
          const SingleActivator(LogicalKeyboardKey.enter):
              const ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              _toggle();
              return null;
            },
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: GestureDetector(
            key: _anchorKey,
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: widget.trigger,
          ),
        ),
      ),
    );
  }
}

class _PopoverPanel extends StatelessWidget {
  const _PopoverPanel({
    required this.child,
    required this.style,
    required this.seed,
    required this.animate,
    required this.padding,
  });

  final Widget child;
  final DrawkitStyle style;
  final int? seed;
  final bool animate;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DrawkitSurface(
    builder: (size, options) => [
      DrawkitLayer(
        roughRoundedRect(3, 3, size.width - 6, size.height - 6, 8, options),
        drawkitFillPaint(style.paperColor),
      ),
      DrawkitLayer(
        roughRoundedRect(3, 3, size.width - 6, size.height - 6, 8, options),
        drawkitStroke(style),
      ),
    ],
    style: style,
    seed: seed,
    animate: animate,
    child: Padding(padding: padding, child: child),
  );
}

class _PopoverPositionDelegate extends SingleChildLayoutDelegate {
  _PopoverPositionDelegate({
    required this.anchorRect,
    required this.textDirection,
    required this.width,
    required this.gap,
  });

  final Rect anchorRect;
  final TextDirection textDirection;
  final double? width;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final w = width ?? anchorRect.width.clamp(180.0, 360.0);
    return BoxConstraints(minWidth: w, maxWidth: w, maxHeight: _panelMaxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = anchorRect.bottom + gap;
    final fitsBelow = below + childSize.height <= size.height;
    final y = fitsBelow ? below : anchorRect.top - gap - childSize.height;
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
  bool shouldRelayout(_PopoverPositionDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      textDirection != oldDelegate.textDirection ||
      width != oldDelegate.width ||
      gap != oldDelegate.gap;
}

/// A sketched button that drops a menu of [DrawkitMenuItem]s: hover wash,
/// check marks, hints, dividers — and disabled rows that never fire.
class DrawkitMenu extends StatefulWidget {
  const DrawkitMenu({
    required this.child,
    required this.items,
    this.semanticLabel,
    this.minWidth = 180,
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final Widget child;
  final List<DrawkitMenuItem> items;
  final String? semanticLabel;
  final double minWidth;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<DrawkitMenu> createState() => _DrawkitMenuState();
}

class _DrawkitMenuState extends State<DrawkitMenu> {
  final MenuController _menu = MenuController();
  final GlobalKey _anchorKey = GlobalKey();
  Rect _anchorRect = Rect.zero;
  bool _open = false;

  void _toggle() {
    if (_menu.isOpen) {
      _menu.close();
      return;
    }
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _anchorRect = box.localToGlobal(Offset.zero) & box.size;
    }
    _menu.open();
  }

  void _pick(DrawkitMenuItem item) {
    _menu.close();
    item.onSelected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final textStyle = DefaultTextStyle.of(context).style
        .merge(const TextStyle(color: DrawkitPalette.ink));

    return RawMenuAnchor(
      controller: _menu,
      consumeOutsideTaps: true,
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      overlayBuilder: (context, info) => TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (event) => _menu.close(),
        child: CustomSingleChildLayout(
          delegate: _PopoverPositionDelegate(
            anchorRect: _anchorRect,
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            width: widget.minWidth,
            gap: 4,
          ),
          child: _PopoverPanel(
            style: style,
            seed: widget.seed,
            animate: widget.animate,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in widget.items)
                  if (item.divider)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: CustomPaint(
                        size: const Size(double.infinity, 1.5),
                        painter: _RulePainter(
                          seed: widget.seed ?? 1,
                          ink: style.effectiveStroke,
                        ),
                      ),
                    )
                  else
                    _MenuRow(
                      item: item,
                      textStyle: textStyle,
                      style: style,
                      seed: widget.seed,
                      onPick: () => _pick(item),
                    ),
              ],
            ),
          ),
        ),
      ),
      builder: (context, controller, child) => DrawkitButton(
        key: _anchorKey,
        onPressed: _toggle,
        style: widget.style,
        seed: widget.seed,
        animate: widget.animate,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        semanticLabel: widget.semanticLabel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.child,
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: widget.animate
                  ? const Duration(milliseconds: 160)
                  : Duration.zero,
              curve: drawkitEase,
              child: DrawkitSurface(
                builder: (size, options) => [
                  DrawkitLayer(
                    roughLine(0, 0, size.width / 2, size.height, options),
                    drawkitStroke(style, fallbackWidth: 1.5),
                  ),
                  DrawkitLayer(
                    roughLine(
                      size.width / 2,
                      size.height,
                      size.width,
                      0,
                      RoughOptions(
                        seed: options.seed + 1,
                        roughness: options.roughness * 0.4,
                        boil: options.boil,
                      ),
                    ),
                    drawkitStroke(style, fallbackWidth: 1.5),
                  ),
                ],
                style: style,
                seed: widget.seed,
                animate: widget.animate,
                size: const Size(9, 5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.item,
    required this.textStyle,
    required this.style,
    required this.seed,
    required this.onPick,
  });

  final DrawkitMenuItem item;
  final TextStyle textStyle;
  final DrawkitStyle style;
  final int? seed;
  final VoidCallback onPick;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ink = widget.style.effectiveStroke;
    final wash = (_hovered || _focused) && item.active;
    return FocusableActionDetector(
      enabled: item.active,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            if (item.active) widget.onPick();
            return null;
          },
        ),
      },
      mouseCursor: item.active
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        enabled: item.active,
        checked: item.checked ? true : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: item.active ? widget.onPick : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: wash ? ink.withValues(alpha: 0.10) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: item.checked
                          ? CustomPaint(
                              painter: _CheckPainter(
                                seed: widget.seed ?? 1,
                                ink: ink,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: widget.textStyle.copyWith(
                          color: item.active ? null : DrawkitPalette.inkFaint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.hint != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        item.hint!,
                        style: widget.textStyle.copyWith(
                          fontSize: (widget.textStyle.fontSize ?? 14) - 2,
                          color: DrawkitPalette.inkFaint,
                        ),
                      ),
                    ],
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

class _RulePainter extends CustomPainter {
  _RulePainter({required this.seed, required this.ink});

  final int seed;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      roughLine(
        0,
        size.height / 2,
        size.width,
        size.height / 2,
        RoughOptions(seed: seed, roughness: 0.4),
      ),
      Paint()
        ..color = ink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RulePainter oldDelegate) =>
      seed != oldDelegate.seed || ink != oldDelegate.ink;
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.seed, required this.ink});

  final int seed;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      roughCheckmark(
        2,
        2,
        size.width - 4,
        size.height - 4,
        RoughOptions(seed: seed),
      ),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      seed != oldDelegate.seed || ink != oldDelegate.ink;
}

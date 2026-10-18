import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/intents.dart';
import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart';
import 'drawkit_panel.dart';

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
    this.onOpen,
    this.onClose,
    this.semanticLabel,
    this.controller,
    this.useRootOverlay = false,
    this.alignmentOffset = Offset.zero,
    this.maxWidth = 360,
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

  /// Fired after the panel opens / folds away.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// The trigger's accessible name; defaults to `'menu'`.
  final String? semanticLabel;

  /// External controller; one is created when null.
  final MenuController? controller;

  /// Builds the panel into the root overlay instead of the nearest one.
  final bool useRootOverlay;

  /// Nudges the parked panel position, in physical pixels.
  final Offset alignmentOffset;

  /// The widest the panel may grow when matching the trigger.
  final double maxWidth;

  @override
  State<DrawkitPopover> createState() => _DrawkitPopoverState();
}

class _DrawkitPopoverState extends State<DrawkitPopover> {
  late final MenuController _menu = widget.controller ?? MenuController();
  final GlobalKey _anchorKey = GlobalKey();
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _open = false;

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
      _menu.open();
    }
  }

  void _opened() {
    setState(() => _open = true);
    widget.onOpen?.call();
  }

  void _closed() {
    setState(() => _open = false);
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    return RawMenuAnchor(
      controller: _menu,
      consumeOutsideTaps: true,
      useRootOverlay: widget.useRootOverlay,
      childFocusNode: _focusNode,
      onOpen: _opened,
      onClose: _closed,
      overlayBuilder: (context, info) => TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (event) => _menu.close(),
        child: CustomSingleChildLayout(
          delegate: DrawkitPanelPositionDelegate(
            anchorRect: info.anchorRect,
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            width: widget.width,
            gap: widget.gap,
            maxHeight: _panelMaxHeight,
            maxWidth: widget.maxWidth,
            alignmentOffset: widget.alignmentOffset,
          ),
          child: FocusTraversalGroup(
            child: _PopoverPanel(
              style: style,
              seed: widget.seed,
              animate: widget.animate,
              padding: widget.padding,
              child: widget.child,
            ),
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
          expanded: _open,
          label: widget.semanticLabel ?? 'menu',
          onTap: _toggle,
          child: ExcludeSemantics(
            child: GestureDetector(
              key: _anchorKey,
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _toggle,
              child: DrawkitTapTarget(child: widget.trigger),
            ),
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

/// A sketched button that drops a menu of [DrawkitMenuItem]s: hover wash,
/// check marks, hints, dividers — and disabled rows that never fire.
class DrawkitMenu extends StatefulWidget {
  const DrawkitMenu({
    required this.child,
    required this.items,
    this.semanticLabel,
    this.minWidth = 180,
    this.maxWidth = 360,
    this.style,
    this.seed,
    this.animate = true,
    this.focusNode,
    this.autofocus = false,
    this.onOpen,
    this.onClose,
    this.controller,
    this.useRootOverlay = false,
    this.alignmentOffset = Offset.zero,
    super.key,
  });

  final Widget child;
  final List<DrawkitMenuItem> items;
  final String? semanticLabel;
  final double minWidth;
  final double maxWidth;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Fired after the panel opens / folds away.
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// External controller; one is created when null.
  final MenuController? controller;

  /// Builds the panel into the root overlay instead of the nearest one.
  final bool useRootOverlay;

  /// Nudges the parked panel position, in physical pixels.
  final Offset alignmentOffset;

  @override
  State<DrawkitMenu> createState() => _DrawkitMenuState();
}

class _DrawkitMenuState extends State<DrawkitMenu> {
  late final MenuController _menu = widget.controller ?? MenuController();
  final GlobalKey _anchorKey = GlobalKey();
  late FocusNode _triggerNode;
  late bool _ownsTriggerNode;
  List<FocusNode?> _rowNodes = const [];
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _attachTriggerNode();
    _syncRowNodes();
  }

  void _attachTriggerNode() {
    _ownsTriggerNode = widget.focusNode == null;
    _triggerNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(DrawkitMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsTriggerNode) _triggerNode.dispose();
      _attachTriggerNode();
    }
    if (widget.items.length != _rowNodes.length ||
        _dividerSignature(widget.items) != _dividerSignature(oldWidget.items)) {
      final hadRowFocus = _rowNodes.any((n) => n?.hasFocus ?? false);
      _syncRowNodes();
      if (_open && hadRowFocus) {
        final targets = _targets;
        if (targets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                !_rowNodes.any((n) => n?.hasFocus ?? false) &&
                _menu.isOpen) {
              _focusRow(targets.first);
            }
          });
        }
      }
    }
  }

  static String _dividerSignature(List<DrawkitMenuItem> items) =>
      items.map((item) => item.divider ? '1' : '0').join();

  @override
  void dispose() {
    for (final node in _rowNodes) {
      node?.dispose();
    }
    if (_ownsTriggerNode) _triggerNode.dispose();
    super.dispose();
  }

  void _syncRowNodes() {
    for (final node in _rowNodes) {
      node?.dispose();
    }
    _rowNodes = [
      for (final item in widget.items)
        item.divider ? null : FocusNode(skipTraversal: true),
    ];
  }

  /// Indexes that the arrow keys step through: rows the user can actually
  /// pick right now.
  List<int> get _targets => [
    for (var i = 0; i < widget.items.length; i++)
      if (widget.items[i].active) i,
  ];

  void _focusRow(int? index) => _rowNodes[index ?? -1]?.requestFocus();

  void _move(int delta) {
    final targets = _targets;
    if (targets.isEmpty) return;
    final current = _rowNodes.indexWhere((n) => n?.hasFocus ?? false);
    final at = targets.indexOf(current);
    _focusRow(targets[(at + delta + targets.length) % targets.length]);
  }

  void _edge(bool end) {
    final targets = _targets;
    if (targets.isEmpty) return;
    _focusRow(end ? targets.last : targets.first);
  }

  void _toggle() {
    if (_menu.isOpen) {
      _menu.close();
      return;
    }
    _menu.open();
  }

  void _pick(DrawkitMenuItem item) {
    _menu.close();
    item.onSelected?.call();
  }

  void _opened() {
    setState(() => _open = true);
    widget.onOpen?.call();
    final targets = _targets;
    if (targets.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _menu.isOpen) _focusRow(targets.first);
    });
  }

  void _closed() {
    final hadRowFocus = _rowNodes.any((n) => n?.hasFocus ?? false);
    setState(() => _open = false);
    widget.onClose?.call();
    if (!hadRowFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final palette = style.palette;
    final reduce = drawkitReduceMotion(context);
    final textStyle = DefaultTextStyle.of(context).style
        .merge(TextStyle(color: palette.ink));

    return RawMenuAnchor(
      controller: _menu,
      consumeOutsideTaps: true,
      useRootOverlay: widget.useRootOverlay,
      childFocusNode: _triggerNode,
      onOpen: _opened,
      onClose: _closed,
      overlayBuilder: (context, info) => TapRegion(
        groupId: info.tapRegionGroupId,
        onTapOutside: (event) => _menu.close(),
        child: CustomSingleChildLayout(
          delegate: DrawkitPanelPositionDelegate(
            anchorRect: info.anchorRect,
            textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
            width: null,
            minWidth: widget.minWidth,
            maxWidth: widget.maxWidth,
            gap: 4,
            maxHeight: _panelMaxHeight,
            alignmentOffset: widget.alignmentOffset,
          ),
          child: FocusTraversalGroup(
            child: _PopoverPanel(
              style: style,
              seed: widget.seed,
              animate: widget.animate,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Shortcuts(
                shortcuts: {
                  const SingleActivator(LogicalKeyboardKey.arrowDown):
                      const DrawkitMoveIntent(1),
                  const SingleActivator(LogicalKeyboardKey.arrowUp):
                      const DrawkitMoveIntent(-1),
                  const SingleActivator(LogicalKeyboardKey.arrowLeft):
                      const DrawkitNoopIntent(),
                  const SingleActivator(LogicalKeyboardKey.arrowRight):
                      const DrawkitNoopIntent(),
                  const SingleActivator(LogicalKeyboardKey.home):
                      const DrawkitEdgeIntent(false),
                  const SingleActivator(LogicalKeyboardKey.end):
                      const DrawkitEdgeIntent(true),
                },
                child: Actions(
                  actions: {
                    DrawkitMoveIntent: CallbackAction<DrawkitMoveIntent>(
                      onInvoke: (intent) {
                        _move(intent.delta);
                        return null;
                      },
                    ),
                    DrawkitEdgeIntent: CallbackAction<DrawkitEdgeIntent>(
                      onInvoke: (intent) {
                        _edge(intent.end);
                        return null;
                      },
                    ),
                    DrawkitNoopIntent: CallbackAction<DrawkitNoopIntent>(
                      onInvoke: (intent) => null,
                    ),
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.items.length; i++)
                          if (widget.items[i].divider)
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
                            DrawkitPanelRow(
                              label: widget.items[i].label,
                              textStyle: textStyle.copyWith(
                                color: widget.items[i].active
                                    ? null
                                    : palette.inkFaint,
                              ),
                              hint: widget.items[i].hint,
                              hintStyle: textStyle.copyWith(
                                fontSize: (textStyle.fontSize ?? 14) - 2,
                                color: palette.inkMuted,
                              ),
                              ink: style.effectiveStroke,
                              seed: widget.seed,
                              enabled: widget.items[i].active,
                              checked: widget.items[i].checked ? true : null,
                              focusNode: _rowNodes[i],
                              onPick: () => _pick(widget.items[i]),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      builder: (context, controller, child) => Semantics(
        expanded: _open,
        child: DrawkitButton(
          key: _anchorKey,
          onPressed: _toggle,
          style: widget.style,
          seed: widget.seed,
          animate: widget.animate,
          focusNode: _triggerNode,
          autofocus: widget.autofocus,
          semanticLabel: widget.semanticLabel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.child,
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: widget.animate && !reduce
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

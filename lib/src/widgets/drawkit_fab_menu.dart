import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/intents.dart';
import '../core/motion.dart';
import '../core/style.dart';
import 'drawkit_button.dart';

/// One action in a [DrawkitFabMenu]'s unfolding stack.
@immutable
class DrawkitFabMenuItem {
  const DrawkitFabMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;

  /// Decorative — excluded from semantics; the label is what gets announced.
  final Widget? icon;
}

/// Speed-dial sibling of [DrawkitFab]: the circle stays put while labelled
/// pills unfold above it, nearest action first. The pen mark turns a quarter
/// turn into a close mark, Escape or a tap outside folds everything back, and
/// keyboard focus walks from the top pill down into the circle.
class DrawkitFabMenu extends StatefulWidget {
  const DrawkitFabMenu({
    required this.items,
    this.child,
    this.semanticLabel = 'actions',
    this.tone = DrawkitTone.accent,
    this.size = 56,
    this.style,
    this.seed,
    this.animate = true,
    this.closeOnTapOutside = true,
    super.key,
  });

  final List<DrawkitFabMenuItem> items;

  /// The circle's face when closed. Defaults to a plus glyph.
  final Widget? child;

  final String semanticLabel;
  final DrawkitTone tone;
  final double size;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  /// Folds the menu back when a pointer lands anywhere outside it.
  final bool closeOnTapOutside;

  @override
  State<DrawkitFabMenu> createState() => _DrawkitFabMenuState();
}

class _DrawkitFabMenuState extends State<DrawkitFabMenu> {
  bool _open = false;
  late FocusNode _triggerNode;
  late List<FocusNode> _itemNodes;

  @override
  void initState() {
    super.initState();
    _triggerNode = FocusNode(debugLabel: 'drawkit fab menu trigger');
    _itemNodes = _makeItemNodes();
  }

  List<FocusNode> _makeItemNodes() => [
    for (var i = 0; i < widget.items.length; i++)
      FocusNode(debugLabel: 'drawkit fab menu item $i'),
  ];

  @override
  void didUpdateWidget(DrawkitFabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      for (final node in _itemNodes) {
        node.dispose();
      }
      _itemNodes = _makeItemNodes();
    }
  }

  @override
  void dispose() {
    _triggerNode.dispose();
    for (final node in _itemNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _openMenu() {
    setState(() => _open = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open && _itemNodes.isNotEmpty) {
        _itemNodes.first.requestFocus();
      }
    });
  }

  void _close() {
    final hadFocus = _itemNodes.any((node) => node.hasFocus);
    setState(() => _open = false);
    if (hadFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_triggerNode.canRequestFocus) return;
        final primary = FocusManager.instance.primaryFocus;
        if (primary != null && !identical(primary, _triggerNode)) return;
        _triggerNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = drawkitReduceMotion(context);
    final duration = widget.animate && !reduce
        ? const Duration(milliseconds: 260)
        : Duration.zero;

    final trigger = Semantics(
      expanded: _open,
      child: DrawkitFab(
        onPressed: _open ? _close : _openMenu,
        tone: widget.tone,
        size: widget.size,
        style: widget.style,
        seed: widget.seed,
        animate: widget.animate,
        semanticLabel: widget.semanticLabel,
        focusNode: _triggerNode,
        child: AnimatedRotation(
          turns: _open ? 0.125 : 0,
          duration: duration,
          curve: drawkitEase,
          child:
              widget.child ??
              const Text(
                '＋',
                style: TextStyle(
                  fontSize: 22,
                  height: 1,
                  decoration: TextDecoration.none,
                ),
              ),
        ),
      ),
    );

    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.escape):
            const DrawkitDismissIntent(),
      },
      child: Actions(
        actions: {
          DrawkitDismissIntent: CallbackAction<DrawkitDismissIntent>(
            onInvoke: (intent) {
              if (_open) _close();
              return null;
            },
          ),
        },
        child: TapRegion(
          onTapOutside: (event) {
            if (widget.closeOnTapOutside && _open) _close();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_open)
                for (var i = 0; i < widget.items.length; i++)
                  _DialItem(
                    item: widget.items[i],
                    index: i,
                    count: widget.items.length,
                    duration: duration,
                    focusNode: _itemNodes[i],
                    onPressed: () {
                      widget.items[i].onPressed();
                      _close();
                    },
                    style: widget.style,
                    seed: widget.seed == null ? null : widget.seed! + i,
                    animate: widget.animate,
                  ),
              trigger,
            ],
          ),
        ),
      ),
    );
  }
}

class _DialItem extends StatelessWidget {
  const _DialItem({
    required this.item,
    required this.index,
    required this.count,
    required this.duration,
    required this.focusNode,
    required this.onPressed,
    this.style,
    this.seed,
    this.animate = true,
  });

  final DrawkitFabMenuItem item;
  final int index;
  final int count;
  final Duration duration;
  final FocusNode focusNode;
  final VoidCallback onPressed;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    // Spread the whole stagger window over however many items exist, so a
    // long menu still unfolds in sequence instead of in simultaneous groups.
    final step = count <= 1 ? 0.0 : 0.7 / (count - 1);
    final start = (count - 1 - index) * step;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Interval(start.clamp(0, 0.7), 1, curve: drawkitEase),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DrawkitButton(
          tone: DrawkitTone.neutral,
          onPressed: onPressed,
          focusNode: focusNode,
          semanticLabel: item.label,
          style: style,
          seed: seed,
          animate: animate,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                ExcludeSemantics(child: item.icon!),
                const SizedBox(width: 8),
              ],
              ExcludeSemantics(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

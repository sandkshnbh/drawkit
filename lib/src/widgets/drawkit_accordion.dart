import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// One expandable section of a [DrawkitAccordion].
class DrawkitAccordionSection {
  const DrawkitAccordionSection({required this.title, required this.child});

  final String title;
  final Widget child;
}

/// Collapsible sketch sections: a ruled header with a chevron that flips as
/// the body unfolds. [allowMultiple] false keeps it a single-open group.
///
/// Expansion animates through [AnimatedSize]; reduced motion jumps straight
/// to the new layout. Every header is a tab stop and toggles with
/// Enter/Space; the arrow keys (and Home/End) jump between headers,
/// wrapping at the ends.
class DrawkitAccordion extends StatefulWidget {
  const DrawkitAccordion({
    required this.sections,
    this.allowMultiple = true,
    this.initiallyExpanded = const {},
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<DrawkitAccordionSection> sections;
  final bool allowMultiple;

  /// Indexes to open on mount.
  final Set<int> initiallyExpanded;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitAccordion> createState() => _DrawkitAccordionState();
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);

  final int delta;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent(this.end);

  final bool end;
}

class _DrawkitAccordionState extends State<DrawkitAccordion> {
  late Set<int> _open = {...widget.initiallyExpanded};
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = [for (var i = 0; i < widget.sections.length; i++) FocusNode()];
  }

  @override
  void didUpdateWidget(DrawkitAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sections.length != _nodes.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = [for (var i = 0; i < widget.sections.length; i++) FocusNode()];
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _move(int from, int delta) {
    final count = widget.sections.length;
    if (count == 0) return;
    _nodes[(from + delta + count) % count].requestFocus();
  }

  void _edge(bool end) {
    if (widget.sections.isEmpty) return;
    _nodes[end ? widget.sections.length - 1 : 0].requestFocus();
  }

  void _toggle(int index) {
    setState(() {
      if (_open.contains(index)) {
        _open.remove(index);
      } else if (widget.allowMultiple) {
        _open = {..._open, index};
      } else {
        _open = {index};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.sections.length; i++)
          _AccordionTile(
            section: widget.sections[i],
            index: i,
            open: _open.contains(i),
            focusNode: _nodes[i],
            onMove: (delta) => _move(i, delta),
            onEdge: _edge,
            style: style,
            seed: widget.seed == null ? null : widget.seed! + i,
            animate: widget.animate,
            onToggle: () => _toggle(i),
          ),
      ],
    );
  }
}

class _AccordionTile extends StatefulWidget {
  const _AccordionTile({
    required this.section,
    required this.index,
    required this.open,
    required this.focusNode,
    required this.onMove,
    required this.onEdge,
    required this.style,
    required this.seed,
    required this.animate,
    required this.onToggle,
  });

  final DrawkitAccordionSection section;
  final int index;
  final bool open;
  final FocusNode focusNode;
  final ValueChanged<int> onMove;
  final ValueChanged<bool> onEdge;
  final DrawkitStyle style;
  final int? seed;
  final bool animate;
  final VoidCallback onToggle;

  @override
  State<_AccordionTile> createState() => _AccordionTileState();
}

class _AccordionTileState extends State<_AccordionTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final textStyle = DefaultTextStyle.of(context).style;
    final motion = widget.animate && !drawkitReduceMotion(context);

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const _MoveIntent(
          1,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const _MoveIntent(
          -1,
        ),
        const SingleActivator(LogicalKeyboardKey.home): const _EdgeIntent(
          false,
        ),
        const SingleActivator(LogicalKeyboardKey.end): const _EdgeIntent(true),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onToggle();
            return null;
          },
        ),
        _MoveIntent: CallbackAction<_MoveIntent>(
          onInvoke: (intent) {
            widget.onMove(intent.delta);
            return null;
          },
        ),
        _EdgeIntent: CallbackAction<_EdgeIntent>(
          onInvoke: (intent) {
            widget.onEdge(intent.end);
            return null;
          },
        ),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        expanded: widget.open,
        onTap: widget.onToggle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onToggle,
                child: DrawkitSurface(
                  builder: (size, options) => [
                    if (_focused)
                      drawkitFocusRingRect(
                        size: size,
                        radius: 10,
                        options: options,
                        style: style,
                      ),
                    DrawkitLayer(
                      roughLine(
                        0,
                        size.height - 2,
                        size.width,
                        size.height - 2,
                        options,
                      ),
                      drawkitStroke(
                        style,
                        color: style.effectiveStroke.withValues(
                          alpha: _hovered ? 0.9 : 0.45,
                        ),
                        fallbackWidth: 1.5,
                      ),
                    ),
                  ],
                  style: style,
                  seed: widget.seed,
                  animate: widget.animate,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.section.title,
                            style: textStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: DrawkitPalette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedRotation(
                          turns: widget.open ? 0.5 : 0,
                          duration: motion
                              ? const Duration(milliseconds: 180)
                              : Duration.zero,
                          curve: drawkitEase,
                          child: DrawkitSurface(
                            builder: (size, options) => [
                              DrawkitLayer(
                                roughLine(
                                  0,
                                  0,
                                  size.width / 2,
                                  size.height,
                                  RoughOptions(
                                    seed: options.seed,
                                    roughness: options.roughness * 0.4,
                                    boil: options.boil,
                                  ),
                                ),
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
                            size: const Size(10, 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ClipRect(
              child: AnimatedSize(
                duration: motion
                    ? const Duration(milliseconds: 220)
                    : Duration.zero,
                curve: drawkitEase,
                alignment: Alignment.topCenter,
                child: widget.open
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(2, 10, 2, 14),
                        child: widget.section.child,
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

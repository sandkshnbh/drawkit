import 'package:flutter/widgets.dart';

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
/// to the new layout.
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

class _DrawkitAccordionState extends State<DrawkitAccordion> {
  late Set<int> _open = {...widget.initiallyExpanded};

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
    required this.style,
    required this.seed,
    required this.animate,
    required this.onToggle,
  });

  final DrawkitAccordionSection section;
  final int index;
  final bool open;
  final DrawkitStyle style;
  final int? seed;
  final bool animate;
  final VoidCallback onToggle;

  @override
  State<_AccordionTile> createState() => _AccordionTileState();
}

class _AccordionTileState extends State<_AccordionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final textStyle = DefaultTextStyle.of(context).style;
    final motion = widget.animate && !drawkitReduceMotion(context);

    return Semantics(
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
    );
  }
}

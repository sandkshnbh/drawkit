import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/intents.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/prng.dart';
import '../engine/rough.dart';
import 'drawkit_arrow.dart';
import 'drawkit_button.dart';
import 'drawkit_checkbox.dart';
import 'drawkit_decorations.dart';
import 'drawkit_list.dart';
import 'drawkit_text.dart';

/// Composites: several pen strokes on one piece, seeded from one base so a
/// chosen seed reproduces the whole thing — the same `group`/`seeded` contract
/// as `composites.ts`, adapted to widgets.

/// Badge around the whole chip, checkbox on its own 0.8-scaled box.
class DrawkitChip extends StatefulWidget {
  const DrawkitChip({
    required this.selected,
    required this.onChanged,
    required this.child,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;
  final Widget child;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitChip> createState() => _DrawkitChipState();
}

class _DrawkitChipState extends State<DrawkitChip> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _decorNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );
  bool _focused = false;

  bool get _enabled => widget.onChanged != null;

  @override
  void dispose() {
    _focusNode.dispose();
    _decorNode.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.selected);

  @override
  Widget build(BuildContext context) {
    final base = widget.seed ?? randomSeed();
    final resolved = widget.style ?? DrawkitTheme.of(context);
    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        enabled: _enabled,
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
              _toggle();
              return null;
            },
          ),
        },
        child: Semantics(
          button: true,
          selected: widget.selected,
          enabled: _enabled,
          onTap: _enabled ? _toggle : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _enabled ? _toggle : null,
            child: DrawkitTapTarget(
              child: DrawkitSurface(
                builder: (size, options) => [
                  if (_focused && _enabled)
                    drawkitFocusRingRect(
                      size: size,
                      radius: 14,
                      gapX: 3,
                      gapY: 3,
                      options: options,
                      style: resolved,
                    ),
                ],
                style: resolved,
                seed: base,
                animate: widget.animate,
                enabled: _enabled,
                child: DrawkitBadge(
                  style: widget.style,
                  seed: base,
                  animate: widget.animate,
                  padding: const EdgeInsetsDirectional.fromSTEB(6, 3, 10, 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: Transform.scale(
                            scale: 0.8,
                            child: DrawkitCheckbox(
                              value: widget.selected,
                              onChanged: widget.onChanged,
                              focusNode: _decorNode,
                              seed: base + 1,
                              animate: widget.animate,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      widget.child,
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

/// Tabs: the underline follows the active index, seeds stable per selection.
///
/// Keyboard follows the tabs pattern: Tab lands on the active tab, the arrow
/// keys move focus and activate (automatic activation, wrapping, following
/// the reading direction), and Home/End jump to the ends. A sketched ring
/// wraps the focused label.
class DrawkitTabs extends StatefulWidget {
  const DrawkitTabs({
    required this.labels,
    required this.active,
    required this.onChanged,
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<String> labels;
  final int active;
  final ValueChanged<int>? onChanged;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitTabs> createState() => _DrawkitTabsState();
}

class _DrawkitTabsState extends State<DrawkitTabs> {
  late List<FocusNode> _nodes;
  late int _seed = widget.seed ?? randomSeed();
  int? _focused;

  bool get _enabled => widget.onChanged != null;

  int get _active => widget.active >= 0 && widget.active < widget.labels.length
      ? widget.active
      : -1;

  int get _tabStop => _active >= 0 ? _active : 0;

  @override
  void initState() {
    super.initState();
    _nodes = [
      for (var i = 0; i < widget.labels.length; i++)
        FocusNode(skipTraversal: i != _tabStop),
    ];
  }

  @override
  void didUpdateWidget(DrawkitTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
    if (widget.labels.length != _nodes.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = [
        for (var i = 0; i < widget.labels.length; i++)
          FocusNode(skipTraversal: i != _tabStop),
      ];
      _focused = null;
    } else if (widget.active != oldWidget.active ||
        widget.onChanged != oldWidget.onChanged) {
      _syncTraversal();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncTraversal() {
    final stop = _tabStop;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = !_enabled || i != stop;
    }
  }

  void _pick(int index) {
    if (!_enabled || widget.labels.isEmpty) return;
    if (index != widget.active) widget.onChanged!(index);
    _nodes[index].requestFocus();
  }

  void _move(int delta) {
    final count = widget.labels.length;
    if (count == 0) return;
    final from = _focused ?? _tabStop;
    _pick((from + delta + count) % count);
  }

  void _edge(bool end) => _pick(end ? widget.labels.length - 1 : 0);

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = widget.style ?? DrawkitTheme.of(context);
    final enabled = _enabled;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final horizontal = rtl ? -1 : 1;
    final base = _seed;

    return Semantics(
      container: true,
      role: SemanticsRole.tabBar,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: i == widget.labels.length - 1 ? 0 : 18,
              ),
              child: FocusableActionDetector(
                focusNode: _nodes[i],
                enabled: enabled,
                onShowFocusHighlight: (value) => setState(() {
                  if (value) {
                    _focused = i;
                  } else if (_focused == i) {
                    _focused = null;
                  }
                }),
                shortcuts: {
                  SingleActivator(LogicalKeyboardKey.arrowRight):
                      DrawkitMoveIntent(horizontal),
                  SingleActivator(LogicalKeyboardKey.arrowLeft):
                      DrawkitMoveIntent(-horizontal),
                  const SingleActivator(LogicalKeyboardKey.arrowDown):
                      const DrawkitMoveIntent(1),
                  const SingleActivator(LogicalKeyboardKey.arrowUp):
                      const DrawkitMoveIntent(-1),
                  const SingleActivator(LogicalKeyboardKey.home):
                      const DrawkitEdgeIntent(false),
                  const SingleActivator(LogicalKeyboardKey.end):
                      const DrawkitEdgeIntent(true),
                  const SingleActivator(LogicalKeyboardKey.space):
                      const ActivateIntent(),
                  const SingleActivator(LogicalKeyboardKey.enter):
                      const ActivateIntent(),
                },
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
                  ActivateIntent: CallbackAction<ActivateIntent>(
                    onInvoke: (intent) {
                      _pick(i);
                      return null;
                    },
                  ),
                },
                mouseCursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: Semantics(
                  role: SemanticsRole.tab,
                  selected: i == widget.active,
                  enabled: enabled,
                  onTap: enabled ? () => widget.onChanged!(i) : null,
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: enabled ? () => widget.onChanged!(i) : null,
                    child: DrawkitTapTarget(
                      child: DrawkitSurface(
                        builder: (size, options) => [
                          if (_focused == i && enabled)
                            drawkitFocusRingRect(
                              size: size,
                              radius: 8,
                              gapX: 6,
                              gapY: 4,
                              options: options,
                              style: resolvedStyle,
                            ),
                        ],
                        style: resolvedStyle,
                        seed: base + 31 * (i + 1),
                        animate: widget.animate,
                        enabled: enabled,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: i == widget.active
                              ? DrawkitUnderline(
                                  text: widget.labels[i],
                                  textStyle: widget.textStyle,
                                  style: widget.style,
                                  seed: base,
                                  animate: widget.animate,
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    widget.labels[i],
                                    style: widget.textStyle,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card around the tip, arrow from it to the target. The arrow paints outside
/// its box, so drop the tooltip in a [Stack] with `clipBehavior: Clip.none`.
class DrawkitTooltip extends StatefulWidget {
  const DrawkitTooltip({
    required this.target,
    required this.child,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final GlobalKey target;
  final Widget child;

  /// Announced as the tip's tooltip text; omit for purely decorative tips.
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitTooltip> createState() => _DrawkitTooltipState();
}

class _DrawkitTooltipState extends State<DrawkitTooltip> {
  final GlobalKey _tipKey = GlobalKey();
  late int _seed = widget.seed ?? randomSeed();

  @override
  void didUpdateWidget(DrawkitTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _seed;
    Widget card = DrawkitCard(
      key: _tipKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      style: widget.style,
      seed: base,
      animate: widget.animate,
      child: widget.child,
    );
    if (widget.semanticLabel != null) {
      card = Semantics(
        container: true,
        tooltip: widget.semanticLabel,
        child: card,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned.fill(
          child: IgnorePointer(
            child: DrawkitArrow(
              from: _tipKey,
              to: widget.target,
              style: widget.style,
              seed: base + 1,
              animate: widget.animate,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card around the alert, badge on an optional tag.
class DrawkitAlert extends StatefulWidget {
  const DrawkitAlert({
    required this.child,
    this.tag,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final Widget? tag;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitAlert> createState() => _DrawkitAlertState();
}

class _DrawkitAlertState extends State<DrawkitAlert> {
  late int _seed = widget.seed ?? randomSeed();

  @override
  void didUpdateWidget(DrawkitAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _seed;
    return DrawkitCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      style: widget.style,
      seed: base,
      animate: widget.animate,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.tag != null) ...[
            DrawkitBadge(
              style: widget.style,
              seed: base + 1,
              animate: widget.animate,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              child: widget.tag!,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: widget.child),
        ],
      ),
    );
  }
}

/// A checklist: the list with check markers.
class DrawkitSteps extends StatelessWidget {
  const DrawkitSteps({
    required this.children,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<Widget> children;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) => DrawkitList(
    marker: DrawkitListMarker.check,
    style: style,
    seed: seed,
    animate: animate,
    children: children,
  );
}

/// Keys are drawn with a steadier hand than prose (roughness x0.6).
class DrawkitKbd extends StatelessWidget {
  const DrawkitKbd({
    required this.child,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    return DrawkitBadge(
      style: resolved.copyWith(roughness: resolved.roughness * 0.6),
      seed: seed,
      animate: animate,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: const [
              'Geist Mono',
              'ui-monospace',
              'monospace',
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Highlight on the quote, rule in a 10px band above an optional footer.
///
/// The rule spans the quote's block width (the `drawablyDivider` contract:
/// a line at the middle of a 10px-tall footer box), with the attribution
/// starting 8px into that band — `roughLine` at `y=5` clears the text.
class DrawkitQuote extends StatefulWidget {
  const DrawkitQuote({
    required this.text,
    this.textStyle,
    this.footer,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final String text;
  final TextStyle? textStyle;
  final Widget? footer;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitQuote> createState() => _DrawkitQuoteState();
}

class _DrawkitQuoteState extends State<DrawkitQuote> {
  late int _seed = widget.seed ?? randomSeed();

  @override
  void didUpdateWidget(DrawkitQuote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _seed;
    final resolved = widget.style ?? DrawkitTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DrawkitHighlight(
          text: widget.text,
          textStyle: widget.textStyle,
          style: resolved,
          seed: base,
          animate: widget.animate,
        ),
        if (widget.footer != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 10,
                  child: DrawkitSurface(
                    builder: (size, options) => [
                      DrawkitLayer(
                        roughLine(
                          3,
                          size.height / 2,
                          size.width - 3,
                          size.height / 2,
                          options,
                        ),
                        drawkitStroke(resolved),
                      ),
                    ],
                    style: resolved,
                    seed: base + 1,
                    animate: widget.animate,
                    resketchOnPointer: false,
                    child: const SizedBox(height: 10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DefaultTextStyle(
                    style: DefaultTextStyle.of(context).style
                        .copyWith(color: resolved.palette.inkMuted),
                    child: widget.footer!,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Page buttons: the current page is solid, the rest outlined.
class DrawkitPager extends StatefulWidget {
  const DrawkitPager({
    required this.count,
    required this.page,
    required this.onPage,
    this.labels,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : assert(labels == null || labels.length == count);

  final int count;
  final int page;
  final ValueChanged<int>? onPage;
  final List<String>? labels;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitPager> createState() => _DrawkitPagerState();
}

class _DrawkitPagerState extends State<DrawkitPager> {
  late int _seed = widget.seed ?? randomSeed();

  @override
  void didUpdateWidget(DrawkitPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != null && widget.seed != oldWidget.seed) {
      _seed = widget.seed!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _seed;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.count; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: i == widget.count - 1 ? 0 : 6,
            ),
            child: Semantics(
              selected: i == widget.page,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 34),
                child: DrawkitButton(
                  variant: i == widget.page
                      ? DrawkitButtonVariant.solid
                      : DrawkitButtonVariant.outline,
                  style: widget.style,
                  seed: base + i,
                  animate: widget.animate,
                  semanticLabel:
                      widget.labels?[i] ?? 'page ${i + 1} of ${widget.count}',
                  onPressed: widget.onPage == null
                      ? null
                      : () => widget.onPage!(i),
                  child: Center(child: Text(widget.labels?[i] ?? '${i + 1}')),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

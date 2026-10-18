import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/intents.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

const double _inset = 3;

/// One choice in a [DrawkitSegmentedButton].
@immutable
class DrawkitSegment<T> {
  const DrawkitSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// A single-choice segmented control: one sketched frame, a scribble wash
/// under the selected segment, redrawn (fresh seed) on every pick.
///
/// Keyboard follows the radio-group pattern: Tab lands on the selected
/// segment, the arrow keys move the selection (wrapping, following the
/// reading direction — right moves toward the nearest edge in RTL), and
/// Home/End jump to the ends. The row itself is direction-aware — segments
/// run start-to-end, so Arabic lists fill from the right and a tap reports
/// the value, never the position.
class DrawkitSegmentedButton<T> extends StatefulWidget {
  const DrawkitSegmentedButton({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<DrawkitSegment<T>> segments;
  final T selected;

  /// Null disables the whole control.
  final ValueChanged<T>? onChanged;

  /// External node for the segment that is the Tab stop (the selected one,
  /// or the first while the selection matches nothing).
  final FocusNode? focusNode;
  final bool autofocus;

  /// Group label announced before the segment labels.
  final String? semanticLabel;

  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitSegmentedButton<T>> createState() =>
      _DrawkitSegmentedButtonState<T>();
}

class _DrawkitSegmentedButtonState<T> extends State<DrawkitSegmentedButton<T>> {
  late List<FocusNode> _nodes;
  int? _focused;

  bool get _enabled => widget.onChanged != null;

  int get _active =>
      widget.segments.indexWhere((s) => s.value == widget.selected);

  /// The one segment Tab stops on: the selected one, or the first while the
  /// selection doesn't match (the radio "roving tabindex" rule).
  int get _tabStop => _active >= 0 ? _active : 0;

  @override
  void initState() {
    super.initState();
    _nodes = _makeNodes();
  }

  List<FocusNode> _makeNodes() => [
    for (var i = 0; i < widget.segments.length; i++)
      i == _tabStop && widget.focusNode != null
          ? widget.focusNode!
          : FocusNode(skipTraversal: i != _tabStop),
  ];

  void _disposeNodes() {
    for (final node in _nodes) {
      if (!identical(node, widget.focusNode)) node.dispose();
    }
  }

  void _rebuildNodes() {
    final focusedIndex = _nodes.indexWhere((node) => node.hasFocus);
    final hadFocus = _nodes.any((node) => node.hasFocus);
    _disposeNodes();
    _nodes = _makeNodes();
    _syncTraversal();
    _focused = null;
    if (hadFocus && focusedIndex >= 0 && focusedIndex < _nodes.length) {
      final node = _nodes[focusedIndex];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) node.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(DrawkitSegmentedButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.segments.length != _nodes.length ||
        widget.focusNode != oldWidget.focusNode) {
      _rebuildNodes();
    } else if (widget.selected != oldWidget.selected ||
        widget.onChanged != oldWidget.onChanged) {
      _syncTraversal();
    }
  }

  @override
  void dispose() {
    _disposeNodes();
    super.dispose();
  }

  void _syncTraversal() {
    final stop = _tabStop;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = !_enabled || i != stop;
    }
  }

  void _pick(int index) {
    if (!_enabled) return;
    final value = widget.segments[index].value;
    if (value != widget.selected) widget.onChanged!(value);
    _nodes[index].requestFocus();
  }

  void _move(int delta) {
    final count = widget.segments.length;
    final from = _focused ?? _tabStop;
    _pick((from + delta + count) % count);
  }

  void _edge(bool end) => _pick(end ? widget.segments.length - 1 : 0);

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = widget.style ?? DrawkitTheme.of(context);
    final enabled = _enabled;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final text = DefaultTextStyle.of(context).style
        .merge(TextStyle(color: resolvedStyle.palette.ink, fontSize: 14))
        .merge(widget.textStyle);
    final active = _active;
    final visual = rtl ? widget.segments.length - 1 - active : active;
    final horizontal = rtl ? -1 : 1;

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: DrawkitSurface(
        builder: (size, options) {
          final layers = <DrawkitLayer>[
            DrawkitLayer(
              roughRoundedRect(
                _inset,
                _inset,
                size.width - 2 * _inset,
                size.height - 2 * _inset,
                8,
                options,
              ),
              drawkitStroke(resolvedStyle),
            ),
          ];
          if (active >= 0) {
            final seg = size.width / widget.segments.length;
            layers.add(
              DrawkitLayer(
                scribbleFill(
                  seg * visual + 6,
                  6,
                  seg - 12,
                  size.height - 12,
                  options,
                ),
                drawkitStroke(
                  resolvedStyle,
                  color: resolvedStyle.effectiveStroke.withValues(alpha: 0.35),
                  fallbackWidth: 1.5,
                ),
              ),
            );
          }
          final focused = _focused;
          if (focused != null && enabled) {
            final seg = size.width / widget.segments.length;
            final visualFocus = rtl
                ? widget.segments.length - 1 - focused
                : focused;
            final ring = drawkitFocusRingRect(
              size: Size(seg - 2 * _inset - 2, size.height - 2 * _inset - 2),
              radius: 10,
              options: options,
              style: resolvedStyle,
            );
            layers.add(
              DrawkitLayer(
                ring.path,
                ring.paint,
                matrix: () => Matrix4.translationValues(
                  seg * visualFocus + _inset + 1,
                  _inset + 1,
                  0,
                ),
              ),
            );
          }
          return layers;
        },
        style: resolvedStyle,
        seed: widget.seed,
        animate: widget.animate,
        enabled: enabled,
        resketchOnPointer: true,
        child: Row(
          children: [
            for (var i = 0; i < widget.segments.length; i++)
              Expanded(
                child: FocusableActionDetector(
                  focusNode: _nodes[i],
                  autofocus: widget.autofocus && i == _tabStop,
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
                    button: true,
                    selected: i == active,
                    enabled: enabled,
                    onTap: enabled ? () => _pick(i) : null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: enabled ? () => _pick(i) : null,
                      child: DrawkitTapTarget(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            widget.segments[i].label,
                            style: text,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

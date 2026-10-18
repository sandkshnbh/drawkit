import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/intents.dart';
import '../core/style.dart';
import 'drawkit_dialog.dart';
import 'drawkit_search.dart';

/// One entry in a command palette.
class DrawkitCommand<T> {
  const DrawkitCommand({
    required this.label,
    required this.value,
    this.hint,
    this.keywords = const [],
    this.leading,
    this.group,
    this.enabled = true,
  });

  final String label;
  final T value;

  /// Trailing shortcut label, e.g. `⌘ K`.
  final String? hint;

  /// Extra words the filter may match, beyond [label].
  final List<String> keywords;

  /// Optional glyph shown before the label.
  final Widget? leading;

  /// Optional section title; consecutive commands sharing a group sit under
  /// one header.
  final String? group;

  /// Disabled commands render faint, the arrow walk steps over them, and
  /// Enter refuses to run them.
  final bool enabled;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (label.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// Opens the sketch command palette: type to filter, arrows to walk, enter to
/// run, escape to walk away. The future completes with the chosen value, or
/// null when dismissed.
Future<T?> showDrawkitCommandPalette<T extends Object?>({
  required BuildContext context,
  required List<DrawkitCommand<T>> commands,
  String placeholder = 'type a command…',
  String emptyLabel = 'nothing matches',
  double width = 460,
  DrawkitStyle? style,
  int? seed,
  bool animate = true,
  bool Function(DrawkitCommand<T> command, String query)? filterCallback,
  T? initialSelection,
}) => showDrawkitDialog<T>(
  context: context,
  style: style,
  seed: seed,
  animate: animate,
  maxWidth: width,
  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
  child: _CommandPalette<T>(
    commands: commands,
    placeholder: placeholder,
    emptyLabel: emptyLabel,
    style: style,
    seed: seed,
    animate: animate,
    filterCallback: filterCallback,
    initialSelection: initialSelection,
  ),
);

class _CommandPalette<T> extends StatefulWidget {
  const _CommandPalette({
    required this.commands,
    required this.placeholder,
    required this.emptyLabel,
    required this.style,
    required this.seed,
    required this.animate,
    required this.filterCallback,
    required this.initialSelection,
  });

  final List<DrawkitCommand<T>> commands;
  final String placeholder;
  final String emptyLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final bool Function(DrawkitCommand<T> command, String query)? filterCallback;
  final T? initialSelection;

  @override
  State<_CommandPalette<T>> createState() => _CommandPaletteState<T>();
}

class _CommandPaletteState<T> extends State<_CommandPalette<T>> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final Map<DrawkitCommand<T>, GlobalKey> _rowKeys = {};
  String _query = '';
  int _highlighted = 0;
  bool _invoked = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    if (initial == null) return;
    final index = widget.commands.indexWhere(
      (command) => command.value == initial,
    );
    if (index >= 0) _highlighted = index;
  }

  List<DrawkitCommand<T>> get _filtered {
    final filter = widget.filterCallback;
    if (filter == null) {
      return widget.commands.where((c) => c.matches(_query)).toList();
    }
    return widget.commands.where((c) => filter(c, _query)).toList();
  }

  void _move(int delta) {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    var index = _highlighted.clamp(0, filtered.length - 1);
    for (var step = 0; step < filtered.length; step++) {
      index = (index + delta) % filtered.length;
      if (filtered[index].enabled) break;
    }
    if (!filtered[index].enabled) return;
    setState(() => _highlighted = index);
    _revealHighlighted();
  }

  void _edge(bool end) {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    var index = end ? filtered.length - 1 : 0;
    final step = end ? -1 : 1;
    while (index >= 0 && index < filtered.length && !filtered[index].enabled) {
      index += step;
    }
    if (index < 0 || index >= filtered.length) return;
    setState(() => _highlighted = index);
    _revealHighlighted();
  }

  /// Keeps the keyboard cursor visible when the arrows walk past the 280px
  /// viewport, instead of moving an invisible selection.
  void _revealHighlighted() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filtered = _filtered;
      if (filtered.isEmpty) return;
      final index = _highlighted.clamp(0, filtered.length - 1);
      final rowContext = _rowKeys[filtered[index]]?.currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(rowContext, alignment: 0.5);
    });
  }

  void _invoke(DrawkitCommand<T> command) {
    if (_invoked || !command.enabled) return;
    _invoked = true;
    Navigator.of(context).pop(command.value);
  }

  void _invokeHighlighted() {
    final filtered = _filtered;
    if (filtered.isEmpty) return;
    _invoke(filtered[_highlighted.clamp(0, filtered.length - 1)]);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final filtered = _filtered;
    final highlighted = filtered.isEmpty
        ? -1
        : _highlighted.clamp(0, filtered.length - 1);

    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const DrawkitMoveIntent(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const DrawkitMoveIntent(-1),
        const SingleActivator(LogicalKeyboardKey.home): const DrawkitEdgeIntent(
          false,
        ),
        const SingleActivator(LogicalKeyboardKey.end): const DrawkitEdgeIntent(
          true,
        ),
        const SingleActivator(LogicalKeyboardKey.escape):
            const DrawkitDismissIntent(),
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
          DrawkitDismissIntent: CallbackAction<DrawkitDismissIntent>(
            onInvoke: (intent) {
              if (_invoked) return null;
              _invoked = true;
              Navigator.maybePop(context);
              return null;
            },
          ),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawkitSearchField(
              controller: _controller,
              autofocus: true,
              placeholder: widget.placeholder,
              style: widget.style,
              seed: widget.seed,
              animate: widget.animate,
              onChanged: (value) => setState(() {
                _query = value;
                _highlighted = 0;
              }),
              onSubmitted: (value) => _invokeHighlighted(),
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  widget.emptyLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: style.palette.inkFaint,
                    decoration: TextDecoration.none,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        if (filtered[i].group != null &&
                            (i == 0 ||
                                filtered[i - 1].group != filtered[i].group))
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              10,
                              i == 0 ? 2 : 10,
                              10,
                              4,
                            ),
                            child: Text(
                              filtered[i].group!,
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 0.4,
                                color: style.palette.inkFaint,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        _CommandRow(
                          key: _rowKeys.putIfAbsent(
                            filtered[i],
                            () => GlobalKey(),
                          ),
                          command: filtered[i],
                          highlighted: i == highlighted,
                          ink: style.effectiveStroke,
                          onPick: () => _invoke(filtered[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CommandRow extends StatefulWidget {
  const _CommandRow({
    required this.command,
    required this.highlighted,
    required this.ink,
    required this.onPick,
    super.key,
  });

  final DrawkitCommand<Object?> command;
  final bool highlighted;
  final Color ink;
  final VoidCallback onPick;

  @override
  State<_CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends State<_CommandRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    final enabled = widget.command.enabled;
    final wash = enabled && (widget.highlighted || _hovered);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onPick : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: wash
                ? widget.ink.withValues(alpha: widget.highlighted ? 0.12 : 0.07)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                if (widget.command.leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: widget.command.leading!,
                  ),
                Expanded(
                  child: Text(
                    widget.command.label,
                    style: TextStyle(
                      color: enabled ? palette.ink : palette.inkFaint,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (widget.command.hint != null)
                  Text(
                    widget.command.hint!,
                    style: TextStyle(
                      color: palette.inkFaint,
                      fontSize: 12,
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

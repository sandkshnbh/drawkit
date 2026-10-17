import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
  });

  final String label;
  final T value;

  /// Trailing shortcut label, e.g. `⌘ K`.
  final String? hint;

  /// Extra words the filter may match, beyond [label].
  final List<String> keywords;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (label.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.delta);

  final int delta;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent(this.end);

  final bool end;
}

class _DismissIntent extends Intent {
  const _DismissIntent();
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
}) => showDrawkitDialog<T>(
  context: context,
  style: style,
  seed: seed,
  animate: animate,
  child: _CommandPalette<T>(
    commands: commands,
    placeholder: placeholder,
    emptyLabel: emptyLabel,
    width: width,
    style: style,
    seed: seed,
    animate: animate,
  ),
);

class _CommandPalette<T> extends StatefulWidget {
  const _CommandPalette({
    required this.commands,
    required this.placeholder,
    required this.emptyLabel,
    required this.width,
    required this.style,
    required this.seed,
    required this.animate,
  });

  final List<DrawkitCommand<T>> commands;
  final String placeholder;
  final String emptyLabel;
  final double width;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<_CommandPalette<T>> createState() => _CommandPaletteState<T>();
}

class _CommandPaletteState<T> extends State<_CommandPalette<T>> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  int _highlighted = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DrawkitCommand<T>> get _filtered =>
      widget.commands.where((c) => c.matches(_query)).toList();

  void _move(int delta) {
    final count = _filtered.length;
    if (count == 0) return;
    setState(() => _highlighted = (_highlighted + delta) % count);
  }

  void _edge(bool end) {
    final count = _filtered.length;
    if (count == 0) return;
    setState(() => _highlighted = end ? count - 1 : 0);
  }

  void _invoke(DrawkitCommand<T> command) =>
      Navigator.of(context).pop(command.value);

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
        const SingleActivator(LogicalKeyboardKey.escape):
            const _DismissIntent(),
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
          _DismissIntent: CallbackAction<_DismissIntent>(
            onInvoke: (intent) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: DrawkitTheme(
          data: style,
          child: DrawkitDialog(
            maxWidth: widget.width,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            style: widget.style,
            seed: widget.seed,
            animate: widget.animate,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < filtered.length; i++)
                            _CommandRow(
                              command: filtered[i],
                              highlighted: i == highlighted,
                              ink: style.effectiveStroke,
                              onPick: () => _invoke(filtered[i]),
                            ),
                        ],
                      ),
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

class _CommandRow extends StatefulWidget {
  const _CommandRow({
    required this.command,
    required this.highlighted,
    required this.ink,
    required this.onPick,
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
    final wash = widget.highlighted || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPick,
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
                Expanded(
                  child: Text(
                    widget.command.label,
                    style: TextStyle(
                      color: palette.ink,
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

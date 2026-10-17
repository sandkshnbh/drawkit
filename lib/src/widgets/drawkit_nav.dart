import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// One stop in a [DrawkitNavRail] or [DrawkitBottomNav].
@immutable
class DrawkitNavDestination {
  const DrawkitNavDestination({required this.label, this.icon});

  final String label;

  /// Decorative — excluded from semantics; the label is what gets announced.
  final Widget? icon;
}

/// Vertical navigation rail: destinations stack start-edge top down, the
/// chosen tile wears a scribble wash and redraws itself on every pick.
class DrawkitNavRail extends StatelessWidget {
  const DrawkitNavRail({
    required this.destinations,
    required this.selected,
    required this.onChanged,
    this.width = 88,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<DrawkitNavDestination> destinations;
  final int selected;

  /// Null disables the whole rail.
  final ValueChanged<int>? onChanged;

  final double width;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < destinations.length; i++)
            _NavTile(
              destination: destinations[i],
              isSelected: i == selected && enabled,
              width: width,
              onTap: enabled ? () => onChanged!(i) : null,
              style: style,
              seed: seed == null ? null : seed! + i,
              animate: animate,
            ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar: one paper strip with a top rule, destinations
/// spread start-to-end across it. Mirrors in RTL — the first destination
/// always sits at the start edge.
class DrawkitBottomNav extends StatelessWidget {
  const DrawkitBottomNav({
    required this.destinations,
    required this.selected,
    required this.onChanged,
    this.height = 58,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<DrawkitNavDestination> destinations;
  final int selected;
  final ValueChanged<int>? onChanged;
  final double height;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final enabled = onChanged != null;
    return Semantics(
      container: true,
      child: DrawkitSurface(
        builder: (size, options) => [
          DrawkitLayer(
            roughRoundedRect(0, 0, size.width, size.height, 0, options),
            drawkitFillPaint(resolved.paperColor),
          ),
          DrawkitLayer(
            roughLine(-2, 1.5, size.width + 2, 1.5, options),
            drawkitStroke(resolved, fallbackWidth: 1.5),
          ),
        ],
        style: resolved,
        seed: seed,
        animate: animate,
        child: SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavTile(
                    destination: destinations[i],
                    isSelected: i == selected && enabled,
                    onTap: enabled ? () => onChanged!(i) : null,
                    style: style,
                    seed: seed == null ? null : seed! + i,
                    animate: animate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    this.width,
    this.style,
    this.seed,
    this.animate = true,
  });

  final DrawkitNavDestination destination;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final enabled = widget.onTap != null;
    final label = Text(
      widget.destination.label,
      style: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
        color: enabled
            ? (widget.isSelected ? DrawkitPalette.ink : DrawkitPalette.inkMuted)
            : DrawkitPalette.inkFaint,
        decoration: TextDecoration.none,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.destination.icon != null) ...[
            widget.destination.icon!,
            const SizedBox(height: 4),
          ],
          label,
        ],
      ),
    );

    if (widget.isSelected) {
      content = DrawkitSurface(
        builder: (size, options) => [
          DrawkitLayer(
            scribbleFill(5, 4, size.width - 10, size.height - 8, options),
            drawkitStroke(
              resolved,
              color: resolved.effectiveStroke.withValues(alpha: 0.35),
              fallbackWidth: 1.5,
            ),
          ),
        ],
        style: resolved,
        seed: widget.seed,
        animate: widget.animate,
        resketchOnPointer: true,
        child: content,
      );
    }

    if (_focused && enabled) {
      content = DrawkitSurface(
        builder: (size, options) => [
          drawkitFocusRingRect(
            size: size,
            radius: 10,
            gapX: -5,
            gapY: -3,
            options: options,
            style: resolved,
          ),
        ],
        style: resolved,
        seed: widget.seed,
        animate: widget.animate,
        child: content,
      );
    }

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        enabled: enabled,
        label: widget.destination.label,
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: widget.width == null
                ? Center(child: DrawkitTapTarget(child: content))
                : SizedBox(
                    width: widget.width,
                    child: Center(child: DrawkitTapTarget(child: content)),
                  ),
          ),
        ),
      ),
    );
  }
}

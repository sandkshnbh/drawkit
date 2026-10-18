import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/motion.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_nav.dart';

/// Floating navigation bar: a paper capsule hovering above the content with
/// air around it, the chosen destination wearing a soft ink blob.
///
/// Two label moods, both from the 2025 floating-bar wave: [showLabels] true
/// keeps every label in view (icon and label side by side), false lets only
/// the pick open into a label while the rest stay glyphs. With
/// [hideOnScroll] the bar tucks itself below the fold while the linked
/// [scrollController] moves down and slides back on the first upward flick —
/// the scroll-aware trick every floating nav package ships.
class DrawkitFloatingNavBar extends StatefulWidget {
  const DrawkitFloatingNavBar({
    required this.destinations,
    required this.selected,
    required this.onChanged,
    this.margin = const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
    this.height = 56,
    this.showLabels = true,
    this.hideOnScroll = false,
    this.scrollController,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<DrawkitNavDestination> destinations;
  final int selected;

  /// Null disables the whole bar.
  final ValueChanged<int>? onChanged;

  final EdgeInsetsGeometry margin;
  final double height;
  final bool showLabels;
  final bool hideOnScroll;

  /// The scrollable the bar watches when [hideOnScroll] is on. Without a
  /// controller the bar stays put.
  final ScrollController? scrollController;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitFloatingNavBar> createState() => _DrawkitFloatingNavBarState();
}

class _DrawkitFloatingNavBarState extends State<DrawkitFloatingNavBar> {
  bool _hidden = false;
  double? _lastPixels;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(DrawkitFloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
      _lastPixels = null;
    }
    if (!widget.hideOnScroll && _hidden) _hidden = false;
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (!widget.hideOnScroll || controller == null || !controller.hasClients) {
      return;
    }
    final position = controller.position;
    final pixels = position.pixels;
    final last = _lastPixels;
    _lastPixels = pixels;

    var hidden = _hidden;
    if (pixels <= position.minScrollExtent + 0.5) {
      hidden = false;
    } else if (last != null && (pixels - last).abs() > 1) {
      hidden = pixels > last;
    }
    if (hidden != _hidden) setState(() => _hidden = hidden);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final enabled = widget.onChanged != null;
    final reduce = drawkitReduceMotion(context);
    final duration = widget.animate && !reduce
        ? const Duration(milliseconds: 220)
        : Duration.zero;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return IgnorePointer(
      ignoring: _hidden,
      child: ExcludeFocus(
        excluding: _hidden,
        child: ExcludeSemantics(
          excluding: _hidden,
          child: AnimatedSlide(
            offset: _hidden ? const Offset(0, 1.8) : Offset.zero,
            duration: duration,
            curve: drawkitEase,
            child: AnimatedOpacity(
              opacity: _hidden ? 0 : 1,
              duration: duration,
              curve: drawkitEase,
              child: Padding(
                padding: widget.margin.add(EdgeInsets.only(bottom: safeBottom)),
                child: Semantics(
                  container: true,
                  child: DrawkitSurface(
                    builder: (size, options) => [
                      DrawkitLayer(
                        roughRoundedRect(
                          0,
                          0,
                          size.width,
                          size.height,
                          size.height / 2,
                          options,
                        ),
                        drawkitFillPaint(resolved.paperColor),
                      ),
                      DrawkitLayer(
                        roughRoundedRect(
                          0,
                          0,
                          size.width,
                          size.height,
                          size.height / 2,
                          options,
                        ),
                        drawkitStroke(resolved, fallbackWidth: 1.5),
                      ),
                    ],
                    style: resolved,
                    seed: widget.seed,
                    animate: widget.animate,
                    child: SizedBox(
                      height: widget.height,
                      child: Row(
                        children: [
                          for (var i = 0; i < widget.destinations.length; i++)
                            Expanded(
                              child: _FloatingTile(
                                destination: widget.destinations[i],
                                isSelected: i == widget.selected && enabled,
                                showLabel:
                                    widget.showLabels ||
                                    (i == widget.selected && enabled),
                                onTap: enabled
                                    ? () => widget.onChanged!(i)
                                    : null,
                                style: widget.style,
                                seed: widget.seed == null
                                    ? null
                                    : widget.seed! + i,
                                animate: widget.animate,
                              ),
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
      ),
    );
  }
}

class _FloatingTile extends StatefulWidget {
  const _FloatingTile({
    required this.destination,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
    this.style,
    this.seed,
    this.animate = true,
  });

  final DrawkitNavDestination destination;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback? onTap;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<_FloatingTile> createState() => _FloatingTileState();
}

class _FloatingTileState extends State<_FloatingTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    final enabled = widget.onTap != null;
    final reduce = drawkitReduceMotion(context);
    final duration = widget.animate && !reduce
        ? const Duration(milliseconds: 220)
        : Duration.zero;

    final ink = enabled
        ? (widget.isSelected ? resolved.palette.ink : resolved.palette.inkMuted)
        : resolved.palette.inkFaint;

    Widget label = Text(
      widget.destination.label,
      style: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
        color: ink,
        decoration: TextDecoration.none,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    Widget? glyph;
    if (widget.destination.icon != null) {
      glyph = widget.destination.badge == null
          ? widget.destination.icon
          : Stack(
              clipBehavior: Clip.none,
              children: [
                widget.destination.icon!,
                Positioned(
                  top: -7,
                  right: -10,
                  child: DrawkitNavBadge(
                    count: widget.destination.badge!,
                    style: resolved,
                    seed: widget.seed,
                    animate: widget.animate,
                  ),
                ),
              ],
            );
    }

    Widget content = AnimatedContainer(
      duration: duration,
      curve: drawkitEase,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: widget.isSelected ? 16 : 12),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? resolved.effectiveStroke.withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            ExcludeSemantics(child: glyph),
            const SizedBox(width: 6),
          ] else if (widget.destination.badge != null) ...[
            DrawkitNavBadge(
              count: widget.destination.badge!,
              style: resolved,
              seed: widget.seed,
              animate: widget.animate,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: AnimatedSize(
              duration: duration,
              curve: drawkitEase,
              alignment: AlignmentDirectional.centerStart,
              child: widget.showLabel
                  ? label
                  : const SizedBox(width: 0, height: 0),
            ),
          ),
        ],
      ),
    );

    if (_focused && enabled) {
      content = DrawkitSurface(
        builder: (size, options) => [
          drawkitFocusRingRect(
            size: size,
            radius: size.height / 2,
            gapX: -1,
            gapY: -1,
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
        label: widget.destination.announcement,
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: DrawkitTapTarget(child: content),
          ),
        ),
      ),
    );
  }
}

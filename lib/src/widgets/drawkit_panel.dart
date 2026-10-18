import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../engine/rough.dart';

/// Internals shared by the overlay panels (`DrawkitMenu`, `DrawkitPopover`,
/// `DrawkitSelect`): the anchored positioner, the sketched check mark, and the
/// row. Kept out of `drawkit.dart` — apps never see these.

/// Places a panel below its anchor, flipping above when tight, and follows
/// the reading direction for the horizontal alignment.
class DrawkitPanelPositionDelegate extends SingleChildLayoutDelegate {
  const DrawkitPanelPositionDelegate({
    required this.anchorRect,
    required this.textDirection,
    required this.gap,
    required this.maxHeight,
    this.width,
    this.minWidth = 180,
    this.maxWidth = 360,
    this.alignmentOffset = Offset.zero,
  });

  final Rect anchorRect;
  final TextDirection textDirection;
  final double gap;
  final double maxHeight;
  final double? width;
  final double minWidth;
  final double maxWidth;
  final Offset alignmentOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final w = (width ?? anchorRect.width).clamp(minWidth, maxWidth);
    return BoxConstraints(minWidth: w, maxWidth: w, maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = anchorRect.bottom + gap;
    final fitsBelow = below + childSize.height <= size.height;
    final y =
        (fitsBelow ? below : anchorRect.top - gap - childSize.height) +
        alignmentOffset.dy;
    final rawX = textDirection == TextDirection.rtl
        ? anchorRect.right - childSize.width
        : anchorRect.left;
    final x = rawX + alignmentOffset.dx;
    return Offset(
      x.clamp(0.0, (size.width - childSize.width).clamp(0.0, double.infinity)),
      y.clamp(
        0.0,
        (size.height - childSize.height).clamp(0.0, double.infinity),
      ),
    );
  }

  @override
  bool shouldRelayout(DrawkitPanelPositionDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      textDirection != oldDelegate.textDirection ||
      gap != oldDelegate.gap ||
      maxHeight != oldDelegate.maxHeight ||
      width != oldDelegate.width ||
      minWidth != oldDelegate.minWidth ||
      maxWidth != oldDelegate.maxWidth ||
      alignmentOffset != oldDelegate.alignmentOffset;
}

/// The rows' chosen-mark: a 2px-inset check sized to its 14px box.
class DrawkitCheckPainter extends CustomPainter {
  DrawkitCheckPainter({required this.seed, required this.ink});

  final int seed;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      roughCheckmark(
        2,
        2,
        size.width - 4,
        size.height - 4,
        RoughOptions(seed: seed),
      ),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(DrawkitCheckPainter oldDelegate) =>
      seed != oldDelegate.seed || ink != oldDelegate.ink;
}

/// One row of a popup panel: hover/focus wash, optional check, label, hint.
///
/// [enabled] false disables the row (no wash, no tap, basic cursor);
/// [checked] and [selected] drive the check slot and the semantics flags.
class DrawkitPanelRow extends StatefulWidget {
  const DrawkitPanelRow({
    required this.label,
    required this.textStyle,
    required this.ink,
    required this.seed,
    required this.onPick,
    this.enabled,
    this.checked,
    this.selected,
    this.hint,
    this.hintStyle,
    this.hPadding = 10,
    this.focusNode,
    super.key,
  });

  final String label;
  final TextStyle textStyle;
  final Color ink;
  final int? seed;
  final VoidCallback onPick;
  final bool? enabled;
  final bool? checked;
  final bool? selected;
  final String? hint;
  final TextStyle? hintStyle;
  final double hPadding;
  final FocusNode? focusNode;

  @override
  State<DrawkitPanelRow> createState() => _DrawkitPanelRowState();
}

class _DrawkitPanelRowState extends State<DrawkitPanelRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled ?? true;
    final wash = (_hovered || _focused) && active && widget.selected != true;
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: active,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            if (active) widget.onPick();
            return null;
          },
        ),
      },
      mouseCursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        checked: widget.checked,
        selected: widget.selected,
        onTap: active ? widget.onPick : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: active ? widget.onPick : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: wash ? widget.ink.withValues(alpha: 0.10) : null,
              ),
              child: DrawkitTapTarget(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.hPadding,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: widget.checked == true || widget.selected == true
                            ? CustomPaint(
                                painter: DrawkitCheckPainter(
                                  seed: widget.seed ?? 1,
                                  ink: widget.ink,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: widget.textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.hint != null) ...[
                        const SizedBox(width: 12),
                        Text(widget.hint!, style: widget.hintStyle),
                      ],
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

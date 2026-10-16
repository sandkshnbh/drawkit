import 'package:flutter/widgets.dart';

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
/// The row is direction-aware — segments run start-to-end, so Arabic lists
/// fill from the right and a tap reports the value, never the position.
class DrawkitSegmentedButton<T> extends StatelessWidget {
  const DrawkitSegmentedButton({
    required this.segments,
    required this.selected,
    required this.onChanged,
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

  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? DrawkitTheme.of(context);
    final enabled = onChanged != null;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final text = DefaultTextStyle.of(context).style
        .merge(const TextStyle(color: DrawkitPalette.ink, fontSize: 14))
        .merge(textStyle);
    final active = segments.indexWhere((s) => s.value == selected);
    final visual = rtl ? segments.length - 1 - active : active;

    return Semantics(
      container: true,
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
            final seg = size.width / segments.length;
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
          return layers;
        },
        style: resolvedStyle,
        seed: seed,
        animate: animate,
        enabled: enabled,
        resketchOnPointer: true,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == active,
                  enabled: enabled,
                  child: MouseRegion(
                    cursor: enabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled
                          ? () => onChanged!(segments[i].value)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          segments[i].label,
                          style: text,
                          textAlign: TextAlign.center,
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

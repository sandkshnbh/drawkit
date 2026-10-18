import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// Whole-star rating: tap a star to set it, tap the current value to clear
/// back one. Read-only when [onChanged] is null.
///
/// One [DrawkitSurface] paints every star, so the boil steps them together
/// and a tap redraws the whole row with a fresh seed.
class DrawkitRating extends StatelessWidget {
  const DrawkitRating({
    required this.value,
    this.count = 5,
    this.onChanged,
    this.starSize = 26,
    this.spacing = 4,
    this.semanticLabel = 'rating',
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : assert(value >= 0 && value <= count, 'value must sit within count');

  final int value;
  final int count;

  /// Reports the new star count; null makes the row read-only.
  final ValueChanged<int>? onChanged;

  final double starSize;
  final double spacing;
  final String semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  List<Offset> _star(int index, double width, bool rtl) {
    final slot = index * (starSize + spacing);
    final cx = rtl ? width - slot - starSize / 2 : slot + starSize / 2;
    final cy = starSize / 2;
    final outer = starSize / 2 - 3;
    final inner = outer * 0.46;
    return [
      for (var k = 0; k < 10; k++)
        Offset(
          cx +
              math.cos(-math.pi / 2 + k * math.pi / 5) *
                  (k.isEven ? outer : inner),
          cy +
              math.sin(-math.pi / 2 + k * math.pi / 5) *
                  (k.isEven ? outer : inner),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final enabled = onChanged != null;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final width = count * (starSize + spacing) - spacing;
    final fill = Paint()
      ..color = resolved.effectiveStroke
      ..style = PaintingStyle.fill;

    return Semantics(
      slider: true,
      enabled: enabled,
      label: semanticLabel,
      value: '$value of $count stars',
      increasedValue: value < count ? '${value + 1} of $count stars' : null,
      decreasedValue: value > 0 ? '${value - 1} of $count stars' : null,
      onIncrease: enabled && value < count ? () => onChanged!(value + 1) : null,
      onDecrease: enabled && value > 0 ? () => onChanged!(value - 1) : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: enabled,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                onChanged?.call(value < count ? value + 1 : 0);
                return null;
              },
            ),
          },
          child: SizedBox(
            width: width,
            height: starSize,
            child: DrawkitSurface(
              builder: (size, options) {
                final layers = <DrawkitLayer>[];
                for (var i = 0; i < count; i++) {
                  final points = _star(i, size.width, rtl);
                  if (i < value) {
                    layers.add(
                      DrawkitLayer(Path()..addPolygon(points, true), fill),
                    );
                  }
                  layers.add(
                    DrawkitLayer(
                      doubleStroke(points, options, close: true),
                      drawkitStroke(resolved, fallbackWidth: 1.5),
                    ),
                  );
                }
                return layers;
              },
              style: resolved,
              seed: seed,
              animate: animate,
              enabled: enabled,
              resketchOnPointer: true,
              child: Row(
                children: [
                  for (var i = 0; i < count; i++)
                    SizedBox(
                      width: starSize + (i == count - 1 ? 0 : spacing),
                      height: starSize,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: enabled
                            ? () {
                                onChanged!(value == i + 1 ? i : i + 1);
                              }
                            : null,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

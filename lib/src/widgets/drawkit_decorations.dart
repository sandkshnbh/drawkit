import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// A 10px-tall rule with a pen line through its middle — `.drawably-divider`.
/// Stretches to its parent's width, like the CSS `display: block`.
class DrawkitDivider extends StatelessWidget {
  const DrawkitDivider({this.style, this.seed, this.animate = true, super.key});

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  static const double height = 10;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    return DrawkitSurface(
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
      seed: seed,
      animate: animate,
      resketchOnPointer: false,
      child: const SizedBox(height: height, width: double.infinity),
    );
  }
}

/// Sketch frame around any child with the CSS card's 16px padding.
class DrawkitCard extends StatelessWidget {
  const DrawkitCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    return DrawkitSurface(
      builder: (size, options) => [
        DrawkitLayer(
          roughRoundedRect(3, 3, size.width - 6, size.height - 6, 10, options),
          drawkitStroke(resolved),
        ),
      ],
      style: resolved,
      seed: seed,
      animate: animate,
      resketchOnPointer: false,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Small mono label in a sketched pill — `.drawably-badge`. The scribble
/// variant hatches the interior with the marker fill like the CSS
/// `--drawably-badge--scribble`.
class DrawkitBadge extends StatelessWidget {
  const DrawkitBadge({
    required this.child,
    this.variant = DrawkitBadgeVariant.outline,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget child;
  final DrawkitBadgeVariant variant;
  final EdgeInsetsGeometry padding;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    return DrawkitSurface(
      builder: (size, options) {
        final layers = <DrawkitLayer>[];
        if (variant == DrawkitBadgeVariant.scribble) {
          layers.add(
            DrawkitLayer(
              scribbleFill(4, 4, size.width - 8, size.height - 8, options),
              drawkitStroke(resolved, fallbackWidth: 1.5),
            ),
          );
        }
        layers.add(
          DrawkitLayer(
            roughRoundedRect(3, 3, size.width - 6, size.height - 6, 2, options),
            drawkitStroke(resolved),
          ),
        );
        return layers;
      },
      style: resolved,
      seed: seed,
      animate: animate,
      resketchOnPointer: false,
      child: Padding(
        padding: padding,
        child: DefaultTextStyle(
          style: DefaultTextStyle.of(context).style.copyWith(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: const [
              'Geist Mono',
              'ui-monospace',
              'monospace',
            ],
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          child: child,
        ),
      ),
    );
  }
}

enum DrawkitBadgeVariant { outline, scribble }

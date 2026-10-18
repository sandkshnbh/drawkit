import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// A sketched disc around any child — initials, a glyph, or a small image.
///
/// The circle is drawn, so it keeps the wobble the rest of the library has.
class DrawkitAvatar extends StatelessWidget {
  const DrawkitAvatar({
    this.child,
    this.size = 40,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final Widget? child;
  final double size;

  /// Announced for the whole disc; the child's own semantics are excluded.
  final String? semanticLabel;

  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _AvatarDisc(
    size: size,
    semanticLabel: semanticLabel,
    style: style,
    seed: seed,
    animate: animate,
    child: child,
  );
}

/// Overlapping row of avatars, start-edge ordered — mirrors in RTL like the
/// rest of the library. Anything past [max] collapses into a `+n` disc.
class DrawkitAvatarGroup extends StatelessWidget {
  const DrawkitAvatarGroup({
    required this.children,
    this.max = 4,
    this.overlap = 12,
    this.size = 40,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : assert(overlap < size, 'the discs must still overlap, not invert');

  final List<Widget> children;
  final int max;
  final double overlap;
  final double size;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final shown = children.length > max ? max : children.length;
    final hidden = children.length - shown;
    final discs = shown + (hidden > 0 ? 1 : 0);
    final step = size - overlap.clamp(0.0, size);
    final width = discs * step + (size - step);
    final palette = (style ?? DrawkitTheme.of(context)).palette;
    final text = TextStyle(
      fontSize: size * 0.32,
      fontWeight: FontWeight.w600,
      color: palette.ink,
      decoration: TextDecoration.none,
    );

    return Semantics(
      label:
          semanticLabel ??
          (children.length == 1 ? '1 avatar' : '${children.length} avatars'),
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown; i++)
                PositionedDirectional(
                  start: i * step,
                  child: DrawkitAvatar(
                    size: size,
                    style: style,
                    seed: seed == null ? null : seed! + i + 1,
                    animate: animate,
                    child: children[i],
                  ),
                ),
              if (hidden > 0)
                PositionedDirectional(
                  start: shown * step,
                  child: DrawkitAvatar(
                    size: size,
                    style: style,
                    seed: seed == null ? null : seed! + shown + 1,
                    animate: animate,
                    child: Text('+$hidden', style: text),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarDisc extends StatelessWidget {
  const _AvatarDisc({
    required this.size,
    required this.semanticLabel,
    required this.style,
    required this.seed,
    required this.animate,
    this.child,
  });

  final double size;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final disc = DrawkitSurface(
      builder: (size, options) {
        final cx = size.width / 2;
        final cy = size.height / 2;
        final r = (size.shortestSide - 3) / 2;
        return [
          DrawkitLayer(
            roughCircle(cx, cy, r, options),
            drawkitFillPaint(resolved.paperColor),
          ),
          DrawkitLayer(
            roughCircle(cx, cy, r, options),
            drawkitStroke(resolved, fallbackWidth: 1.5),
          ),
        ];
      },
      style: resolved,
      seed: seed,
      animate: animate,
      child: SizedBox.square(
        dimension: size,
        child: child == null ? null : Center(child: child),
      ),
    );

    if (semanticLabel == null) return disc;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(child: disc),
    );
  }
}

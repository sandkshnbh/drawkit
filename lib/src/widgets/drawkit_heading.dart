import 'package:flutter/widgets.dart';

import '../core/style.dart';
import 'drawkit_text.dart';

/// Display type: three weights of headline, optionally ruled with the pen.
///
/// [level] 1 → 28px, 2 → 22px, 3 → 18px; sizes scale the text only, the ink
/// stays the house ink.
class DrawkitHeading extends StatelessWidget {
  const DrawkitHeading({
    required this.text,
    this.level = 1,
    this.underline = false,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : assert(level >= 1 && level <= 3, 'levels are 1, 2, or 3');

  final String text;
  final int level;

  /// Draws the pen rule under the last line box (a [DrawkitUnderline]).
  final bool underline;

  final TextAlign textAlign;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  static const List<double> _sizes = [28, 22, 18];
  static const List<FontWeight> _weights = [
    FontWeight.w700,
    FontWeight.w700,
    FontWeight.w600,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = (style ?? DrawkitTheme.of(context)).palette;
    final level = this.level.clamp(1, 3);
    final textStyle = DefaultTextStyle.of(context).style
        .merge(
          TextStyle(
            fontSize: _sizes[level - 1],
            height: 1.25,
            fontWeight: _weights[level - 1],
            color: palette.ink,
            decoration: TextDecoration.none,
          ),
        )
        .merge(this.textStyle);

    return Semantics(
      header: true,
      child: underline
          ? DrawkitUnderline(
              text: text,
              textStyle: textStyle,
              textAlign: textAlign,
              style: style,
              seed: seed,
              animate: animate,
            )
          : Text(text, style: textStyle, textAlign: textAlign),
    );
  }
}

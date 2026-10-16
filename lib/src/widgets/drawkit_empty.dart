import 'package:flutter/widgets.dart';

import '../core/style.dart';
import 'drawkit_doodle.dart';

/// The friendly nothing: a faint doodle, a title, an optional message and
/// action. Drop it wherever a list, table or search result would be before
/// there is anything to show — the sketchbook equivalent of an empty margin.
///
/// The whole block is one semantic container; the title is marked as a
/// header so screen readers announce the state before any action.
class DrawkitEmpty extends StatelessWidget {
  const DrawkitEmpty({
    required this.title,
    this.doodle = DrawkitDoodleKind.squiggle,
    this.message,
    this.action,
    this.doodleSize = 56,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  /// First line, drawn in ink and marked as a header.
  final String title;

  /// Decorative shape above the title; drawn in faint ink.
  final DrawkitDoodleKind doodle;

  /// Quiet second line explaining what to do about it.
  final String? message;

  /// Optional call-to-action, typically a [DrawkitButton].
  final Widget? action;

  final double doodleSize;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final titleStyle = base.merge(
      const TextStyle(
        color: DrawkitPalette.ink,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
    final messageStyle = base.merge(
      const TextStyle(color: DrawkitPalette.inkMuted, height: 1.4),
    );

    return Semantics(
      container: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DrawkitDoodle(
              kind: doodle,
              size: doodleSize,
              color: DrawkitPalette.inkFaint,
              style: style,
              seed: seed,
              animate: animate,
            ),
            const SizedBox(height: 14),
            Semantics(header: true, child: Text(title, style: titleStyle)),
            if (message != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  message!,
                  style: messageStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

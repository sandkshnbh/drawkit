import 'package:flutter/widgets.dart';

import '../core/style.dart';
import 'drawkit_text.dart';

/// One step on a [DrawkitBreadcrumb]. Null [onTap] marks the current page —
/// it renders bolder and never announces itself as a button.
@immutable
class DrawkitBreadcrumbItem {
  const DrawkitBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// A sketched trail: tappable crumbs wear the pen underline, the current
/// page sits plain and bold, separators are muted glyphs between them.
///
/// Direction-aware — in RTL the trail starts at the right edge and the
/// separator reads inverted, like the rest of the library.
class DrawkitBreadcrumb extends StatelessWidget {
  const DrawkitBreadcrumb({
    required this.items,
    this.separator = '›',
    this.textStyle,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final List<DrawkitBreadcrumbItem> items;
  final String separator;
  final TextStyle? textStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style
        .merge(
          const TextStyle(
            color: DrawkitPalette.ink,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        )
        .merge(textStyle);

    return Semantics(
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ExcludeSemantics(
                  child: Text(
                    separator,
                    style: base.copyWith(color: DrawkitPalette.inkFaint),
                  ),
                ),
              ),
            _crumb(items[i], base: base, isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _crumb(
    DrawkitBreadcrumbItem item, {
    required TextStyle base,
    required bool isLast,
  }) {
    final tappable = item.onTap != null && !isLast;
    if (!tappable) {
      return Semantics(
        container: true,
        child: Text(
          item.label,
          style: base.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }
    return Semantics(
      button: true,
      label: item.label,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: item.onTap,
            child: DrawkitUnderline(
              text: item.label,
              textStyle: base,
              style: style,
              seed: seed,
              animate: animate,
            ),
          ),
        ),
      ),
    );
  }
}

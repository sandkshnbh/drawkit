import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
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
    return _Crumb(
      item: item,
      base: base,
      style: style,
      seed: seed,
      animate: animate,
    );
  }
}

class _Crumb extends StatefulWidget {
  const _Crumb({
    required this.item,
    required this.base,
    this.style,
    this.seed,
    this.animate = true,
  });

  final DrawkitBreadcrumbItem item;
  final TextStyle base;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<_Crumb> createState() => _CrumbState();
}

class _CrumbState extends State<_Crumb> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final resolved = widget.style ?? DrawkitTheme.of(context);
    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.item.onTap!();
            return null;
          },
        ),
      },
      mouseCursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.item.label,
        onTap: widget.item.onTap,
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: widget.item.onTap,
            child: DrawkitTapTarget(
              child: DrawkitSurface(
                builder: (size, options) => [
                  if (_focused)
                    drawkitFocusRingRect(
                      size: size,
                      radius: 8,
                      gapX: 6,
                      gapY: 4,
                      options: options,
                      style: resolved,
                    ),
                ],
                style: resolved,
                seed: widget.seed,
                animate: widget.animate,
                child: DrawkitUnderline(
                  text: widget.item.label,
                  textStyle: widget.base,
                  style: widget.style,
                  seed: widget.seed,
                  animate: widget.animate,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

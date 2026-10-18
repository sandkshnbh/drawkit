import 'package:flutter/widgets.dart';

import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';

/// One column of a [DrawkitTable]: header label, relative [flex], and where
/// its cells align (direction-resolved, so `centerStart` mirrors in RTL).
@immutable
class DrawkitTableColumn {
  const DrawkitTableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final String label;
  final int flex;
  final AlignmentGeometry alignment;
}

/// A ruled ledger: a bold header line under the column labels, faint pen
/// rules between rows, cells laid out on relative widths.
///
/// Rules are drawn with fixed seeds (nothing boils — a ledger shouldn't
/// breathe), and the whole table is direction-aware.
class DrawkitTable extends StatelessWidget {
  DrawkitTable({
    required this.columns,
    required this.rows,
    this.cellPadding = const EdgeInsetsDirectional.symmetric(
      horizontal: 10,
      vertical: 9,
    ),
    this.headerTextStyle,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  }) : assert(
         rows.every((row) => row.length == columns.length),
         'every row must have one cell per column',
       );

  final List<DrawkitTableColumn> columns;
  final List<List<Widget>> rows;
  final EdgeInsetsGeometry cellPadding;
  final TextStyle? headerTextStyle;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DrawkitTheme.of(context);
    final palette = resolved.palette;
    final ink = resolved.effectiveStroke;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cells(
          columns: columns,
          padding: cellPadding,
          children: [
            for (var i = 0; i < columns.length; i++)
              Text(
                columns[i].label,
                style: DefaultTextStyle.of(context).style
                    .merge(
                      TextStyle(
                        color: palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    )
                    .merge(headerTextStyle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        _TableRuleLine(
          seed: seed ?? 1,
          style: resolved,
          animate: animate,
          color: ink,
          width: 1.5,
        ),
        for (var r = 0; r < rows.length; r++) ...[
          _Cells(columns: columns, padding: cellPadding, children: rows[r]),
          if (r < rows.length - 1)
            _TableRuleLine(
              seed: (seed ?? 1) + r + 1,
              style: resolved,
              animate: animate,
              color: ink.withValues(alpha: 0.35),
              width: 1,
            ),
        ],
      ],
    );
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.columns,
    required this.padding,
    required this.children,
  });

  final List<DrawkitTableColumn> columns;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Padding(
      padding: padding,
      child: Row(
        mainAxisSize: constraints.hasBoundedWidth
            ? MainAxisSize.max
            : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < columns.length; i++)
            if (constraints.hasBoundedWidth)
              Expanded(
                flex: columns[i].flex,
                child: Align(
                  alignment: columns[i].alignment,
                  child: children[i],
                ),
              )
            else
              children[i],
        ],
      ),
    ),
  );
}

class _TableRuleLine extends StatelessWidget {
  const _TableRuleLine({
    required this.seed,
    required this.style,
    required this.animate,
    required this.color,
    required this.width,
  });

  final int seed;
  final DrawkitStyle style;
  final bool animate;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => DrawkitSurface(
    builder: (size, options) => [
      DrawkitLayer(
        roughLine(
          -2,
          size.height / 2,
          size.width + 2,
          size.height / 2,
          options,
        ),
        drawkitStroke(style, color: color, fallbackWidth: width),
      ),
    ],
    style: style,
    seed: seed,
    animate: animate,
    child: const SizedBox(height: 2, width: double.infinity),
  );
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart';
import 'drawkit_dialog.dart';

const List<String> _defaultMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _defaultWeekdays = [
  'Mo',
  'Tu',
  'We',
  'Th',
  'Fr',
  'Sa',
  'Su',
];

/// A hand-drawn month calendar: chevron header, weekday row, and a day grid
/// where the pick gets a shaded ball, today gets a dot, and out-of-range days
/// fade. Rows follow the ambient direction like every other widget.
///
/// Keyboard: the grid is one tab stop with a roving cursor. Arrow keys walk
/// by day (horizontal arrows follow the reading direction, crossing month
/// edges pages the calendar), PageUp/PageDown page by month, Home/End jump
/// to the first/last day, and Enter/Space picks the cursor.
///
/// Weekdays start on Monday; pass [weekdayLabels] and [monthNames] to
/// localise. Tapping a day reports it — [showDrawkitDatePicker] wraps this in
/// a dialog that pops with the picked date.
class DrawkitDatePicker extends StatefulWidget {
  const DrawkitDatePicker({
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.today,
    this.monthNames = _defaultMonths,
    this.weekdayLabels = _defaultWeekdays,
    this.semanticLabel,
    this.style,
    this.seed,
    this.animate = true,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Overridable clock input — defaults to `DateTime.now()`.
  final DateTime? today;

  final List<String> monthNames;
  final List<String> weekdayLabels;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitDatePicker> createState() => _DrawkitDatePickerState();
}

class _ShiftIntent extends Intent {
  const _ShiftIntent(this.days);

  final int days;
}

class _PageIntent extends Intent {
  const _PageIntent(this.months);

  final int months;
}

class _EdgeIntent extends Intent {
  const _EdgeIntent(this.end);

  final bool end;
}

class _DrawkitDatePickerState extends State<DrawkitDatePicker> {
  static const double _cell = 34;

  late DateTime _month;
  late DateTime _cursor;
  final FocusNode _dayNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    final anchor = widget.value ?? widget.today ?? DateTime.now();
    _month = DateTime(anchor.year, anchor.month);
    _cursor = DateTime(anchor.year, anchor.month, anchor.day);
  }

  @override
  void dispose() {
    _dayNode.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _enabled(DateTime day) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null &&
        day.isBefore(DateTime(first.year, first.month, first.day))) {
      return false;
    }
    if (last != null &&
        day.isAfter(DateTime(last.year, last.month, last.day))) {
      return false;
    }
    return true;
  }

  void _step(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  /// Moves the cursor by whole days, paging the month when it crosses an
  /// edge (so ArrowRight from the 31st lands on the 1st of the next month).
  void _shift(int days) {
    setState(() {
      _cursor = _cursor.add(Duration(days: days));
      _month = DateTime(_cursor.year, _cursor.month);
    });
  }

  /// Pages by months, keeping the day when the target month is long enough.
  void _page(int months) {
    setState(() {
      final target = DateTime(_month.year, _month.month + months);
      final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
      _month = target;
      _cursor = DateTime(
        target.year,
        target.month,
        _cursor.day.clamp(1, daysInTarget),
      );
    });
  }

  void _edge(bool end) {
    setState(() {
      final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
      _cursor = DateTime(_month.year, _month.month, end ? daysInMonth : 1);
    });
  }

  void _pickCursor() {
    if (_enabled(_cursor)) widget.onChanged(_cursor);
  }

  void _pick(DateTime date) {
    setState(() => _cursor = date);
    widget.onChanged(date);
  }

  String get _title {
    final name = widget.monthNames[(_month.month - 1) % 12];
    return '$name ${_month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final textStyle = DefaultTextStyle.of(context).style;
    final today = widget.today ?? DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final horizontal = rtl ? -1 : 1;

    return Semantics(
      label: widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              DrawkitIconButton(
                semanticLabel: 'previous month',
                size: 30,
                variant: DrawkitButtonVariant.outline,
                style: style,
                seed: widget.seed,
                animate: widget.animate,
                onPressed: () => _step(-1),
                child: const Text('‹'),
              ),
              Expanded(
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DrawkitPalette.ink,
                  ),
                ),
              ),
              DrawkitIconButton(
                semanticLabel: 'next month',
                size: 30,
                variant: DrawkitButtonVariant.outline,
                style: style,
                seed: widget.seed,
                animate: widget.animate,
                onPressed: () => _step(1),
                child: const Text('›'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final label in widget.weekdayLabels)
                SizedBox(
                  width: _cell,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textStyle.copyWith(
                      fontSize: (textStyle.fontSize ?? 14) - 2,
                      color: DrawkitPalette.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
          FocusableActionDetector(
            focusNode: _dayNode,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            shortcuts: {
              SingleActivator(LogicalKeyboardKey.arrowRight): _ShiftIntent(
                horizontal,
              ),
              SingleActivator(LogicalKeyboardKey.arrowLeft): _ShiftIntent(
                -horizontal,
              ),
              const SingleActivator(LogicalKeyboardKey.arrowDown):
                  const _ShiftIntent(7),
              const SingleActivator(LogicalKeyboardKey.arrowUp):
                  const _ShiftIntent(-7),
              const SingleActivator(LogicalKeyboardKey.pageUp):
                  const _PageIntent(-1),
              const SingleActivator(LogicalKeyboardKey.pageDown):
                  const _PageIntent(1),
              const SingleActivator(LogicalKeyboardKey.home): const _EdgeIntent(
                false,
              ),
              const SingleActivator(LogicalKeyboardKey.end): const _EdgeIntent(
                true,
              ),
              const SingleActivator(LogicalKeyboardKey.enter):
                  const ActivateIntent(),
              const SingleActivator(LogicalKeyboardKey.space):
                  const ActivateIntent(),
            },
            actions: {
              _ShiftIntent: CallbackAction<_ShiftIntent>(
                onInvoke: (intent) {
                  _shift(intent.days);
                  return null;
                },
              ),
              _PageIntent: CallbackAction<_PageIntent>(
                onInvoke: (intent) {
                  _page(intent.months);
                  return null;
                },
              ),
              _EdgeIntent: CallbackAction<_EdgeIntent>(
                onInvoke: (intent) {
                  _edge(intent.end);
                  return null;
                },
              ),
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (intent) {
                  _pickCursor();
                  return null;
                },
              ),
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var week = 0; week < rows; week++)
                  Row(
                    children: [
                      for (var slot = 0; slot < 7; slot++)
                        SizedBox(
                          width: _cell,
                          height: _cell,
                          child: _cellFor(
                            week * 7 + slot - leading + 1,
                            daysInMonth,
                            today,
                            style,
                            textStyle,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellFor(
    int day,
    int daysInMonth,
    DateTime today,
    DrawkitStyle style,
    TextStyle textStyle,
  ) {
    if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
    final date = DateTime(_month.year, _month.month, day);
    final selected = widget.value != null && _sameDay(widget.value!, date);
    final isToday = _sameDay(today, date);
    final enabled = _enabled(date);
    final cursor = _focused && _sameDay(_cursor, date);

    final text = Container(
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: textStyle.copyWith(
          color: enabled
              ? (selected ? DrawkitPalette.ink : null)
              : DrawkitPalette.inkFaint,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );

    Widget cell;
    if (!selected && !isToday) {
      cell = enabled
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pick(date),
              child: text,
            )
          : text;
    } else {
      cell = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _pick(date) : null,
        child: DrawkitSurface(
          builder: (size, options) {
            final cx = size.width / 2;
            final cy = size.height / 2;
            return [
              if (selected)
                DrawkitLayer(
                  roughCircle(cx, cy, size.width / 2 - 2, options),
                  drawkitStroke(
                    style,
                    color: style.effectiveStroke.withValues(alpha: 0.20),
                    fallbackWidth: 7,
                  ),
                ),
              if (!selected && isToday)
                DrawkitLayer(
                  roughCircle(cx, size.height - 4.5, 1.8, options),
                  drawkitFillPaint(
                    style.effectiveStroke.withValues(alpha: 0.7),
                  ),
                ),
            ];
          },
          style: style,
          seed: widget.seed,
          animate: widget.animate,
          child: text,
        ),
      );
    }

    if (!cursor) return cell;
    return DrawkitSurface(
      builder: (size, options) => [
        drawkitFocusRingRect(
          size: size,
          radius: 10,
          gapX: 2,
          gapY: 2,
          options: options,
          style: style,
        ),
      ],
      style: style,
      seed: widget.seed,
      animate: widget.animate,
      child: cell,
    );
  }
}

/// Opens a [DrawkitDatePicker] in a sketch dialog; the future completes with
/// the tapped day, or null when the dialog is dismissed.
Future<DateTime?> showDrawkitDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? today,
  List<String> monthNames = _defaultMonths,
  List<String> weekdayLabels = _defaultWeekdays,
  String semanticLabel = 'pick a date',
  DrawkitStyle? style,
  int? seed,
  bool animate = true,
}) => showDrawkitDialog<DateTime>(
  context: context,
  style: style,
  seed: seed,
  animate: animate,
  child: DrawkitDialog(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
    style: style,
    seed: seed,
    animate: animate,
    child: _DatePickerHost(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      today: today,
      monthNames: monthNames,
      weekdayLabels: weekdayLabels,
      semanticLabel: semanticLabel,
      style: style,
      seed: seed,
      animate: animate,
    ),
  ),
);

class _DatePickerHost extends StatefulWidget {
  const _DatePickerHost({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.monthNames,
    required this.weekdayLabels,
    required this.semanticLabel,
    required this.style,
    required this.seed,
    required this.animate,
  });

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? today;
  final List<String> monthNames;
  final List<String> weekdayLabels;
  final String semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<_DatePickerHost> createState() => _DatePickerHostState();
}

class _DatePickerHostState extends State<_DatePickerHost> {
  DateTime? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) => DrawkitDatePicker(
    value: _value,
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    today: widget.today,
    monthNames: widget.monthNames,
    weekdayLabels: widget.weekdayLabels,
    semanticLabel: widget.semanticLabel,
    style: widget.style,
    seed: widget.seed,
    animate: widget.animate,
    onChanged: (date) {
      setState(() => _value = date);
      Navigator.of(context).pop(date);
    },
  );
}

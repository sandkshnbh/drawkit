import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/focus.dart';
import '../core/intents.dart';
import '../core/style.dart';
import '../core/surface.dart';
import '../engine/rough.dart';
import 'drawkit_button.dart';
import 'drawkit_dialog.dart';
import 'drawkit_input.dart';

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

/// The calendar's entry surface: the month grid, or a typed `YYYY-MM-DD`
/// field (matching `showDatePicker`'s calendar/input modes).
enum DrawkitDatePickerMode { calendar, input }

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
    this.selectableDayPredicate,
    this.onDisplayedMonthChanged,
    this.headerText,
    this.footerText,
    this.entryMode = DrawkitDatePickerMode.calendar,
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

  /// Days this predicate rejects render faded and cannot be picked, on top
  /// of the [firstDate]/[lastDate] window.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// Fired when the displayed month changes (paging, arrow walks past the
  /// edge, or a typed jump).
  final ValueChanged<DateTime>? onDisplayedMonthChanged;

  /// Optional label above the calendar, and note below it.
  final String? headerText;
  final String? footerText;

  final DrawkitDatePickerMode entryMode;
  final List<String> monthNames;
  final List<String> weekdayLabels;
  final String? semanticLabel;
  final DrawkitStyle? style;
  final int? seed;
  final bool animate;

  @override
  State<DrawkitDatePicker> createState() => _DrawkitDatePickerState();
}

class _DrawkitDatePickerState extends State<DrawkitDatePicker> {
  static const double _cell = 48;

  late DateTime _month;
  late DateTime _cursor;
  late final TextEditingController _typed;
  final FocusNode _dayNode = FocusNode();
  bool _focused = false;
  String? _typedError;

  @override
  void initState() {
    super.initState();
    final anchor = _clampDate(widget.value ?? widget.today ?? DateTime.now());
    _month = DateTime(anchor.year, anchor.month);
    _cursor = DateTime(anchor.year, anchor.month, anchor.day);
    _typed = TextEditingController(text: _formatDate(widget.value));
  }

  @override
  void didUpdateWidget(DrawkitDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate) {
      _syncTo(_clampDate(_cursor));
    }
    if (widget.value != oldWidget.value && widget.value != null) {
      _syncTo(widget.value!);
      _typed.text = _formatDate(widget.value);
      _typedError = null;
    }
  }

  /// Moves the displayed month and keyboard cursor onto [date].
  void _syncTo(DateTime date) {
    final clamped = _clampDate(date);
    _month = DateTime(clamped.year, clamped.month);
    _cursor = DateTime(clamped.year, clamped.month, clamped.day);
  }

  @override
  void dispose() {
    _dayNode.dispose();
    _typed.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
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
    final predicate = widget.selectableDayPredicate;
    if (predicate != null &&
        !predicate(DateTime(day.year, day.month, day.day))) {
      return false;
    }
    return true;
  }

  void _announceMonth(DateTime before) {
    final listener = widget.onDisplayedMonthChanged;
    if (listener == null) return;
    if (before.year == _month.year && before.month == _month.month) return;
    listener(_month);
  }

  DateTime _clampDate(DateTime day) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null &&
        day.isBefore(DateTime(first.year, first.month, first.day))) {
      return DateTime(first.year, first.month, first.day);
    }
    if (last != null &&
        day.isAfter(DateTime(last.year, last.month, last.day))) {
      return DateTime(last.year, last.month, last.day);
    }
    return day;
  }

  DateTime _clampMonth(DateTime month) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null && month.isBefore(DateTime(first.year, first.month))) {
      return DateTime(first.year, first.month);
    }
    if (last != null && month.isAfter(DateTime(last.year, last.month))) {
      return DateTime(last.year, last.month);
    }
    return month;
  }

  void _step(int months) {
    final before = _month;
    setState(() {
      final target = _clampMonth(DateTime(_month.year, _month.month + months));
      final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
      _month = target;
      _cursor = DateTime(
        target.year,
        target.month,
        _cursor.day.clamp(1, daysInTarget),
      );
    });
    _announceMonth(before);
  }

  /// Moves the cursor by whole days, paging the month when it crosses an
  /// edge (so ArrowRight from the 31st lands on the 1st of the next month).
  /// The cursor never leaves the `[firstDate, lastDate]` window.
  void _shift(int days) {
    final before = _month;
    setState(() {
      _cursor = _clampDate(_cursor.add(Duration(days: days)));
      _month = DateTime(_cursor.year, _cursor.month);
    });
    _announceMonth(before);
  }

  /// Pages by months, keeping the day when the target month is long enough.
  void _page(int months) {
    final before = _month;
    setState(() {
      final target = _clampMonth(DateTime(_month.year, _month.month + months));
      final daysInTarget = DateTime(target.year, target.month + 1, 0).day;
      _month = target;
      _cursor = DateTime(
        target.year,
        target.month,
        _cursor.day.clamp(1, daysInTarget),
      );
    });
    _announceMonth(before);
  }

  void _edge(bool end) {
    setState(() {
      final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
      var day = end ? daysInMonth : 1;
      final first = widget.firstDate;
      final last = widget.lastDate;
      if (end &&
          last != null &&
          last.year == _month.year &&
          last.month == _month.month) {
        day = last.day;
      }
      if (!end &&
          first != null &&
          first.year == _month.year &&
          first.month == _month.month) {
        day = first.day;
      }
      _cursor = DateTime(_month.year, _month.month, day);
    });
  }

  void _pickCursor() {
    if (_enabled(_cursor)) widget.onChanged(_cursor);
  }

  void _pick(DateTime date) {
    setState(() => _cursor = date);
    widget.onChanged(date);
  }

  void _submitTyped(String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      setState(() => _typedError = 'use YYYY-MM-DD');
      return;
    }
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    if (!_enabled(date)) {
      setState(() => _typedError = 'not selectable');
      return;
    }
    setState(() => _typedError = null);
    widget.onChanged(date);
  }

  String get _title {
    final name = widget.monthNames[(_month.month - 1) % 12];
    return '$name ${_month.year}';
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DrawkitTheme.of(context);
    final palette = style.palette;
    final textStyle = DefaultTextStyle.of(context).style;
    final today = widget.today ?? DateTime.now();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday - 1;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final horizontal = rtl ? -1 : 1;

    if (widget.entryMode == DrawkitDatePickerMode.input) {
      return Semantics(
        label: widget.semanticLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.headerText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.headerText!,
                  style: textStyle.copyWith(color: palette.inkMuted),
                ),
              ),
            DrawkitInput(
              controller: _typed,
              autofocus: true,
              semanticLabel: widget.semanticLabel ?? 'date',
              placeholder: 'YYYY-MM-DD',
              style: widget.style,
              seed: widget.seed,
              animate: widget.animate,
              helper: widget.footerText,
              error: _typedError,
              onSubmitted: _submitTyped,
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.headerText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.headerText!,
                style: textStyle.copyWith(color: palette.inkMuted),
              ),
            ),
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
                child: Text(rtl ? '›' : '‹'),
              ),
              Expanded(
                child: Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
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
                child: Text(rtl ? '‹' : '›'),
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
                      color: palette.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
          FocusableActionDetector(
            focusNode: _dayNode,
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            shortcuts: {
              SingleActivator(LogicalKeyboardKey.arrowRight): DrawkitMoveIntent(
                horizontal,
              ),
              SingleActivator(LogicalKeyboardKey.arrowLeft): DrawkitMoveIntent(
                -horizontal,
              ),
              const SingleActivator(LogicalKeyboardKey.arrowDown):
                  const DrawkitMoveIntent(7),
              const SingleActivator(LogicalKeyboardKey.arrowUp):
                  const DrawkitMoveIntent(-7),
              const SingleActivator(LogicalKeyboardKey.pageUp):
                  const DrawkitPageIntent(-1),
              const SingleActivator(LogicalKeyboardKey.pageDown):
                  const DrawkitPageIntent(1),
              const SingleActivator(LogicalKeyboardKey.home):
                  const DrawkitEdgeIntent(false),
              const SingleActivator(LogicalKeyboardKey.end):
                  const DrawkitEdgeIntent(true),
              const SingleActivator(LogicalKeyboardKey.enter):
                  const ActivateIntent(),
              const SingleActivator(LogicalKeyboardKey.space):
                  const ActivateIntent(),
            },
            actions: {
              DrawkitMoveIntent: CallbackAction<DrawkitMoveIntent>(
                onInvoke: (intent) {
                  _shift(intent.delta);
                  return null;
                },
              ),
              DrawkitPageIntent: CallbackAction<DrawkitPageIntent>(
                onInvoke: (intent) {
                  _page(intent.months);
                  return null;
                },
              ),
              DrawkitEdgeIntent: CallbackAction<DrawkitEdgeIntent>(
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
          if (widget.footerText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.footerText!,
                style: textStyle.copyWith(
                  fontSize: (textStyle.fontSize ?? 14) - 2,
                  color: palette.inkMuted,
                ),
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
              ? (selected ? style.palette.ink : null)
              : style.palette.inkFaint,
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

    if (!cursor) return _labeledDay(date, selected, enabled, cell);
    return _labeledDay(
      date,
      selected,
      enabled,
      DrawkitSurface(
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
      ),
    );
  }

  Widget _labeledDay(DateTime date, bool selected, bool enabled, Widget cell) =>
      Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: '${widget.monthNames[(date.month - 1) % 12]} ${date.day}',
        onTap: enabled ? () => _pick(date) : null,
        child: ExcludeSemantics(child: cell),
      );
}

/// Opens a [DrawkitDatePicker] in a sketch dialog; the future completes with
/// the tapped day, or null when the dialog is dismissed.
Future<DateTime?> showDrawkitDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? today,
  bool Function(DateTime day)? selectableDayPredicate,
  ValueChanged<DateTime>? onDisplayedMonthChanged,
  String? headerText,
  String? footerText,
  DrawkitDatePickerMode initialEntryMode = DrawkitDatePickerMode.calendar,
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
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
  child: _DatePickerHost(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    today: today,
    selectableDayPredicate: selectableDayPredicate,
    onDisplayedMonthChanged: onDisplayedMonthChanged,
    headerText: headerText,
    footerText: footerText,
    initialEntryMode: initialEntryMode,
    monthNames: monthNames,
    weekdayLabels: weekdayLabels,
    semanticLabel: semanticLabel,
    style: style,
    seed: seed,
    animate: animate,
  ),
);

class _DatePickerHost extends StatefulWidget {
  const _DatePickerHost({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.today,
    required this.selectableDayPredicate,
    required this.onDisplayedMonthChanged,
    required this.headerText,
    required this.footerText,
    required this.initialEntryMode,
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
  final bool Function(DateTime day)? selectableDayPredicate;
  final ValueChanged<DateTime>? onDisplayedMonthChanged;
  final String? headerText;
  final String? footerText;
  final DrawkitDatePickerMode initialEntryMode;
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
    selectableDayPredicate: widget.selectableDayPredicate,
    onDisplayedMonthChanged: widget.onDisplayedMonthChanged,
    headerText: widget.headerText,
    footerText: widget.footerText,
    entryMode: widget.initialEntryMode,
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

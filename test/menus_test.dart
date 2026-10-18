import 'dart:ui' show CheckedState;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void _noop() {}

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      harness.host(child, direction: direction, app: true, width: 360);

  Widget routeHost(
    Widget Function(BuildContext context) home, {
    TextDirection direction = TextDirection.ltr,
  }) => harness.routeHost(home, direction: direction);

  group('DrawkitPopover', () {
    testWidgets('toggles open, and an outside tap folds it away', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DrawkitPopover(
            trigger: Text('more'),
            child: Text('panel body'),
          ),
        ),
      );
      expect(find.text('panel body'), findsNothing);

      await tester.tap(find.text('more'));
      await tester.pump();
      expect(find.text('panel body'), findsOneWidget);

      await tester.tapAt(const Offset(500, 500));
      await tester.pump();
      expect(find.text('panel body'), findsNothing);
    });

    testWidgets('keyboard activation opens it too', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitPopover(
            trigger: Text('more'),
            autofocus: true,
            child: Text('panel body'),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('panel body'), findsOneWidget);
    });
  });

  group('DrawkitMenu', () {
    testWidgets('a row fires and closes; disabled rows never fire', (
      tester,
    ) async {
      final actions = <String>[];
      await tester.pumpWidget(
        host(
          DrawkitMenu(
            items: [
              DrawkitMenuItem(
                label: 'Cut',
                hint: '⌘X',
                onSelected: () => actions.add('cut'),
              ),
              DrawkitMenuItem(
                label: 'Copy',
                onSelected: () => actions.add('copy'),
              ),
              const DrawkitMenuItem.divider(),
              const DrawkitMenuItem(label: 'Paste', enabled: false),
            ],
            child: const Text('edit'),
          ),
        ),
      );

      await tester.tap(find.text('edit'));
      await tester.pump();
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('⌘X'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pump();
      expect(actions, ['copy']);
      expect(find.text('Cut'), findsNothing);

      await tester.tap(find.text('edit'));
      await tester.pump();
      await tester.tap(find.text('Paste'), warnIfMissed: false);
      await tester.pump();
      expect(actions, ['copy']);
      expect(find.text('Paste'), findsOneWidget);
    });

    testWidgets('a checked row announces its mark', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DrawkitMenu(
            items: [
              DrawkitMenuItem(
                label: 'Ruled paper',
                checked: true,
                onSelected: _noop,
              ),
            ],
            child: const Text('view'),
          ),
        ),
      );
      await tester.tap(find.text('view'));
      await tester.pump();
      final node = tester.getSemantics(
        find
            .ancestor(
              of: find.text('Ruled paper'),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      semanticsHandle.dispose();
    });
  });

  group('DrawkitCommandPalette', () {
    const commands = [
      DrawkitCommand(label: 'Open sketch', value: 'open', hint: '⌘O'),
      DrawkitCommand(label: 'Save sketch', value: 'save', keywords: ['export']),
      DrawkitCommand(label: 'Close window', value: 'close'),
    ];

    Future<String?> openPalette(WidgetTester tester) async {
      String? result;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) => Center(
              child: DrawkitButton(
                onPressed: () async {
                  result = await showDrawkitCommandPalette<String>(
                    context: context,
                    commands: commands,
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      return result;
    }

    testWidgets('filters by label and keyword', (tester) async {
      await openPalette(tester);
      expect(find.text('Open sketch'), findsOneWidget);
      expect(find.text('Close window'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'export');
      await tester.pump();
      expect(find.text('Save sketch'), findsOneWidget);
      expect(find.text('Open sketch'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pump();
      expect(find.text('nothing matches'), findsOneWidget);
    });

    testWidgets('arrows move the pick and enter runs it', (tester) async {
      String? result;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) => Center(
              child: DrawkitButton(
                onPressed: () async {
                  result = await showDrawkitCommandPalette<String>(
                    context: context,
                    commands: commands,
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(result, 'save');
      expect(find.text('Open sketch'), findsNothing);
    });

    testWidgets('escape walks away with null', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final future = showDrawkitCommandPalette<String>(
        context: ctx,
        commands: commands,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Open sketch'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await future, isNull);
    });
  });

  group('DrawkitDatePicker', () {
    testWidgets('lays out the month and reports taps', (tester) async {
      final picked = <DateTime>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 280,
            child: DrawkitDatePicker(
              value: DateTime(2026, 10, 16),
              today: DateTime(2026, 10, 16),
              onChanged: picked.add,
            ),
          ),
        ),
      );
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);

      await tester.tap(find.text('5'));
      await tester.pump();
      expect(picked, [DateTime(2026, 10, 5)]);
    });

    testWidgets('the header steps months', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 280,
            child: DrawkitDatePicker(
              value: DateTime(2026, 10, 16),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('next month')));
      await tester.pump();
      expect(find.text('November 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp('previous month')));
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('out-of-range days ignore taps', (tester) async {
      final picked = <DateTime>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 280,
            child: DrawkitDatePicker(
              value: DateTime(2026, 10, 16),
              firstDate: DateTime(2026, 10, 10),
              lastDate: DateTime(2026, 10, 20),
              onChanged: picked.add,
            ),
          ),
        ),
      );
      await tester.tap(find.text('5'), warnIfMissed: false);
      await tester.pump();
      expect(picked, isEmpty);
      await tester.tap(find.text('12'));
      await tester.pump();
      expect(picked, [DateTime(2026, 10, 12)]);
    });

    testWidgets('the header mirrors in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 280,
            child: DrawkitDatePicker(
              value: DateTime(2026, 10, 16),
              onChanged: (_) {},
            ),
          ),
          direction: TextDirection.rtl,
        ),
      );
      final prev = tester.getCenter(
        find.bySemanticsLabel(RegExp('previous month')),
      );
      final next = tester.getCenter(
        find.bySemanticsLabel(RegExp('next month')),
      );
      expect(prev.dx, greaterThan(next.dx));
    });
  });

  group('showDrawkitDatePicker', () {
    testWidgets('pops with the tapped day', (tester) async {
      DateTime? result;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) => Center(
              child: DrawkitButton(
                onPressed: () async {
                  result = await showDrawkitDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 10, 16),
                    today: DateTime(2026, 10, 16),
                  );
                },
                child: const Text('pick'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('pick'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.text('7'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(result, DateTime(2026, 10, 7));
      expect(find.text('October 2026'), findsNothing);
    });
  });
}

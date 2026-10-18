import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // WidgetsApp installs the Tab -> NextFocusIntent shortcuts, so every host
  // here is a WidgetsApp; menus also need its TapRegionSurface.
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      WidgetsApp(
        color: DrawkitPalette.light.paper,
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              transitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
        home: Directionality(
          textDirection: direction,
          child: DrawkitTheme(
            data: const DrawkitStyle(boil: 0),
            child: Center(child: SizedBox(width: 360, child: child)),
          ),
        ),
      );

  Future<void> tab(WidgetTester tester, [int times = 1]) async {
    for (var i = 0; i < times; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
  }

  Future<void> key(WidgetTester tester, LogicalKeyboardKey which) async {
    await tester.sendKeyEvent(which);
    await tester.pump();
  }

  group('DrawkitSlider keyboard', () {
    Future<double?> slide(
      WidgetTester tester,
      List<LogicalKeyboardKey> keys, {
      TextDirection direction = TextDirection.ltr,
      double value = 0.5,
    }) async {
      double? reported;
      await tester.pumpWidget(
        host(
          DrawkitSlider(value: value, onChanged: (v) => reported = v),
          direction: direction,
        ),
      );
      await tab(tester);
      for (final which in keys) {
        await key(tester, which);
      }
      return reported;
    }

    testWidgets('Home and End jump to the ends', (tester) async {
      expect(await slide(tester, [LogicalKeyboardKey.home]), 0.0);
      expect(await slide(tester, [LogicalKeyboardKey.end]), 1.0);
    });

    testWidgets('PageUp and PageDown move five steps', (tester) async {
      expect(
        await slide(tester, [LogicalKeyboardKey.pageUp]),
        closeTo(0.75, 1e-9),
      );
      expect(
        await slide(tester, [LogicalKeyboardKey.pageDown]),
        closeTo(0.25, 1e-9),
      );
    });

    testWidgets('LTR horizontal arrows follow the screen', (tester) async {
      expect(
        await slide(tester, [LogicalKeyboardKey.arrowRight]),
        closeTo(0.55, 1e-9),
      );
      expect(
        await slide(tester, [LogicalKeyboardKey.arrowLeft]),
        closeTo(0.45, 1e-9),
      );
    });

    testWidgets('RTL flips horizontal arrows like Flutter sliders', (
      tester,
    ) async {
      expect(
        await slide(tester, [
          LogicalKeyboardKey.arrowRight,
        ], direction: TextDirection.rtl),
        closeTo(0.45, 1e-9),
      );
      expect(
        await slide(tester, [
          LogicalKeyboardKey.arrowLeft,
        ], direction: TextDirection.rtl),
        closeTo(0.55, 1e-9),
      );
    });
  });

  group('DrawkitSegmentedButton keyboard', () {
    Future<String> walk(
      WidgetTester tester,
      List<LogicalKeyboardKey> keys, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      var selected = 'a';
      late StateSetter setState;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return DrawkitSegmentedButton<String>(
                segments: const [
                  DrawkitSegment(value: 'a', label: 'one'),
                  DrawkitSegment(value: 'b', label: 'two'),
                  DrawkitSegment(value: 'c', label: 'three'),
                ],
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              );
            },
          ),
          direction: direction,
        ),
      );
      await tab(tester);
      for (final which in keys) {
        await key(tester, which);
      }
      return selected;
    }

    testWidgets('Tab lands on the selection and arrows move it', (
      tester,
    ) async {
      expect(await walk(tester, [LogicalKeyboardKey.arrowRight]), 'b');
      expect(
        await walk(tester, [
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowRight,
        ]),
        'c',
      );
    });

    testWidgets('arrows wrap and Home/End jump to the ends', (tester) async {
      expect(
        await walk(tester, [
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowRight,
        ]),
        'a',
      );
      expect(await walk(tester, [LogicalKeyboardKey.end]), 'c');
      expect(
        await walk(tester, [LogicalKeyboardKey.end, LogicalKeyboardKey.home]),
        'a',
      );
    });

    testWidgets('RTL ArrowRight walks toward the visual right', (tester) async {
      expect(
        await walk(tester, [
          LogicalKeyboardKey.arrowRight,
        ], direction: TextDirection.rtl),
        'c',
      );
    });

    testWidgets('a disabled control never takes focus', (tester) async {
      final probe = FocusNode();
      addTearDown(probe.dispose);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              const DrawkitSegmentedButton<String>(
                segments: [
                  DrawkitSegment(value: 'a', label: 'one'),
                  DrawkitSegment(value: 'b', label: 'two'),
                ],
                selected: 'a',
                onChanged: null,
              ),
              Focus(
                focusNode: probe,
                child: const SizedBox(width: 8, height: 8),
              ),
            ],
          ),
        ),
      );
      await tab(tester);
      expect(probe.hasFocus, isTrue);
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(probe.hasFocus, isTrue);
    });
  });

  group('DrawkitTabs keyboard', () {
    Future<int> walk(
      WidgetTester tester,
      List<LogicalKeyboardKey> keys, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      var active = 0;
      late StateSetter setState;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setter) {
              setState = setter;
              return DrawkitTabs(
                labels: const ['Sketch', 'Ink', 'Export'],
                active: active,
                onChanged: (i) => setState(() => active = i),
              );
            },
          ),
          direction: direction,
        ),
      );
      await tab(tester);
      for (final which in keys) {
        await key(tester, which);
      }
      return active;
    }

    testWidgets('Tab lands on the active tab; arrows activate', (tester) async {
      expect(await walk(tester, [LogicalKeyboardKey.arrowRight]), 1);
      expect(await walk(tester, [LogicalKeyboardKey.end]), 2);
      expect(await walk(tester, [LogicalKeyboardKey.arrowLeft]), 2);
    });

    testWidgets('RTL mirrors the arrow direction', (tester) async {
      expect(
        await walk(tester, [
          LogicalKeyboardKey.arrowRight,
        ], direction: TextDirection.rtl),
        2,
      );
      expect(
        await walk(tester, [
          LogicalKeyboardKey.arrowLeft,
        ], direction: TextDirection.rtl),
        1,
      );
    });
  });

  group('DrawkitBreadcrumb keyboard', () {
    testWidgets('crumbs activate with Enter and Space', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        host(
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(
                label: 'docs',
                onTap: () => taps.add('docs'),
              ),
              DrawkitBreadcrumbItem(
                label: 'guides',
                onTap: () => taps.add('guides'),
              ),
              const DrawkitBreadcrumbItem(label: 'here'),
            ],
          ),
        ),
      );
      await tab(tester);
      await key(tester, LogicalKeyboardKey.enter);
      expect(taps, ['docs']);

      await tab(tester);
      await key(tester, LogicalKeyboardKey.space);
      expect(taps, ['docs', 'guides']);
    });
  });

  group('DrawkitAccordion keyboard', () {
    testWidgets('headers toggle and Up/Down walk between them', (tester) async {
      await tester.pumpWidget(
        host(
          DrawkitAccordion(
            sections: const [
              DrawkitAccordionSection(title: 'Pens', child: Text('pen body')),
              DrawkitAccordionSection(title: 'Ink', child: Text('ink body')),
            ],
          ),
        ),
      );
      await tab(tester);
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('pen body'), findsOneWidget);
      expect(find.text('ink body'), findsNothing);

      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('ink body'), findsOneWidget);

      await key(tester, LogicalKeyboardKey.home);
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('pen body'), findsNothing);
    });
  });

  group('DrawkitNavRail keyboard', () {
    testWidgets('destinations activate with Enter', (tester) async {
      final picks = <int>[];
      await tester.pumpWidget(
        host(
          DrawkitNavRail(
            destinations: const [
              DrawkitNavDestination(label: 'Home'),
              DrawkitNavDestination(label: 'Notes'),
            ],
            selected: 0,
            onChanged: picks.add,
          ),
        ),
      );
      await tab(tester);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picks, [0]);

      await tab(tester);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picks, [0, 1]);
    });
  });

  group('DrawkitChip keyboard', () {
    testWidgets('the inner checkbox is the keyboard stop', (tester) async {
      bool? toggled;
      await tester.pumpWidget(
        host(
          DrawkitChip(
            selected: false,
            onChanged: (v) => toggled = v,
            child: const Text('tag'),
          ),
        ),
      );
      await tab(tester);
      await key(tester, LogicalKeyboardKey.space);
      expect(toggled, true);
    });
  });

  group('DrawkitPager keyboard', () {
    testWidgets('page buttons activate with Enter', (tester) async {
      final picks = <int>[];
      await tester.pumpWidget(
        host(DrawkitPager(count: 3, page: 0, onPage: picks.add)),
      );
      await tab(tester);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picks, [0]);

      await tab(tester, 2);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picks, [0, 2]);
    });
  });

  group('DrawkitMenu keyboard', () {
    Widget menu(List<DrawkitMenuItem> items, List<String> log) => host(
      DrawkitMenu(autofocus: true, items: items, child: const Text('edit')),
    );

    testWidgets('opening focuses the first row; arrows walk and pick', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        menu([
          DrawkitMenuItem(label: 'Cut', onSelected: () => log.add('cut')),
          DrawkitMenuItem(label: 'Copy', onSelected: () => log.add('copy')),
          const DrawkitMenuItem.divider(),
          DrawkitMenuItem(label: 'Paste', onSelected: () => log.add('paste')),
        ], log),
      );
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      expect(find.text('Cut'), findsOneWidget);

      await key(tester, LogicalKeyboardKey.enter);
      expect(log, ['cut']);
    });

    testWidgets('Down steps over dividers, Up wraps, End reaches the last', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        menu([
          DrawkitMenuItem(label: 'Cut', onSelected: () => log.add('cut')),
          DrawkitMenuItem(label: 'Copy', onSelected: () => log.add('copy')),
          const DrawkitMenuItem.divider(),
          DrawkitMenuItem(label: 'Paste', onSelected: () => log.add('paste')),
        ], log),
      );
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowUp);
      await key(tester, LogicalKeyboardKey.enter);
      expect(log, ['copy']);

      await key(tester, LogicalKeyboardKey.enter);
      await key(tester, LogicalKeyboardKey.arrowUp);
      await key(tester, LogicalKeyboardKey.enter);
      expect(log, ['copy', 'paste']);

      await key(tester, LogicalKeyboardKey.enter);
      await key(tester, LogicalKeyboardKey.end);
      await key(tester, LogicalKeyboardKey.home);
      await key(tester, LogicalKeyboardKey.enter);
      expect(log, ['copy', 'paste', 'cut']);
    });

    testWidgets('disabled rows are skipped', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        menu([
          DrawkitMenuItem(label: 'Cut', onSelected: () => log.add('cut')),
          const DrawkitMenuItem(label: 'Paste', enabled: false),
          DrawkitMenuItem(label: 'Undo', onSelected: () => log.add('undo')),
        ], log),
      );
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      expect(log, ['undo']);
    });

    testWidgets('Escape closes and hands focus back to the trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        menu([DrawkitMenuItem(label: 'Cut', onSelected: () {})], []),
      );
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      expect(find.text('Cut'), findsOneWidget);

      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Cut'), findsNothing);

      await key(tester, LogicalKeyboardKey.enter);
      expect(find.text('Cut'), findsOneWidget);
    });
  });

  group('DrawkitSelect keyboard', () {
    Widget select(ValueChanged<String> onChanged) => host(
      DrawkitSelect<String>(
        autofocus: true,
        options: const [
          DrawkitSelectOption(value: 'ink', label: 'Ink'),
          DrawkitSelectOption(value: 'pen', label: 'Pen'),
          DrawkitSelectOption(value: 'paper', label: 'Paper'),
        ],
        value: 'ink',
        onChanged: onChanged,
      ),
    );

    testWidgets('opening focuses the selected option; Enter picks it', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(select((v) => picked = v));
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 'ink');
    });

    testWidgets('arrows walk the options and Enter picks; focus returns', (
      tester,
    ) async {
      String? picked;
      await tester.pumpWidget(select((v) => picked = v));
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 'pen');

      // The field has focus again: Enter reopens the menu.
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Paper'), findsOneWidget);
    });

    testWidgets('Escape closes and hands focus back to the field', (
      tester,
    ) async {
      await tester.pumpWidget(select((_) {}));
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Pen'), findsNothing);

      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Pen'), findsOneWidget);
    });
  });

  group('command palette keyboard', () {
    testWidgets('Home/End move the highlight; Enter runs; focus returns', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => DrawkitButton(
              autofocus: true,
              onPressed: () async {
                result = await showDrawkitCommandPalette<String>(
                  context: context,
                  commands: const [
                    DrawkitCommand(label: 'Open', value: 'open'),
                    DrawkitCommand(label: 'Save', value: 'save'),
                    DrawkitCommand(label: 'Close', value: 'close'),
                  ],
                );
              },
              child: const Text('palette'),
            ),
          ),
        ),
      );
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Open'), findsOneWidget);

      await key(tester, LogicalKeyboardKey.end);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(result, 'close');

      // The trigger has focus again: Enter reopens the palette.
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group('DrawkitDialog keyboard', () {
    testWidgets('Escape dismisses and Tab stays trapped inside', (
      tester,
    ) async {
      var inner = 0;
      var outside = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrawkitButton(
                autofocus: true,
                onPressed: () async {
                  await showDrawkitDialog<void>(
                    context: tester.element(find.text('page button')),
                    child: DrawkitDialog(
                      child: DrawkitButton(
                        onPressed: () => inner++,
                        child: const Text('inside'),
                      ),
                    ),
                  );
                },
                child: const Text('page button'),
              ),
              DrawkitButton(
                autofocus: true,
                onPressed: () => outside++,
                child: const Text('outside button'),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await key(tester, LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('inside'), findsOneWidget);

      await tab(tester, 3);
      await key(tester, LogicalKeyboardKey.enter);
      expect(inner, greaterThan(0));
      expect(outside, 0);

      await key(tester, LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('inside'), findsNothing);
    });
  });

  group('DrawkitDatePicker keyboard', () {
    testWidgets('arrows walk the grid and Enter picks', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          DrawkitDatePicker(
            value: DateTime(2026, 6, 15),
            today: DateTime(2026, 6, 15),
            onChanged: (d) => picked = d,
          ),
        ),
      );
      await tab(tester, 3);
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picked, DateTime(2026, 6, 16));
    });

    testWidgets('crossing the month edge pages the calendar', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          DrawkitDatePicker(
            value: DateTime(2026, 6, 30),
            today: DateTime(2026, 6, 30),
            onChanged: (d) => picked = d,
          ),
        ),
      );
      await tab(tester, 3);
      expect(find.text('June 2026'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(find.text('July 2026'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picked, DateTime(2026, 7, 1));
    });

    testWidgets('PageUp/PageDown page months and Home/End jump days', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          DrawkitDatePicker(
            value: DateTime(2026, 6, 15),
            today: DateTime(2026, 6, 15),
            onChanged: (d) => picked = d,
          ),
        ),
      );
      await tab(tester, 3);
      await key(tester, LogicalKeyboardKey.pageDown);
      expect(find.text('July 2026'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.pageUp);
      expect(find.text('June 2026'), findsOneWidget);

      await key(tester, LogicalKeyboardKey.end);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picked, DateTime(2026, 6, 30));

      await key(tester, LogicalKeyboardKey.home);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picked, DateTime(2026, 6, 1));
    });

    testWidgets('RTL mirrors the horizontal arrows', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        host(
          DrawkitDatePicker(
            value: DateTime(2026, 6, 15),
            today: DateTime(2026, 6, 15),
            onChanged: (d) => picked = d,
          ),
          direction: TextDirection.rtl,
        ),
      );
      await tab(tester, 3);
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.enter);
      expect(picked, DateTime(2026, 6, 14));
    });
  });
}

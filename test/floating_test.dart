import 'dart:ui' show Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  // WidgetsApp gives us the Tab shortcuts and the TapRegionSurface the FAB
  // menu leans on for outside taps.
  Widget host(
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    bool disableAnimations = false,
  }) => harness.host(
    child,
    direction: direction,
    disableAnimations: disableAnimations,
    app: true,
    width: 360,
  );

  const destinations = [
    DrawkitNavDestination(label: 'Inbox', icon: Text('✉'), badge: 3),
    DrawkitNavDestination(label: 'Drafts', icon: Text('✎')),
    DrawkitNavDestination(label: 'Archive', icon: Text('▤')),
  ];

  group('DrawkitFloatingNavBar', () {
    testWidgets('picks destinations on tap', (tester) async {
      var picked = 0;
      await tester.pumpWidget(
        host(
          DrawkitFloatingNavBar(
            destinations: destinations,
            selected: 0,
            onChanged: (i) => picked = i,
          ),
        ),
      );
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);

      await tester.tap(find.text('Archive'));
      await tester.pump();
      expect(picked, 2);
    });

    testWidgets('announces selection and badge count', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DrawkitFloatingNavBar(
            destinations: destinations,
            selected: 0,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Inbox, 3 notifications'), findsOneWidget);
      final node = tester.getSemantics(
        find.bySemanticsLabel('Inbox, 3 notifications'),
      );
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('flexible mode opens only the pick into a label', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitFloatingNavBar(
              destinations: destinations,
              selected: selected,
              showLabels: false,
              onChanged: (i) => setState(() => selected = i),
            ),
          ),
        ),
      );
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Drafts'), findsNothing);

      await tester.tap(find.text('✎'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('Inbox'), findsNothing);
    });

    testWidgets('keyboard walks in and activates with Enter', (tester) async {
      var picked = -1;
      await tester.pumpWidget(
        host(
          DrawkitFloatingNavBar(
            destinations: destinations,
            selected: 0,
            onChanged: (i) => picked = i,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, 1);
    });

    testWidgets('mirrors in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          DrawkitFloatingNavBar(
            destinations: destinations,
            selected: 0,
            onChanged: (_) {},
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getCenter(find.text('Inbox')).dx,
        greaterThan(tester.getCenter(find.text('Archive')).dx),
      );
    });

    testWidgets('tucks away on scroll down and slides back on scroll up', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 30,
                  itemBuilder: (context, i) =>
                      SizedBox(height: 40, child: Text('row $i')),
                ),
              ),
              DrawkitFloatingNavBar(
                destinations: destinations,
                selected: 0,
                onChanged: (_) {},
                hideOnScroll: true,
                scrollController: controller,
              ),
            ],
          ),
        ),
      );
      final resting = tester.getTopLeft(find.text('Inbox')).dy;

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final hidden = tester.getTopLeft(find.text('Inbox')).dy;
      expect(hidden, greaterThan(resting + 50));

      await tester.drag(find.byType(ListView), const Offset(0, 80));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getTopLeft(find.text('Inbox')).dy, closeTo(resting, 1));
    });

    testWidgets('reduced motion snaps the tuck in place', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 30,
                  itemBuilder: (context, i) =>
                      SizedBox(height: 40, child: Text('row $i')),
                ),
              ),
              DrawkitFloatingNavBar(
                destinations: destinations,
                selected: 0,
                onChanged: (_) {},
                hideOnScroll: true,
                scrollController: controller,
              ),
            ],
          ),
          disableAnimations: true,
        ),
      );
      final resting = tester.getTopLeft(find.text('Inbox')).dy;

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('Inbox')).dy,
        greaterThan(resting + 50),
      );
    });
  });

  group('DrawkitFabMenu', () {
    const items = [
      DrawkitFabMenuItem(label: 'New note', onPressed: _noop),
      DrawkitFabMenuItem(label: 'New sketch', onPressed: _noop),
      DrawkitFabMenuItem(label: 'Import', onPressed: _noop),
    ];

    testWidgets('unfolds items on tap, picks one, folds back', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        host(
          DrawkitFabMenu(
            semanticLabel: 'new',
            items: [
              const DrawkitFabMenuItem(label: 'New note', onPressed: _noop),
              DrawkitFabMenuItem(
                label: 'Import',
                onPressed: () => pressed = true,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Import'), findsNothing);

      await tester.tap(find.text('＋'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New note'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);

      await tester.tap(find.text('Import'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(pressed, isTrue);
      expect(find.text('Import'), findsNothing);
    });

    testWidgets('Escape folds back and returns focus to the circle', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const DrawkitFabMenu(semanticLabel: 'new', items: items)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'drawkit fab menu trigger',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'drawkit fab menu item 0',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New note'), findsNothing);
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'drawkit fab menu trigger',
      );
    });

    testWidgets('Enter on a focused item runs it', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        host(
          DrawkitFabMenu(
            semanticLabel: 'new',
            items: [
              DrawkitFabMenuItem(
                label: 'New note',
                onPressed: () => pressed = true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('＋'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 300));
      expect(pressed, isTrue);
      expect(find.text('New note'), findsNothing);
    });

    testWidgets('a tap outside folds it away', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitFabMenu(semanticLabel: 'new', items: items)),
      );
      await tester.tap(find.text('＋'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New note'), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New note'), findsNothing);
    });
  });
}

void _noop() {}

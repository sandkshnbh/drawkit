import 'dart:ui' show Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      harness.host(child, direction: direction, width: 360);

  const destinations = [
    DrawkitNavDestination(label: 'Inbox', icon: Text('✉')),
    DrawkitNavDestination(label: 'Drafts', icon: Text('✎')),
    DrawkitNavDestination(label: 'Archive', icon: Text('▤')),
  ];

  group('DrawkitAppBar', () {
    testWidgets('lays out leading, title, and actions', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitAppBar(
            leading: Text('←'),
            title: Text('Sketchbook'),
            actions: [Text('save'), Text('more')],
          ),
        ),
      );
      expect(find.text('←'), findsOneWidget);
      expect(find.text('Sketchbook'), findsOneWidget);
      expect(find.text('save'), findsOneWidget);
      expect(find.text('more'), findsOneWidget);
      expect(tester.getSize(find.byType(DrawkitAppBar)).height, 56);
      expect(
        tester.getTopLeft(find.text('←')).dx <
            tester.getTopLeft(find.text('Sketchbook')).dx,
        isTrue,
      );
    });

    testWidgets('announces itself as a header', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DrawkitAppBar(title: Text('Sketchbook'))),
      );
      final node = tester.getSemantics(find.byType(DrawkitAppBar));
      expect(node.flagsCollection.isHeader, isTrue);
      semanticsHandle.dispose();
    });

    testWidgets('mirrors in RTL: actions gather at the left', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitAppBar(
            leading: Text('←'),
            title: Text('Sketchbook'),
            actions: [Text('save')],
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getTopLeft(find.text('←')).dx >
            tester.getTopLeft(find.text('Sketchbook')).dx,
        isTrue,
      );
      expect(
        tester.getTopLeft(find.text('save')).dx <
            tester.getTopLeft(find.text('Sketchbook')).dx,
        isTrue,
      );
    });
  });

  group('DrawkitNavRail', () {
    testWidgets('stacks destinations top down and reports picks', (
      tester,
    ) async {
      final picked = <int>[];
      await tester.pumpWidget(
        host(
          DrawkitNavRail(
            destinations: destinations,
            selected: 0,
            onChanged: picked.add,
          ),
        ),
      );
      expect(find.text('Inbox'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Inbox')).dy <
            tester.getTopLeft(find.text('Drafts')).dy,
        isTrue,
      );
      await tester.tap(find.text('Archive'));
      await tester.pump();
      expect(picked, [2]);
    });

    testWidgets('announces the selected stop', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DrawkitNavRail(
            destinations: destinations,
            selected: 1,
            onChanged: _noopInt,
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Drafts'));
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Inbox'))
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      semanticsHandle.dispose();
    });

    testWidgets('a null onChanged disables the rail', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitNavRail(
            destinations: destinations,
            selected: 0,
            onChanged: null,
          ),
        ),
      );
      await tester.tap(find.text('Inbox'));
      await tester.pump();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Inbox'))
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );
    });
  });

  group('DrawkitBottomNav', () {
    testWidgets('spreads destinations start to end', (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        host(
          DrawkitBottomNav(
            destinations: destinations,
            selected: 0,
            onChanged: picked.add,
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Inbox')).dx <
            tester.getTopLeft(find.text('Drafts')).dx,
        isTrue,
      );
      expect(
        tester.getTopLeft(find.text('Drafts')).dx <
            tester.getTopLeft(find.text('Archive')).dx,
        isTrue,
      );
      await tester.tap(find.text('Drafts'));
      await tester.pump();
      expect(picked, [1]);
    });

    testWidgets('mirrors in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          DrawkitBottomNav(
            destinations: destinations,
            selected: 0,
            onChanged: _noopInt,
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getTopLeft(find.text('Inbox')).dx >
            tester.getTopLeft(find.text('Archive')).dx,
        isTrue,
      );
    });
  });

  group('DrawkitBreadcrumb', () {
    testWidgets('renders crumbs with separators between them', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        host(
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(label: 'Sketchbook', onTap: () => opened++),
              DrawkitBreadcrumbItem(label: 'Pencils', onTap: () => opened++),
              const DrawkitBreadcrumbItem(label: 'HB'),
            ],
          ),
        ),
      );
      expect(find.text('Sketchbook'), findsOneWidget);
      expect(find.text('HB'), findsOneWidget);
      expect(find.text('›'), findsNWidgets(2));
      await tester.tap(find.text('Sketchbook'));
      await tester.pump();
      expect(opened, 1);
    });

    testWidgets('the current page is not a button', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(label: 'Sketchbook', onTap: _noop),
              const DrawkitBreadcrumbItem(label: 'HB'),
            ],
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Sketchbook'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('HB'))
            .flagsCollection
            .isButton,
        isFalse,
      );
      semanticsHandle.dispose();
    });

    testWidgets('mirrors in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(label: 'Sketchbook', onTap: _noop),
              const DrawkitBreadcrumbItem(label: 'HB'),
            ],
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getTopLeft(find.text('Sketchbook')).dx >
            tester.getTopLeft(find.text('HB')).dx,
        isTrue,
      );
    });
  });

  group('DrawkitTable', () {
    Widget table() => DrawkitTable(
      columns: const [
        DrawkitTableColumn(label: 'Pencil', flex: 2),
        DrawkitTableColumn(label: 'Qty'),
        DrawkitTableColumn(label: 'Total'),
      ],
      rows: const [
        [Text('HB'), Text('12'), Text('\$1.20')],
        [Text('2B'), Text('3'), Text('\$0.60')],
      ],
    );

    testWidgets('lays out a flex-weighted ledger', (tester) async {
      await tester.pumpWidget(host(table()));
      final tableLeft = tester.getTopLeft(find.text('Pencil')).dx;
      expect(
        tester.widget<Text>(find.text('Pencil')).style!.fontWeight,
        FontWeight.w600,
      );
      final qty = tester.getTopLeft(find.text('Qty')).dx;
      final total = tester.getTopLeft(find.text('Total')).dx;
      expect(tableLeft < qty, isTrue);
      expect(qty < total, isTrue);
      final width = tester.getSize(find.byType(DrawkitTable)).width - 20;
      expect(qty - tableLeft, closeTo(width * 2 / 4, 1));
      expect(total - qty, closeTo(width / 4, 1));
    });

    testWidgets('draws a rule under the header and between rows', (
      tester,
    ) async {
      await tester.pumpWidget(host(table()));
      expect(
        find.descendant(
          of: find.byType(DrawkitTable),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('mirrors its columns in RTL', (tester) async {
      await tester.pumpWidget(host(table(), direction: TextDirection.rtl));
      expect(
        tester.getTopLeft(find.text('Pencil')).dx >
            tester.getTopLeft(find.text('Total')).dx,
        isTrue,
      );
    });

    testWidgets('rejects rows that do not match the columns', (tester) async {
      expect(
        () => DrawkitTable(
          columns: const [DrawkitTableColumn(label: 'A')],
          rows: const [
            [Text('a'), Text('extra')],
          ],
        ),
        throwsAssertionError,
      );
    });
  });
}

void _noop() {}
void _noopInt(int _) {}

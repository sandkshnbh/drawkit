import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: DrawkitTheme(
        data: const DrawkitStyle(boil: 0),
        child: SizedBox(width: 360, child: child),
      ),
    ),
  );

  group('DrawkitChip', () {
    testWidgets('tap flips through onChanged and the checkbox follows', (
      tester,
    ) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitChip(
              selected: seen.isNotEmpty && seen.last,
              onChanged: (v) => setState(() => seen.add(v)),
              child: const Text('dashed'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('dashed'));
      expect(seen, [true]);
    });
  });

  group('DrawkitTabs', () {
    testWidgets('tapping a tab reports its index', (tester) async {
      final seen = <int>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitTabs(
              labels: const ['one', 'two', 'three'],
              active: 0,
              onChanged: (i) => setState(() => seen.add(i)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('two'));
      expect(seen, [1]);
    });
  });

  group('DrawkitAlert', () {
    testWidgets('shows tag and body', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitAlert(
            tag: Text('warn'),
            child: Text('the pen ran out of ink'),
          ),
        ),
      );
      expect(find.text('warn'), findsOneWidget);
      expect(find.text('the pen ran out of ink'), findsOneWidget);
    });
  });

  group('DrawkitKbd', () {
    testWidgets('renders the key', (tester) async {
      await tester.pumpWidget(host(const DrawkitKbd(child: Text('⌘K'))));
      expect(find.text('⌘K'), findsOneWidget);
    });
  });

  group('DrawkitQuote', () {
    testWidgets('highlights the line and rules the footer', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitQuote(
            text: 'draw the rest of the owl',
            footer: Text('— the internet'),
          ),
        ),
      );
      expect(find.text('draw the rest of the owl'), findsOneWidget);
      expect(find.text('— the internet'), findsOneWidget);
    });

    testWidgets('the footer rule sits above the attribution, spanning the '
        'quote', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitQuote(
            seed: 1,
            text: 'draw the rest of the owl',
            footer: Text('— the internet'),
          ),
        ),
      );
      final band = tester.getRect(find.byType(DrawkitSurface).last);
      final attribution = tester.getRect(find.text('— the internet'));
      expect(band.height, 10);
      expect(band.width, 360);
      expect(band.bottom, lessThanOrEqualTo(attribution.top + 2));
      expect(band.top + 5, lessThan(attribution.top));
    });
  });

  group('DrawkitSteps', () {
    testWidgets('draws a check per step', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitSteps(
            children: [Text('open the box'), Text('find the pen')],
          ),
        ),
      );
      expect(find.byType(DrawkitSurface), findsNWidgets(2));
    });
  });

  group('DrawkitPager', () {
    testWidgets('reports the page and marks it selected', (tester) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitPager(
              count: 4,
              page: 0,
              onPage: (i) => setState(() => seen.add(i)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('3'));
      expect(seen, [2]);
      handle.dispose();
    });
  });

  group('DrawkitArrow', () {
    testWidgets('requires two anchors and paints between them', (tester) async {
      final from = GlobalKey();
      final to = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DrawkitTheme(
            data: const DrawkitStyle(boil: 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(key: from, width: 40, height: 40),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(key: to, width: 40, height: 40),
                ),
                Positioned.fill(
                  child: DrawkitArrow(from: from, to: to),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DrawkitArrow), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tooltip wraps a card and points at its target', (
      tester,
    ) async {
      final target = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DrawkitTheme(
            data: const DrawkitStyle(boil: 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: DrawkitTooltip(
                    target: target,
                    child: const Text('this way!'),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: 120,
                  child: SizedBox(key: target, width: 30, height: 30),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('this way!'), findsOneWidget);
      expect(find.byType(DrawkitArrow), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    Widget child, {
    TextDirection direction = TextDirection.rtl,
    bool overlay = false,
  }) => Directionality(
    textDirection: direction,
    child: DrawkitTheme(
      data: const DrawkitStyle(boil: 0),
      child: overlay
          ? Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) => Center(child: child)),
              ],
            )
          : Center(child: child),
    ),
  );

  DrawkitLayer toggleTravelLayer(WidgetTester tester) {
    final surface = tester.widget<DrawkitSurface>(find.byType(DrawkitSurface));
    final layers = surface.builder(
      DrawkitToggle.size,
      const RoughOptions(seed: 11),
    );
    return layers.firstWhere((layer) => layer.matrix != null);
  }

  group('DrawkitToggle', () {
    testWidgets('RTL rests the knob right and travels left when on', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const DrawkitToggle(value: false, onChanged: _noopBool)),
      );
      expect(toggleTravelLayer(tester).matrix!().getTranslation().x, 20);

      await tester.pumpWidget(
        host(const DrawkitToggle(value: true, onChanged: _noopBool)),
      );
      await tester.pumpAndSettle();
      expect(toggleTravelLayer(tester).matrix!().getTranslation().x, 0);
    });

    testWidgets('LTR keeps the knob left and travels right when on', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const DrawkitToggle(value: false, onChanged: _noopBool),
          direction: TextDirection.ltr,
        ),
      );
      expect(toggleTravelLayer(tester).matrix!().getTranslation().x, 0);

      await tester.pumpWidget(
        host(
          const DrawkitToggle(value: true, onChanged: _noopBool),
          direction: TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      expect(toggleTravelLayer(tester).matrix!().getTranslation().x, 20);
    });
  });

  group('DrawkitList', () {
    Rect markerBounds(WidgetTester tester) {
      final surface = tester.widget<DrawkitSurface>(
        find.byType(DrawkitSurface).first,
      );
      final layers = surface.builder(
        const Size(80, 22),
        const RoughOptions(seed: 21),
      );
      return layers.single.path.getBounds();
    }

    testWidgets('RTL moves the gutter right and mirrors the marker', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DrawkitList(children: [Text('one'), Text('two')]),
          ),
        ),
      );
      final listRect = tester.getRect(find.byType(DrawkitList));
      final textRect = tester.getRect(find.text('one'));
      expect(listRect.right - textRect.right, closeTo(24, 0.01));

      final bounds = markerBounds(tester);
      expect(bounds.left, closeTo(88, 2));
      expect(bounds.right, closeTo(98, 2));
    });

    testWidgets('LTR keeps the gutter left and the marker negative', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DrawkitList(children: [Text('one'), Text('two')]),
          ),
          direction: TextDirection.ltr,
        ),
      );
      final listRect = tester.getRect(find.byType(DrawkitList));
      final textRect = tester.getRect(find.text('one'));
      expect(textRect.left - listRect.left, closeTo(24, 0.01));

      final bounds = markerBounds(tester);
      expect(bounds.left, closeTo(-18, 2));
      expect(bounds.right, closeTo(-8, 2));
    });
  });

  group('DrawkitChip', () {
    testWidgets('padding resolves and the check sits at the start', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DrawkitChip(
            selected: true,
            onChanged: _noopBool,
            child: const Text('x'),
          ),
        ),
      );
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(DrawkitBadge),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding.resolve(TextDirection.rtl),
        const EdgeInsets.fromLTRB(10, 3, 6, 3),
      );
      expect(
        tester.getCenter(find.byType(DrawkitCheckbox)).dx,
        greaterThan(tester.getCenter(find.text('x')).dx),
      );
    });

    testWidgets('LTR resolves to the original left-to-right padding', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DrawkitChip(
            selected: true,
            onChanged: _noopBool,
            child: const Text('x'),
          ),
          direction: TextDirection.ltr,
        ),
      );
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(DrawkitBadge),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding.resolve(TextDirection.ltr),
        const EdgeInsets.fromLTRB(6, 3, 10, 3),
      );
      expect(
        tester.getCenter(find.byType(DrawkitCheckbox)).dx,
        lessThan(tester.getCenter(find.text('x')).dx),
      );
    });
  });

  group('Rows', () {
    testWidgets('tabs lay out right-to-left in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          DrawkitTabs(
            labels: const ['one', 'two'],
            active: 0,
            onChanged: _noopInt,
          ),
        ),
      );
      expect(
        tester.getCenter(find.text('one')).dx,
        greaterThan(tester.getCenter(find.text('two')).dx),
      );
    });

    testWidgets('pager lays out right-to-left in RTL', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitPager(count: 2, page: 0, onPage: _noopInt)),
      );
      expect(
        tester.getCenter(find.text('1')).dx,
        greaterThan(tester.getCenter(find.text('2')).dx),
      );
    });
  });

  group('DrawkitSelect', () {
    const options = [
      DrawkitSelectOption(value: 'a', label: 'Alpha'),
      DrawkitSelectOption(value: 'b', label: 'Beta'),
    ];

    testWidgets('RTL puts the chevron left and pads the text from the right', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DrawkitSelect<String>(
              options: options,
              value: null,
              onChanged: _noopString,
            ),
          ),
          overlay: true,
        ),
      );
      final surface = tester.widget<DrawkitSurface>(
        find.byType(DrawkitSurface).first,
      );
      final layers = surface.builder(
        const Size(160, 36),
        const RoughOptions(seed: 31),
      );
      expect(layers[1].path.getBounds().right, lessThan(80));

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(DrawkitSurface).first,
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding.resolve(TextDirection.rtl),
        const EdgeInsets.only(left: 34, right: 12, top: 8, bottom: 8),
      );
    });

    testWidgets('RTL aligns the open panel to the anchor right edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DrawkitSelect<String>(
              options: options,
              value: null,
              onChanged: _noopString,
            ),
          ),
          overlay: true,
        ),
      );
      await tester.tap(find.byType(DrawkitSelect<String>));
      await tester.pumpAndSettle();
      final selectRect = tester.getRect(find.byType(DrawkitSelect<String>));
      final panelRect = tester.getRect(
        find.descendant(
          of: find.byType(CustomSingleChildLayout),
          matching: find.byType(DrawkitSurface),
        ),
      );
      expect(panelRect.right, closeTo(selectRect.right, 0.5));
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('LTR keeps the chevron right and the panel left-aligned', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DrawkitSelect<String>(
              options: options,
              value: null,
              onChanged: _noopString,
            ),
          ),
          direction: TextDirection.ltr,
          overlay: true,
        ),
      );
      final surface = tester.widget<DrawkitSurface>(
        find.byType(DrawkitSurface).first,
      );
      final layers = surface.builder(
        const Size(160, 36),
        const RoughOptions(seed: 31),
      );
      expect(layers[1].path.getBounds().left, greaterThan(80));

      await tester.tap(find.byType(DrawkitSelect<String>));
      await tester.pumpAndSettle();
      final selectRect = tester.getRect(find.byType(DrawkitSelect<String>));
      final panelRect = tester.getRect(
        find.descendant(
          of: find.byType(CustomSingleChildLayout),
          matching: find.byType(DrawkitSurface),
        ),
      );
      expect(panelRect.left, closeTo(selectRect.left, 0.5));
    });
  });

  group('Text chrome', () {
    testWidgets('follows the ambient RTL direction', (tester) async {
      await tester.pumpWidget(
        host(const Center(child: DrawkitUnderline(text: 'مرحبا بالعالم'))),
      );
      final text = tester.widget<Text>(find.text('مرحبا بالعالم'));
      expect(text.textDirection, TextDirection.rtl);

      final surface = tester.widget<DrawkitSurface>(
        find.byType(DrawkitSurface),
      );
      final layers = surface.builder(
        const Size(120, 20),
        const RoughOptions(seed: 41),
      );
      expect(layers, isNotEmpty);
    });
  });
}

void _noopBool(bool _) {}
void _noopInt(int _) {}
void _noopString(String _) {}

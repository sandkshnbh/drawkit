import 'package:drawkit/drawkit.dart';
import 'package:drawkit_gallery/main.dart' show DrawkitGalleryApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const DrawkitGalleryApp());
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('gallery boots into the surface page', (tester) async {
    await boot(tester);
    expect(find.text('drawkit'), findsOneWidget);
    expect(find.text('Surface'), findsWidgets);
  });

  testWidgets('sidebar selection switches pages', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Buttons'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text(
        'Variants, states, tones — plus icon buttons, the floating pen, '
        'and the fab menu.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the RTL toggle flips the gallery direction', (tester) async {
    await boot(tester);
    TextDirection direction() =>
        Directionality.of(tester.element(find.text('drawkit')));
    expect(direction(), TextDirection.ltr);
    await tester.tap(find.byType(DrawkitToggle).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(direction(), TextDirection.rtl);
  });

  testWidgets('the dark toggle swaps the palette', (tester) async {
    await boot(tester);
    DrawkitPalette palette() => tester
        .widget<DrawkitTheme>(find.byType(DrawkitTheme).first)
        .data
        .palette;
    expect(palette(), DrawkitPalette.light);
    await tester.tap(find.byType(DrawkitToggle).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(palette(), DrawkitPalette.dark);
  });
}

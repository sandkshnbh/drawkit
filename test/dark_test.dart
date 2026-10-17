import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_sample.dart';

void main() {
  test('the light preset keeps the CSS values', () {
    expect(DrawkitPalette.light.pen, const Color(0xFF2724D1));
    expect(DrawkitPalette.light.paper, const Color(0xFFE3E3E1));
    expect(DrawkitPalette.light.surface, const Color(0xFFFFFFFF));
    expect(DrawkitPalette.light.error, const Color(0xFFD12724));
    expect(DrawkitPalette.light.success, const Color(0xFF188A42));
    expect(DrawkitPalette.light.neutral, const Color(0xFF6E675F));
    expect(DrawkitPalette.light.ink, const Color(0xFF18181B));
    expect(DrawkitPalette.light.inkMuted, const Color(0xFF474645));
    expect(DrawkitPalette.light.inkFaint, const Color(0xFFA1A1AA));
  });

  test('style defaults stay on the light preset', () {
    const style = DrawkitStyle();
    expect(style.palette, DrawkitPalette.light);
    expect(style.strokeColor, DrawkitPalette.light.pen);
    expect(style.paperColor, DrawkitPalette.light.surface);
    expect(DrawkitPalette.light.style.strokeColor, DrawkitPalette.light.pen);
    expect(DrawkitPalette.light.style.paperColor, DrawkitPalette.light.surface);
    expect(DrawkitPalette.dark.style.paperColor, DrawkitPalette.dark.surface);
  });

  test('the dark ink clears AA on its papers', () {
    final palette = DrawkitPalette.dark;
    for (final ink in [palette.ink, palette.inkMuted]) {
      expect(drawkitContrast(ink, palette.paper), greaterThanOrEqualTo(4.5));
      expect(drawkitContrast(ink, palette.surface), greaterThanOrEqualTo(4.5));
    }
    expect(drawkitContrast(palette.inkFaint, palette.surface), greaterThan(3));
    for (final tone in [palette.error, palette.success, palette.neutral]) {
      expect(drawkitContrast(tone, palette.paper), greaterThanOrEqualTo(4.5));
    }
    expect(drawkitContrast(palette.pen, palette.paper), greaterThan(3));
  });

  test('drawkitReadableInk darkens on the paper and lightens on the ink', () {
    final lightened = drawkitReadableInk(
      DrawkitPalette.dark.neutral,
      DrawkitPalette.dark.paper,
    );
    expect(
      drawkitContrast(lightened, DrawkitPalette.dark.paper),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      lightened.computeLuminance(),
      greaterThanOrEqualTo(DrawkitPalette.dark.neutral.computeLuminance()),
    );

    final darkened = drawkitReadableInk(
      DrawkitPalette.light.error,
      DrawkitPalette.light.paper,
    );
    expect(
      drawkitContrast(darkened, DrawkitPalette.light.paper),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      darkened.computeLuminance(),
      lessThanOrEqualTo(DrawkitPalette.light.error.computeLuminance()),
    );

    expect(
      drawkitReadableInk(DrawkitPalette.light.ink, DrawkitPalette.light.paper),
      DrawkitPalette.light.ink,
    );
  });

  testWidgets('a dark theme re-inks text and chrome from the palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      a11yHost(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DrawkitHeading(level: 1, text: 'Night ink'),
            DrawkitButton(onPressed: () {}, child: const Text('draw')),
          ],
        ),
        palette: DrawkitPalette.dark,
      ),
    );
    await tester.pump();

    final heading = tester.widget<Text>(find.text('Night ink'));
    expect(heading.style?.color, DrawkitPalette.dark.ink);

    final surface = tester.widget<DrawkitSurface>(
      find.byType(DrawkitSurface).first,
    );
    final layers = surface.builder(
      const Size(200, 60),
      const RoughOptions(seed: 1),
    );
    expect(
      layers.first.paint.color.toARGB32(),
      DrawkitPalette.dark.pen.toARGB32(),
    );
  });

  testWidgets('the dark sample meets the Android tap target guideline', (
    tester,
  ) async {
    final semantics = await pumpA11ySample(
      tester,
      palette: DrawkitPalette.dark,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('the dark sample meets the iOS tap target guideline', (
    tester,
  ) async {
    final semantics = await pumpA11ySample(
      tester,
      palette: DrawkitPalette.dark,
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('the dark sample labels every tappable control', (tester) async {
    final semantics = await pumpA11ySample(
      tester,
      palette: DrawkitPalette.dark,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('the dark sample keeps WCAG contrast on the ink paper', (
    tester,
  ) async {
    final semantics = await pumpA11ySample(
      tester,
      palette: DrawkitPalette.dark,
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}

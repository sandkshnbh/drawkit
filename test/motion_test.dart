import 'dart:ui' as ui;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {bool disableAnimations = false}) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Center(child: child),
    ),
  );

  DrawkitSurface surface({int seed = 7}) => DrawkitSurface(
    seed: seed,
    animate: false,
    builder: (size, options) => [
      DrawkitLayer(
        roughLine(0, size.height / 2, size.width, size.height / 2, options),
        drawkitStroke(const DrawkitStyle(), fallbackWidth: 2),
      ),
    ],
    child: const SizedBox(width: 100, height: 20),
  );

  Future<int> inkOf(WidgetTester tester, Finder surfaceFinder) async {
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: surfaceFinder,
            matching: find.byType(CustomPaint),
          ),
        )
        .painter!;
    final size = tester.getSize(surfaceFinder);
    final recorder = ui.PictureRecorder();
    painter.paint(ui.Canvas(recorder), size);
    final image = await tester.runAsync(
      () => recorder.endRecording().toImage(
        size.width.ceil(),
        size.height.ceil(),
      ),
    );
    final pixels = (await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!.buffer.asUint8List();
    var ink = 0;
    for (var i = 3; i < pixels.length; i += 4) {
      if (pixels[i] > 0) ink++;
    }
    image!.dispose();
    return ink;
  }

  Finder firstSurface() => find.byType(DrawkitSurface).at(0);

  group('DrawkitSketchIn', () {
    testWidgets('traces from nothing to the full sketch without rebuilding', (
      tester,
    ) async {
      await tester.pumpWidget(host(surface()));
      final full = await inkOf(tester, firstSurface());
      expect(full, greaterThan(0));

      await tester.pumpWidget(
        host(
          DrawkitSketchIn(
            duration: const Duration(milliseconds: 600),
            curve: Curves.linear,
            child: surface(),
          ),
        ),
      );
      expect(await inkOf(tester, firstSurface()), 0);

      await tester.pump(const Duration(milliseconds: 300));
      final mid = await inkOf(tester, firstSurface());
      expect(mid, greaterThan(0));
      expect(mid, lessThan(full));

      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: firstSurface(),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter;
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<CustomPaint>(
              find.descendant(
                of: firstSurface(),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter,
        same(painter),
        reason: 'ticks repaint, they never rebuild the surface',
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(await inkOf(tester, firstSurface()), full);
    });

    testWidgets('reduced motion shows the full sketch immediately', (
      tester,
    ) async {
      await tester.pumpWidget(host(surface()));
      final full = await inkOf(tester, firstSurface());

      await tester.pumpWidget(
        host(
          DrawkitSketchIn(
            duration: const Duration(milliseconds: 600),
            child: surface(),
          ),
          disableAnimations: true,
        ),
      );
      expect(await inkOf(tester, firstSurface()), full);
    });
  });

  group('DrawkitStagger', () {
    testWidgets('children trace in one after another', (tester) async {
      await tester.pumpWidget(host(surface()));
      final full = await inkOf(tester, firstSurface());

      await tester.pumpWidget(
        host(
          DrawkitStagger(
            duration: const Duration(milliseconds: 300),
            step: const Duration(milliseconds: 100),
            children: [surface(), surface(), surface()],
          ),
        ),
      );
      var inks = [
        for (var i = 0; i < 3; i++)
          await inkOf(tester, find.byType(DrawkitSurface).at(i)),
      ];
      expect(inks, [0, 0, 0]);

      await tester.pump(const Duration(milliseconds: 60));
      inks = [
        for (var i = 0; i < 3; i++)
          await inkOf(tester, find.byType(DrawkitSurface).at(i)),
      ];
      expect(inks[0], greaterThan(0));
      expect(inks[1], 0);
      expect(inks[2], 0);

      await tester.pump(const Duration(milliseconds: 600));
      inks = [
        for (var i = 0; i < 3; i++)
          await inkOf(tester, find.byType(DrawkitSurface).at(i)),
      ];
      expect(inks, [full, full, full]);
    });
  });

  group('DrawkitShake', () {
    testWidgets('nudges the child and settles back', (tester) async {
      final controller = DrawkitShakeController();
      const childKey = ValueKey('shakeable');
      await tester.pumpWidget(
        host(
          DrawkitShake(
            controller: controller,
            child: const SizedBox(key: childKey, width: 50, height: 20),
          ),
        ),
      );
      final rest = tester.getTopLeft(find.byKey(childKey));

      controller.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.byKey(childKey)).dx, isNot(rest.dx));

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getTopLeft(find.byKey(childKey)), rest);
      controller.dispose();
    });

    testWidgets('reduced motion keeps it still', (tester) async {
      final controller = DrawkitShakeController();
      const childKey = ValueKey('still');
      await tester.pumpWidget(
        host(
          DrawkitShake(
            controller: controller,
            child: const SizedBox(key: childKey, width: 50, height: 20),
          ),
          disableAnimations: true,
        ),
      );
      final rest = tester.getTopLeft(find.byKey(childKey));
      controller.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.byKey(childKey)), rest);
      controller.dispose();
    });
  });
}

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      harness.host(child, direction: direction);

  group('DrawkitProgressBar', () {
    List<DrawkitLayer> layersOf(WidgetTester tester, Size size) {
      final surface = tester.widget<DrawkitSurface>(
        find.descendant(
          of: find.byType(DrawkitProgressBar),
          matching: find.byType(DrawkitSurface),
        ),
      );
      return surface.builder(size, const RoughOptions(seed: 7));
    }

    testWidgets('the fill grows from the leading edge in both directions', (
      tester,
    ) async {
      const size = Size(200, 12);
      await tester.pumpWidget(
        host(
          const SizedBox(width: 200, child: DrawkitProgressBar(value: 0.25)),
        ),
      );
      final ltr = layersOf(tester, size)[1].path.getBounds();
      expect(ltr.width, closeTo(48.5, 4));
      expect(ltr.left, lessThan(6));

      await tester.pumpWidget(
        host(
          const SizedBox(width: 200, child: DrawkitProgressBar(value: 0.25)),
          direction: TextDirection.rtl,
        ),
      );
      final rtl = layersOf(tester, size)[1].path.getBounds();
      expect(rtl.width, closeTo(48.5, 4));
      expect(rtl.right, greaterThan(191));
    });

    testWidgets('reports its value to semantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: DrawkitProgressBar(value: 0.4, semanticLabel: 'download'),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(DrawkitProgressBar));
      expect(node.value, '40%');
      semanticsHandle.dispose();
    });

    testWidgets('the indeterminate band travels inside the track', (
      tester,
    ) async {
      const size = Size(200, 12);
      await tester.pumpWidget(
        host(const SizedBox(width: 200, child: DrawkitProgressBar())),
      );
      final band = layersOf(tester, size)[1];
      final t0 = band.matrix!().getTranslation().x;
      await tester.pump(const Duration(milliseconds: 400));
      final t1 = band.matrix!().getTranslation().x;
      expect(t0, isNot(closeTo(t1, 1)));
      for (final t in [t0, t1]) {
        expect(t, inInclusiveRange(-1, 132));
      }
    });

    testWidgets('reduced motion parks the band', (tester) async {
      const size = Size(200, 12);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const SizedBox(width: 200, child: DrawkitProgressBar())),
        ),
      );
      final band = layersOf(tester, size)[1];
      final t0 = band.matrix!().getTranslation().x;
      await tester.pump(const Duration(milliseconds: 400));
      final t1 = band.matrix!().getTranslation().x;
      expect(t0, closeTo(t1, 0.001));
    });
  });

  group('DrawkitSpinner', () {
    testWidgets('turns its dashes on one clock', (tester) async {
      await tester.pumpWidget(host(const DrawkitSpinner()));
      final surface = tester.widget<DrawkitSurface>(
        find.descendant(
          of: find.byType(DrawkitSpinner),
          matching: find.byType(DrawkitSurface),
        ),
      );
      final layers = surface.builder(
        const Size(24, 24),
        const RoughOptions(seed: 7),
      );
      expect(layers, hasLength(8));
      final before = layers.first.matrix!().storage.join(',');
      await tester.pump(const Duration(milliseconds: 350));
      final after = layers.first.matrix!().storage.join(',');
      expect(after, isNot(before));
    });

    testWidgets('reduced motion parks the dashes', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const DrawkitSpinner()),
        ),
      );
      final surface = tester.widget<DrawkitSurface>(
        find.descendant(
          of: find.byType(DrawkitSpinner),
          matching: find.byType(DrawkitSurface),
        ),
      );
      final layers = surface.builder(
        const Size(24, 24),
        const RoughOptions(seed: 7),
      );
      final before = layers.first.matrix!().storage.join(',');
      await tester.pump(const Duration(milliseconds: 350));
      final after = layers.first.matrix!().storage.join(',');
      expect(after, before);
    });
  });

  group('DrawkitSkeleton', () {
    testWidgets('draws its lines with a shorter last one', (tester) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 300, child: DrawkitSkeleton(lines: 3))),
      );
      final surfaces = tester
          .widgetList<DrawkitSurface>(
            find.descendant(
              of: find.byType(DrawkitSkeleton),
              matching: find.byType(DrawkitSurface),
            ),
          )
          .toList();
      expect(surfaces, hasLength(3));
      expect(surfaces[0].size!.width, closeTo(300, 0.1));
      expect(surfaces[2].size!.width, closeTo(186, 0.1));
    });

    testWidgets('the shading band sweeps along each line', (tester) async {
      await tester.pumpWidget(
        host(const SizedBox(width: 300, child: DrawkitSkeleton(lines: 2))),
      );
      DrawkitLayer bandOf(int index) {
        final surfaces = tester
            .widgetList<DrawkitSurface>(
              find.descendant(
                of: find.byType(DrawkitSkeleton),
                matching: find.byType(DrawkitSurface),
              ),
            )
            .toList();
        return surfaces[index].builder(
          const Size(300, 12),
          const RoughOptions(seed: 7),
        )[1];
      }

      final t0 = bandOf(0).matrix!().getTranslation().x;
      await tester.pump(const Duration(milliseconds: 450));
      final t1 = bandOf(0).matrix!().getTranslation().x;
      expect(t0, isNot(closeTo(t1, 1)));
      expect(t0, inInclusiveRange(0, 195));
    });

    testWidgets('the circle variant draws one small sketch', (tester) async {
      await tester.pumpWidget(host(const DrawkitSkeleton.circle(size: 44)));
      expect(
        find.descendant(
          of: find.byType(DrawkitSkeleton),
          matching: find.byType(DrawkitSurface),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(DrawkitSkeleton)), const Size(44, 44));
    });
  });
}

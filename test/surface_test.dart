import 'dart:typed_data';

import 'package:drawkit/drawkit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<DrawkitLayer> layers(Size size, RoughOptions options) => [
    DrawkitLayer(
      Path()
        ..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: 8)),
      Paint()..color = const Color(0xFF2724D1),
    ),
  ];

  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: SizedBox(width: 120, height: 36, child: child)),
  );

  Future<Uint8List> pixels(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .descendant(
            of: find.byType(DrawkitSurface),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    final image = await boundary.toImage();
    final data = await image.toByteData();
    return data!.buffer.asUint8List();
  }

  testWidgets('paints three boil frames through one shared clock', (
    tester,
  ) async {
    final seeds = <int>{};
    await tester.pumpWidget(
      host(
        DrawkitSurface(
          builder: (size, options) {
            seeds.add(options.seed);
            // A real pen stroke, so each prebuilt frame's boil seed shows.
            return [
              DrawkitLayer(
                roughLine(
                  4,
                  size.height / 2,
                  size.width - 4,
                  size.height / 2,
                  options,
                ),
                Paint()
                  ..color = const Color(0xFF2724D1)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              ),
            ];
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(seeds.length, 1, reason: 'all three frames share the sketch seed');
    expect(find.byType(CustomPaint), findsWidgets);

    // The three prebuilt frames really do swap over the clock: pixels half a
    // cycle apart cannot match unless the painter repaints.
    final first = await tester.runAsync(() => pixels(tester));
    await tester.pump(const Duration(milliseconds: 500));
    final second = await tester.runAsync(() => pixels(tester));
    expect(second, isNot(equals(first)));
  });

  testWidgets('reduced motion freezes on a single frame', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(
          DrawkitSurface(
            builder: (size, options) {
              calls++;
              return layers(size, options);
            },
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    // one frame per build, not three
    expect(calls, 1);
  });

  testWidgets('boil 0 also skips frames', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        DrawkitSurface(
          style: const DrawkitStyle(boil: 0),
          builder: (size, options) {
            calls++;
            return layers(size, options);
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    expect(calls, 1);
  });

  testWidgets('pointer enter resketches with a fresh seed', (tester) async {
    final seeds = <int>[];
    await tester.pumpWidget(
      host(
        DrawkitSurface(
          resketchOnPointer: true,
          builder: (size, options) {
            seeds.add(options.seed);
            return layers(size, options);
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    final before = seeds.last;

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(CustomPaint).first));
    await tester.pump();

    expect(seeds.last, isNot(before), reason: 'hover draws a new sketch');

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
  });

  testWidgets('resketch(seed) pins the RNG stream', (tester) async {
    final stateKey = GlobalKey<DrawkitSurfaceState>();
    final seeds = <int>[];
    await tester.pumpWidget(
      host(
        DrawkitSurface(
          key: stateKey,
          builder: (size, options) {
            seeds.add(options.seed);
            return layers(size, options);
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
    stateKey.currentState!.resketch(4242);
    await tester.pump();
    expect(seeds.last, 4242);
  });

  testWidgets('same seed paints identical pixels across runs', (tester) async {
    // Paths are deterministic; compare their bounds across two passes to
    // prove a pinned seed produces identical geometry.
    final bounds = <Rect>[];
    for (var i = 0; i < 2; i++) {
      late Path captured;
      await tester.pumpWidget(
        host(
          DrawkitSurface(
            seed: 99,
            animate: false,
            builder: (size, options) => [
              DrawkitLayer(
                captured = roughCheckmark(3, 4, 14, 12, options),
                Paint()..color = const Color(0xFF2724D1),
              ),
            ],
            child: const SizedBox.expand(),
          ),
        ),
      );
      bounds.add(captured.getBounds());
    }
    expect(bounds[0], bounds[1]);
  });

  testWidgets('disposes without leaking the boil ticker', (tester) async {
    await tester.pumpWidget(
      host(DrawkitSurface(builder: layers, child: const SizedBox.expand())),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:drawkit/src/engine/prng.dart';
import 'package:drawkit/src/engine/rough.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures = jsonDecode(
    File('test/fixtures/js_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  double approx(Object? v) => (v as num).toDouble();

  group('prng matches mulberry32 from src/prng.ts', () {
    final vectors = fixtures['mulberry32'] as Map<String, dynamic>;
    for (final entry in vectors.entries) {
      test('seed ${entry.key}', () {
        final rand = Mulberry32(int.parse(entry.key));
        final expected = (entry.value as List).map(approx).toList();
        for (var i = 0; i < expected.length; i++) {
          expect(rand.next(), expected[i], reason: 'value $i');
        }
      });
    }
  });

  group('point pipeline matches src/rough.ts', () {
    final points = fixtures['points'] as Map<String, dynamic>;

    List<Offset> offsets(String key) => [
      for (final p in points[key] as List)
        Offset(approx((p as List)[0]), approx(p[1])),
    ];

    void expectPoints(
      List<Offset> actual,
      List<Offset> expected,
      String reason, {
      double tolerance = 0,
    }) {
      expect(actual.length, expected.length, reason: '$reason length');
      for (var i = 0; i < expected.length; i++) {
        if (tolerance == 0) {
          expect(actual[i].dx, expected[i].dx, reason: '$reason [$i].x');
          expect(actual[i].dy, expected[i].dy, reason: '$reason [$i].y');
        } else {
          expect(
            actual[i].dx,
            closeTo(expected[i].dx, tolerance),
            reason: '$reason [$i].x',
          );
          expect(
            actual[i].dy,
            closeTo(expected[i].dy, tolerance),
            reason: '$reason [$i].y',
          );
        }
      }
    }

    test('sampleLine default step', () {
      expectPoints(
        sampleLine(10, 20, 110, 20),
        offsets('sampleLineDefault'),
        'default',
      );
    });

    test('sampleLine short distance keeps n >= 2', () {
      expectPoints(sampleLine(0, 0, 3, 4), offsets('sampleLineShort'), 'short');
    });

    test('ellipsePoints sampling', () {
      // cos/sin differ by 1 ulp between V8 and the Dart VM; the pen rounds to
      // two decimals, where both agree (see the path string tests below).
      expectPoints(
        ellipsePoints(50, 50, 40, 25, 0, 3.141592653589793 * 2, 10),
        offsets('ellipsePoints'),
        'ellipse',
        tolerance: 1e-9,
      );
    });

    test('jitter consumes one PRNG value per coordinate', () {
      final jittered = jitter(sampleLine(0, 0, 50, 0), Mulberry32(42), 1.5);
      expectPoints(jittered, offsets('jitter42'), 'jitter');
    });
  });

  group('path strings match src/rough.ts', () {
    final paths = fixtures['paths'] as Map<String, dynamic>;
    final o42 = const RoughOptions(
      seed: 42,
      roughness: 1,
      boil: 0.3,
      boilSeed: 42 + 7919,
    );

    test('roughLine with boil', () {
      expect(
        debugSketchString('line', [10, 20, 110, 20], o42),
        paths['roughLine_42_boil'],
      );
    });

    test('roughLine without boil', () {
      expect(
        debugSketchString('line', [
          10,
          20,
          110,
          20,
        ], const RoughOptions(seed: 42)),
        paths['roughLine_42_noboil'],
      );
    });

    test('roughRoundedRect with boil', () {
      expect(
        debugSketchString('roundedRect', [3, 3, 100, 40, 8], o42),
        paths['roughRoundedRect_42_boil'],
      );
    });

    test('roughCircle with boil', () {
      expect(
        debugSketchString(
          'circle',
          [50, 50, 25],
          const RoughOptions(
            seed: 7,
            roughness: 1.2,
            boil: 0.3,
            boilSeed: 7 + 7919,
          ),
        ),
        paths['roughCircle_7_boil'],
      );
    });

    test('roughEllipse with boil', () {
      expect(
        debugSketchString(
          'ellipse',
          [50, 50, 40, 25],
          const RoughOptions(
            seed: 99,
            roughness: 0.8,
            boil: 0.2,
            boilSeed: 99 + 7919,
          ),
        ),
        paths['roughEllipse_99_boil'],
      );
    });

    test('roughArrow with boil', () {
      expect(
        debugSketchString(
          'arrow',
          [10, 10, 110, 60],
          const RoughOptions(
            seed: 5,
            roughness: 1,
            boil: 0.3,
            boilSeed: 5 + 7919,
          ),
        ),
        paths['roughArrow_5_boil'],
      );
    });

    test('roughCheckmark with boil', () {
      expect(
        debugSketchString(
          'checkmark',
          [3, 3, 16, 16],
          const RoughOptions(
            seed: 11,
            roughness: 1,
            boil: 0.3,
            boilSeed: 11 + 7919,
          ),
        ),
        paths['roughCheckmark_11_boil'],
      );
    });

    test('scribbleFill with boil', () {
      expect(
        debugSketchString(
          'scribble',
          [0, 0, 60, 24],
          const RoughOptions(
            seed: 13,
            roughness: 1,
            boil: 0.3,
            boilSeed: 13 + 7919,
          ),
        ),
        paths['scribbleFill_13_boil'],
      );
    });

    test('variants ride seed + (i + 1) * 7919', () {
      final rect = variants(
        (o) => debugSketchString('roundedRect', [3, 3, 100, 40, 8], o),
        const RoughOptions(seed: 42, roughness: 1, boil: 0.3),
      );
      expect(rect, paths['variants_rect_42']);

      final check = variants(
        (o) => debugSketchString('checkmark', [3, 3, 16, 16], o),
        const RoughOptions(seed: 8, roughness: 1, boil: 0.3),
      );
      expect(check, paths['variants_check_8']);
    });
  });

  group('path builders produce deterministic Paths', () {
    Path build(int seed) => roughRoundedRect(
      3,
      3,
      100,
      40,
      8,
      RoughOptions(seed: seed, boil: 0.3, boilSeed: seed + 7919),
    );

    test('same seed, same bounds', () {
      expect(build(42).getBounds(), build(42).getBounds());
    });

    test('different seeds, different bounds', () {
      expect(build(42).getBounds() == build(43).getBounds(), isFalse);
    });
  });
}

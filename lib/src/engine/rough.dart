import 'dart:math' as math;
import 'dart:ui';

import 'prng.dart';

/// Options carried through every geometry pass. [boilSeed] swaps the boil
/// pass onto its own stream so frames differ without disturbing [seed].
class RoughOptions {
  const RoughOptions({
    required this.seed,
    this.roughness = 1,
    this.boil = 0,
    this.boilSeed,
  });

  final int seed;
  final double roughness;
  final double boil;
  final int? boilSeed;

  RoughOptions copyWith({int? seed, int? boilSeed}) => RoughOptions(
    seed: seed ?? this.seed,
    roughness: roughness,
    boil: boil,
    boilSeed: boilSeed ?? this.boilSeed,
  );
}

/// Samples a line every [step] px, both ends included.
List<Offset> sampleLine(
  double x1,
  double y1,
  double x2,
  double y2, [
  double step = 8,
]) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final n = math.max(2, (math.sqrt(dx * dx + dy * dy) / step).ceil());
  return List<Offset>.generate(
    n + 1,
    (i) => Offset(x1 + dx * i / n, y1 + dy * i / n),
    growable: false,
  );
}

/// Arc samples; endpoints included, so joining arcs to lines duplicates points
/// the midpoint smoothing then renders as a soft corner.
List<Offset> ellipsePoints(
  double cx,
  double cy,
  double rx,
  double ry,
  double a0,
  double a1,
  int n,
) => List<Offset>.generate(n + 1, (i) {
  final a = a0 + (a1 - a0) * i / n;
  return Offset(cx + rx * math.cos(a), cy + ry * math.sin(a));
}, growable: false);

List<Offset> arcPoints(
  double cx,
  double cy,
  double r,
  double a0,
  double a1, [
  int n = 4,
]) => ellipsePoints(cx, cy, r, r, a0, a1, n);

List<Offset> roundedRectPoints(
  double x,
  double y,
  double w,
  double h,
  double r,
) {
  r = math.min(r, math.min(w / 2, h / 2));
  return [
    ...sampleLine(x + r, y, x + w - r, y),
    ...arcPoints(x + w - r, y + r, r, -math.pi / 2, 0),
    ...sampleLine(x + w, y + r, x + w, y + h - r),
    ...arcPoints(x + w - r, y + h - r, r, 0, math.pi / 2),
    ...sampleLine(x + w - r, y + h, x + r, y + h),
    ...arcPoints(x + r, y + h - r, r, math.pi / 2, math.pi),
    ...sampleLine(x, y + h - r, x, y + r),
    ...arcPoints(x + r, y + r, r, math.pi, math.pi * 1.5),
  ];
}

/// Two segments with a duplicated vertex so the corner stays sharp under
/// midpoint smoothing.
List<Offset> checkmarkPoints(double x, double y, double w, double h) => [
  ...sampleLine(x, y + h * 0.6, x + w * 0.35, y + h, 4),
  ...sampleLine(x + w * 0.35, y + h, x + w, y, 4),
];

/// Continuous diagonal scribble across the box, one zigzag stroke.
List<Offset> scribblePoints(double x, double y, double w, double h) {
  const gap = 6.0;
  final pts = <Offset>[];
  var flip = false;
  for (var t = gap; t < w + h; t += gap) {
    final a = Offset(x + math.max(0, t - h), y + math.min(t, h));
    final b = Offset(x + math.min(t, w), y + math.max(0, t - w));
    pts.addAll(flip ? [b, a] : [a, b]);
    flip = !flip;
  }
  return pts;
}

List<Offset> jitter(List<Offset> points, Mulberry32 rand, double amp) =>
    List<Offset>.generate(points.length, (i) {
      final p = points[i];
      return Offset(
        p.dx + (rand.next() * 2 - 1) * amp,
        p.dy + (rand.next() * 2 - 1) * amp,
      );
    }, growable: false);

List<Offset> boilPass(List<Offset> points, RoughOptions o) {
  if (o.boil == 0 || o.boilSeed == null) return points;
  return jitter(points, Mulberry32(o.boilSeed!), o.boil);
}

/// Midpoint-quadratic smoothing: each interior point is a control, the curve
/// passes through the midpoints. Shared with the JS pen, so strokes match.
Path smooth(List<Offset> points, {required bool close}) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 1; i < points.length - 1; i++) {
    final c = points[i];
    final next = points[i + 1];
    path.quadraticBezierTo(
      c.dx,
      c.dy,
      (c.dx + next.dx) / 2,
      (c.dy + next.dy) / 2,
    );
  }
  final last = points.last;
  path.lineTo(last.dx, last.dy);
  if (close) path.close();
  return path;
}

/// Both stroke passes of the double-stroke sketch, in draw order.
List<List<Offset>> doubleStrokePoints(List<Offset> points, RoughOptions o) {
  final rand = Mulberry32(o.seed);
  final amp = 1.5 * o.roughness;
  return [
    boilPass(jitter(points, rand, amp), o),
    boilPass(jitter(points, rand, amp * 1.4), o),
  ];
}

Path doubleStroke(List<Offset> points, RoughOptions o, {required bool close}) {
  final strokes = doubleStrokePoints(points, o);
  return Path()
    ..addPath(smooth(strokes[0], close: close), Offset.zero)
    ..addPath(smooth(strokes[1], close: close), Offset.zero);
}

Path roughLine(double x1, double y1, double x2, double y2, RoughOptions o) =>
    doubleStroke(sampleLine(x1, y1, x2, y2), o, close: false);

Path roughCircle(double cx, double cy, double r, RoughOptions o) =>
    roughEllipse(cx, cy, r, r, o);

Path roughEllipse(double cx, double cy, double rx, double ry, RoughOptions o) {
  // Ramanujan's perimeter approximation, sampled every 8px like the lines
  final h = math.pow((rx - ry) / (rx + ry), 2).toDouble();
  final perimeter =
      math.pi * (rx + ry) * (1 + (3 * h) / (10 + math.sqrt(4 - 3 * h)));
  final n = math.max(8, (perimeter / 8).ceil());
  // the last of n + 1 samples coincides with the first; close() joins them
  final points = ellipsePoints(cx, cy, rx, ry, 0, math.pi * 2, n).sublist(0, n);
  return doubleStroke(points, o, close: true);
}

Path roughRoundedRect(
  double x,
  double y,
  double w,
  double h,
  double r,
  RoughOptions o,
) => doubleStroke(roundedRectPoints(x, y, w, h, r), o, close: true);

/// One stroke, so the ridge of the check stays a single pen line.
Path roughCheckmark(double x, double y, double w, double h, RoughOptions o) {
  final rand = Mulberry32(o.seed);
  final pts = checkmarkPoints(x, y, w, h);
  return smooth(
    boilPass(jitter(pts, rand, 1.2 * o.roughness), o),
    close: false,
  );
}

Path scribbleFill(double x, double y, double w, double h, RoughOptions o) {
  final rand = Mulberry32(o.seed);
  final pts = scribblePoints(x, y, w, h);
  if (pts.length < 2) return Path();
  return smooth(
    boilPass(jitter(pts, rand, 1.2 * o.roughness), o),
    close: false,
  );
}

const double arrowHead = 12;
const double arrowHeadAngle = math.pi / 6;

/// Line + two head strokes. The heads share one PRNG stream in draw order,
/// so they diverge like two quick flicks of the same hand.
List<List<Offset>> arrowStrokes(
  double x1,
  double y1,
  double x2,
  double y2,
  RoughOptions o,
) {
  final a = math.atan2(y2 - y1, x2 - x1);
  Offset wing(double da) => Offset(
    x2 - arrowHead * math.cos(a + da),
    y2 - arrowHead * math.sin(a + da),
  );
  final left = wing(arrowHeadAngle);
  final right = wing(-arrowHeadAngle);
  final rand = Mulberry32(o.seed);
  final amp = 1.2 * o.roughness;
  List<Offset> head(Offset p) =>
      boilPass(jitter(sampleLine(x2, y2, p.dx, p.dy, 4), rand, amp), o);
  return [
    ...doubleStrokePoints(sampleLine(x1, y1, x2, y2), o),
    head(left),
    head(right),
  ];
}

Path roughArrow(double x1, double y1, double x2, double y2, RoughOptions o) {
  final strokes = arrowStrokes(x1, y1, x2, y2, o);
  final path = Path();
  for (final s in strokes) {
    path.addPath(smooth(s, close: false), Offset.zero);
  }
  return path;
}

/// Three frames whose boil seeds ride one cycle apart, so a single clock can
/// step through them (see DrawkitSurface).
List<T> variants<T>(
  T Function(RoughOptions o) gen,
  RoughOptions o, [
  int n = 3,
]) => List<T>.generate(
  n,
  (i) => gen(o.copyWith(boilSeed: o.seed + (i + 1) * 7919)),
  growable: false,
);

/// Serializes points with the JS pen's `toFixed(2)` formatting. Exists for
/// fixture tests that prove the port draws exactly what `rough.ts` draws.
String pathString(List<Offset> points, {required bool close}) {
  String f(double v) {
    final n = v == 0 ? 0.0 : v;
    return n.toStringAsFixed(2);
  }

  final sb = StringBuffer('M${f(points.first.dx)} ${f(points.first.dy)}');
  for (var i = 1; i < points.length - 1; i++) {
    final c = points[i];
    final next = points[i + 1];
    sb
      ..write('Q${f(c.dx)} ${f(c.dy)} ')
      ..write('${f((c.dx + next.dx) / 2)} ${f((c.dy + next.dy) / 2)}');
  }
  final last = points.last;
  sb.write('L${f(last.dx)} ${f(last.dy)}');
  if (close) sb.write('Z');
  return sb.toString();
}

/// Rebuilds the JS `rough.ts` path strings for a generator, for fixtures.
String debugSketchString(String kind, List<double> args, RoughOptions o) {
  String ds(List<Offset> pts, bool close) => pathString(pts, close: close);
  switch (kind) {
    case 'line':
      return doubleStrokePoints(
        sampleLine(args[0], args[1], args[2], args[3]),
        o,
      ).map((p) => ds(p, false)).join();
    case 'roundedRect':
      return doubleStrokePoints(
        roundedRectPoints(args[0], args[1], args[2], args[3], args[4]),
        o,
      ).map((p) => ds(p, true)).join();
    case 'circle':
      return debugSketchString('ellipse', [
        args[0],
        args[1],
        args[2],
        args[2],
      ], o);
    case 'ellipse':
      final rx = args[2];
      final ry = args[3];
      final h = math.pow((rx - ry) / (rx + ry), 2).toDouble();
      final perimeter =
          math.pi * (rx + ry) * (1 + (3 * h) / (10 + math.sqrt(4 - 3 * h)));
      final n = math.max(8, (perimeter / 8).ceil());
      final pts = ellipsePoints(
        args[0],
        args[1],
        rx,
        ry,
        0,
        math.pi * 2,
        n,
      ).sublist(0, n);
      return doubleStrokePoints(pts, o).map((p) => ds(p, true)).join();
    case 'arrow':
      return arrowStrokes(
        args[0],
        args[1],
        args[2],
        args[3],
        o,
      ).map((p) => ds(p, false)).join();
    case 'checkmark':
      final rand = Mulberry32(o.seed);
      final pts = checkmarkPoints(args[0], args[1], args[2], args[3]);
      return ds(boilPass(jitter(pts, rand, 1.2 * o.roughness), o), false);
    case 'scribble':
      final rand = Mulberry32(o.seed);
      final pts = scribblePoints(args[0], args[1], args[2], args[3]);
      return ds(boilPass(jitter(pts, rand, 1.2 * o.roughness), o), false);
    default:
      throw ArgumentError('unknown sketch kind: $kind');
  }
}

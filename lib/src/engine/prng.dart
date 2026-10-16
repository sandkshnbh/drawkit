import 'dart:math' as math;

/// JS `mulberry32`, bit-for-bit. Values match the reference implementation
/// on native and web: 32-bit ops are emulated so doubles never lose bits.
class Mulberry32 {
  Mulberry32(int seed) : _a = seed & 0xFFFFFFFF;

  int _a;

  double next() {
    _a = (_a + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _a;
    t = _imul(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >>> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296;
  }

  // Math.imul: low 32 bits of the product, split so web doubles stay exact.
  static int _imul(int a, int b) {
    final aLo = a & 0xFFFF;
    final aHi = (a >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final lo = aLo * bLo;
    final mid = (aLo * bHi + aHi * bLo) & 0xFFFF;
    return (lo + (mid << 16)) & 0xFFFFFFFF;
  }
}

int randomSeed() => math.Random().nextInt(0x100000000);

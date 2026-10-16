import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Brand palette, the Dart side of drawably's CSS custom properties.
abstract final class DrawkitPalette {
  static const Color pen = Color(0xFF2724D1);
  static const Color paper = Color(0xFFE3E3E1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD12724);
  static const Color success = Color(0xFF188A42);
  static const Color neutral = Color(0xFF6E675F);
  static const Color ink = Color(0xFF18181B);
  static const Color inkMuted = Color(0xFF474645);
  static const Color inkFaint = Color(0xFFA1A1AA);
}

/// Visual configuration shared by every Drawkit widget.
///
/// [width] is nullable on purpose: controls default to 2 and text decorations
/// to 1.5, exactly like the CSS (`.drawably-svg path` 2, underline/circle
/// 1.5), so an unset width keeps each surface's own default.
@immutable
class DrawkitStyle {
  const DrawkitStyle({
    this.seed,
    this.roughness = 1,
    this.boil = 0.3,
    this.strokeColor = DrawkitPalette.pen,
    this.fillColor = DrawkitPalette.pen,
    this.paperColor = DrawkitPalette.surface,
    this.width,
    this.ink,
  }) : assert(roughness >= 0),
       assert(boil >= 0),
       assert(width == null || width >= 0);

  final int? seed;
  final double roughness;
  final double boil;
  final Color strokeColor;
  final Color fillColor;
  final Color paperColor;
  final double? width;

  /// State override: when set it wins over stroke and fill (button states).
  final Color? ink;

  Color get effectiveStroke => ink ?? strokeColor;

  Color get effectiveFill => ink ?? fillColor;

  double strokeWidth(double fallback) => width ?? fallback;

  DrawkitStyle copyWith({
    int? seed,
    bool clearSeed = false,
    double? roughness,
    double? boil,
    Color? strokeColor,
    Color? fillColor,
    Color? paperColor,
    double? width,
    Color? ink,
    bool clearInk = false,
  }) => DrawkitStyle(
    seed: clearSeed ? null : seed ?? this.seed,
    roughness: roughness ?? this.roughness,
    boil: boil ?? this.boil,
    strokeColor: strokeColor ?? this.strokeColor,
    fillColor: fillColor ?? this.fillColor,
    paperColor: paperColor ?? this.paperColor,
    width: width ?? this.width,
    ink: clearInk ? null : ink ?? this.ink,
  );

  static DrawkitStyle lerp(DrawkitStyle a, DrawkitStyle b, double t) =>
      DrawkitStyle(
        seed: t < 0.5 ? a.seed : b.seed,
        roughness: lerpDouble(a.roughness, b.roughness, t)!,
        boil: lerpDouble(a.boil, b.boil, t)!,
        strokeColor: Color.lerp(a.strokeColor, b.strokeColor, t)!,
        fillColor: Color.lerp(a.fillColor, b.fillColor, t)!,
        paperColor: Color.lerp(a.paperColor, b.paperColor, t)!,
        width: lerpDouble(a.width, b.width, t),
        ink: Color.lerp(a.ink, b.ink, t),
      );

  @override
  bool operator ==(Object other) =>
      other is DrawkitStyle &&
      other.seed == seed &&
      other.roughness == roughness &&
      other.boil == boil &&
      other.strokeColor == strokeColor &&
      other.fillColor == fillColor &&
      other.paperColor == paperColor &&
      other.width == width &&
      other.ink == ink;

  @override
  int get hashCode => Object.hash(
    seed,
    roughness,
    boil,
    strokeColor,
    fillColor,
    paperColor,
    width,
    ink,
  );
}

/// Optional defaults for a subtree; everything falls back to [DrawkitStyle]'s
/// own values when no theme is installed.
class DrawkitTheme extends InheritedTheme {
  const DrawkitTheme({required this.data, required super.child, super.key});

  final DrawkitStyle data;

  static DrawkitStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DrawkitTheme>()?.data ??
      const DrawkitStyle();

  @override
  bool updateShouldNotify(DrawkitTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      DrawkitTheme(data: data, child: child);
}

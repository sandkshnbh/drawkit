import 'dart:ui' show PlatformDispatcher, lerpDouble;

import 'package:flutter/widgets.dart';

/// The CSS `--drawably-ease`: cubic-bezier(0.2, 0, 0, 1).
const Curve drawkitEase = Cubic(0.2, 0, 0, 1);

/// True when the platform asks for reduced motion. Mirrors the CSS
/// `prefers-reduced-motion` block: boil freezes on frame 0, transitions and
/// pointer re-sketches are skipped.
bool drawkitReduceMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  if (media != null && media.disableAnimations) return true;
  return PlatformDispatcher.instance.accessibilityFeatures.reduceMotion;
}

/// Brand palette, the Dart side of drawably's CSS custom properties.
///
/// [light] holds the original values (the CSS defaults); [dark] is the
/// paper-at-night preset. Widgets resolve the active palette from their
/// [DrawkitStyle] (`style.palette`), so installing
/// `DrawkitTheme(data: DrawkitPalette.dark.style)` re-inks a whole subtree —
/// chrome colours come from the style's stroke/fill/paper, ink and tone
/// colours from the palette.
@immutable
class DrawkitPalette {
  const DrawkitPalette({
    required this.pen,
    required this.paper,
    required this.surface,
    required this.error,
    required this.success,
    required this.neutral,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
  });

  static const light = DrawkitPalette(
    pen: _lightPen,
    paper: _lightPaper,
    surface: _lightSurface,
    error: _lightError,
    success: _lightSuccess,
    neutral: _lightNeutral,
    ink: _lightInk,
    inkMuted: _lightInkMuted,
    inkFaint: _lightInkFaint,
  );

  static const dark = DrawkitPalette(
    pen: _darkPen,
    paper: _darkPaper,
    surface: _darkSurface,
    error: _darkError,
    success: _darkSuccess,
    neutral: _darkNeutral,
    ink: _darkInk,
    inkMuted: _darkInkMuted,
    inkFaint: _darkInkFaint,
  );

  final Color pen;
  final Color paper;
  final Color surface;
  final Color error;
  final Color success;
  final Color neutral;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;

  /// A matching chrome style: strokes and fills in the palette's pen, drawn
  /// boxes filled with its surface. Install both together:
  /// `DrawkitTheme(data: DrawkitPalette.dark.style, child: ...)`.
  DrawkitStyle get style => DrawkitStyle(
    strokeColor: pen,
    fillColor: pen,
    paperColor: surface,
    palette: this,
  );

  @override
  bool operator ==(Object other) =>
      other is DrawkitPalette &&
      other.pen == pen &&
      other.paper == paper &&
      other.surface == surface &&
      other.error == error &&
      other.success == success &&
      other.neutral == neutral &&
      other.ink == ink &&
      other.inkMuted == inkMuted &&
      other.inkFaint == inkFaint;

  @override
  int get hashCode => Object.hash(
    pen,
    paper,
    surface,
    error,
    success,
    neutral,
    ink,
    inkMuted,
    inkFaint,
  );
}

const Color _lightPen = Color(0xFF2724D1);
const Color _lightPaper = Color(0xFFE3E3E1);
const Color _lightSurface = Color(0xFFFFFFFF);
const Color _lightError = Color(0xFFD12724);
const Color _lightSuccess = Color(0xFF188A42);
const Color _lightNeutral = Color(0xFF6E675F);
const Color _lightInk = Color(0xFF18181B);
const Color _lightInkMuted = Color(0xFF474645);
const Color _lightInkFaint = Color(0xFFA1A1AA);

const Color _darkPen = Color(0xFF8B88FF);
const Color _darkPaper = Color(0xFF1D1E21);
const Color _darkSurface = Color(0xFF26282C);
const Color _darkError = Color(0xFFFF8A85);
const Color _darkSuccess = Color(0xFF6FD79B);
const Color _darkNeutral = Color(0xFFC4BEB6);
const Color _darkInk = Color(0xFFF1F1EF);
const Color _darkInkMuted = Color(0xFFB4B3AF);
const Color _darkInkFaint = Color(0xFF84837F);

/// WCAG contrast ratio between two opaque colors.
double drawkitContrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// [ink] nudged until it reaches the WCAG AA contrast ratio ([minRatio],
/// 4.5 by default) against [background] — toward black on a light paper,
/// toward white on a dark one. Strokes keep the brand tone; text built from
/// the same color goes through here so tone and state colors stay readable.
Color drawkitReadableInk(
  Color ink, [
  Color? background,
  double minRatio = 4.5,
]) {
  final against = background ?? DrawkitPalette.light.paper;
  final toward = against.computeLuminance() > 0.5
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);
  var candidate = ink;
  for (
    var i = 0;
    i < 40 && drawkitContrast(candidate, against) < minRatio;
    i++
  ) {
    candidate = Color.lerp(candidate, toward, 0.05)!;
  }
  return candidate;
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
    this.strokeColor = _lightPen,
    this.fillColor = _lightPen,
    this.paperColor = _lightSurface,
    this.width,
    this.ink,
    this.palette = DrawkitPalette.light,
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

  /// The ink and tone colors widgets dress their text with. Swap it with the
  /// stroke/fill/paper colors for a full re-ink: `DrawkitPalette.dark.style`.
  final DrawkitPalette palette;

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
    DrawkitPalette? palette,
  }) => DrawkitStyle(
    seed: clearSeed ? null : seed ?? this.seed,
    roughness: roughness ?? this.roughness,
    boil: boil ?? this.boil,
    strokeColor: strokeColor ?? this.strokeColor,
    fillColor: fillColor ?? this.fillColor,
    paperColor: paperColor ?? this.paperColor,
    width: width ?? this.width,
    ink: clearInk ? null : ink ?? this.ink,
    palette: palette ?? this.palette,
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
        palette: t < 0.5 ? a.palette : b.palette,
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
      other.ink == ink &&
      other.palette == palette;

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
    palette,
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

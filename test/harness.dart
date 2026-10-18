import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared widget-test scaffolding: one host, one route host, and one
/// accessibility host — the app/theme/MediaQuery plumbing every suite used
/// to copy privately.
Widget host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool disableAnimations = false,
  bool app = false,
  bool overlay = false,
  DrawkitStyle style = const DrawkitStyle(boil: 0),
  double? width,
  double? height,
}) {
  Widget core = Center(
    child: width == null && height == null
        ? child
        : SizedBox(width: width, height: height, child: child),
  );
  if (overlay) {
    final inner = core;
    core = Overlay(initialEntries: [OverlayEntry(builder: (context) => inner)]);
  }
  if (disableAnimations) {
    final inner = core;
    core = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: inner,
      ),
    );
  }
  final home = Directionality(
    textDirection: direction,
    child: DrawkitTheme(data: style, child: core),
  );
  if (!app) return home;
  return WidgetsApp(
    color: DrawkitPalette.light.paper,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        ),
    home: home,
  );
}

/// A bare [Navigator] host for suites that open routes themselves.
Widget routeHost(
  Widget Function(BuildContext context) home, {
  TextDirection direction = TextDirection.ltr,
  bool disableAnimations = false,
}) {
  Widget navigator = Navigator(
    onGenerateRoute: (settings) => PageRouteBuilder(
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => home(context),
    ),
  );
  if (disableAnimations) {
    navigator = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: navigator,
      ),
    );
  }
  return Directionality(
    textDirection: direction,
    child: DrawkitTheme(data: const DrawkitStyle(boil: 0), child: navigator),
  );
}

/// The gallery-style wrapper the accessibility suites render samples in:
/// readable ink, no text decoration, the paper as the page.
Widget a11yHost(
  Widget child, {
  DrawkitPalette palette = DrawkitPalette.light,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(
    style: TextStyle(
      color: palette.ink,
      fontSize: 14,
      height: 1.4,
      decoration: TextDecoration.none,
    ),
    child: DrawkitTheme(
      data: palette.style.copyWith(boil: 0),
      child: ColoredBox(color: palette.paper, child: child),
    ),
  ),
);

/// Pumps [widget] through a host, lets the boil clock tick a beat, then
/// unmounts it — a control that leaks a controller or ticker throws here.
Future<void> disposeSmoke(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpWidget(const SizedBox());
}

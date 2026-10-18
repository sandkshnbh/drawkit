import 'package:drawkit/drawkit.dart';
import 'package:drawkit_gallery/main.dart' show galleryPages;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in const [false, true]) {
    final palette = dark ? DrawkitPalette.dark : DrawkitPalette.light;
    final shade = dark ? ' (dark)' : '';
    for (final direction in TextDirection.values) {
      final way = direction == TextDirection.rtl ? ' (rtl)' : '';
      for (final page in galleryPages) {
        testWidgets(
          '${page.title} meets the accessibility guidelines$shade$way',
          (tester) async {
            tester.view.physicalSize = const Size(1400, 6000);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);
            final semantics = tester.ensureSemantics();
            await tester.pumpWidget(
              Directionality(
                textDirection: direction,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14,
                    height: 1.4,
                    decoration: TextDecoration.none,
                  ),
                  child: DrawkitTheme(
                    data: palette.style,
                    child: Builder(
                      builder: (context) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(textScaler: const TextScaler.linear(1.2)),
                        child: ColoredBox(
                          color: palette.paper,
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: 1200,
                              child: Builder(builder: page.builder),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            semantics.dispose();
          },
        );
      }
    }
  }

  testWidgets('overlays mount under reduced motion in RTL', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    late BuildContext ctx;
    await tester.pumpWidget(
      WidgetsApp(
        color: DrawkitPalette.light.paper,
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              transitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: DrawkitTheme(
            data: DrawkitPalette.light.style.copyWith(boil: 0),
            child: Builder(
              builder: (context) {
                ctx = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    final dialog = showDrawkitDialog<void>(
      context: ctx,
      child: const Text('صباح الخير'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('صباح الخير'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('صباح الخير'), findsNothing);
    await dialog;

    showDrawkitToast(ctx, message: 'تم الحفظ');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('تم الحفظ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3000));
  });
}

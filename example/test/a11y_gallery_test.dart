import 'package:drawkit/drawkit.dart';
import 'package:drawkit_gallery/main.dart' show galleryPages;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final page in galleryPages) {
    testWidgets('${page.title} meets the accessibility guidelines', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: DrawkitPalette.ink,
              fontSize: 14,
              height: 1.4,
              decoration: TextDecoration.none,
            ),
            child: DrawkitTheme(
              data: const DrawkitStyle(boil: 0),
              child: ColoredBox(
                color: DrawkitPalette.paper,
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
      );
      await tester.pump();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}

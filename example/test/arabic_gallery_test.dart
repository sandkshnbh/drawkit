import 'package:drawkit/drawkit.dart';
import 'package:drawkit_gallery/l10n.dart' show demoArabic;
import 'package:drawkit_gallery/main.dart' show DrawkitGalleryApp, galleryPages;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the Arabic gallery keeps English out of its copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final english = RegExp(r'[A-Za-z]{3,}');
    final allowed = RegExp(
      r'^(drawkit|HB|RTL|CSS|Tab|Home|End|PageUp|PageDown|Enter|Space|'
      r'Escape|Up|Down|sketchbook)$',
    );
    final seen = <String>{};

    void sweep(String where) {
      for (final element in find.byType(Text).evaluate()) {
        final text = (element.widget as Text).data ?? '';
        if (!english.hasMatch(text) || text.contains('@')) continue;
        for (final word in text.split(RegExp(r'[^A-Za-z]+'))) {
          if (word.length >= 3 && !allowed.hasMatch(word)) {
            seen.add('$where: $text');
            break;
          }
        }
      }
    }

    demoArabic = true;
    for (final page in galleryPages) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: DefaultTextStyle(
            style: TextStyle(
              color: DrawkitPalette.light.ink,
              fontSize: 14,
              height: 1.4,
              decoration: TextDecoration.none,
            ),
            child: DrawkitTheme(
              data: DrawkitPalette.light.style,
              child: ColoredBox(
                color: DrawkitPalette.light.paper,
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
      await tester.pump(const Duration(milliseconds: 300));
      sweep(page.title);
    }

    await tester.pumpWidget(const DrawkitGalleryApp());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(DrawkitToggle).first);
    await tester.pump(const Duration(milliseconds: 300));
    sweep('chrome');

    expect(seen, isEmpty, reason: seen.join('\n'));
  });
}

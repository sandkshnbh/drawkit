import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawkit/drawkit.dart';
import 'package:drawkit_gallery/l10n.dart' show demoArabic;
import 'package:drawkit_gallery/main.dart' show galleryPages;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _shotFamily = 'DrawkitShot';
const _shotArabic = 'DrawkitShotArabic';

Future<void> _loadFileFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length),
      ),
    );
  await loader.load();
}

Future<void> _loadAssetFont(String family, String key) async {
  final data = await rootBundle.load(key);
  await (FontLoader(family)..addFont(Future.value(data))).load();
}

Widget _frame({required Widget child, required bool dark, required bool rtl}) {
  final palette = dark ? DrawkitPalette.dark : DrawkitPalette.light;
  return Directionality(
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    child: DefaultTextStyle(
      style: TextStyle(
        fontFamily: _shotFamily,
        fontFamilyFallback: const [_shotArabic],
        color: palette.ink,
        fontSize: 14,
        height: 1.4,
        decoration: TextDecoration.none,
      ),
      child: DrawkitTheme(
        data: palette.style,
        child: ColoredBox(
          color: palette.paper,
          child: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(30), child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('capture gallery screenshots', (tester) async {
    tester.view.physicalSize = const Size(1200, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const latin = '/usr/share/fonts/liberation-sans-fonts';
    await _loadFileFont(_shotFamily, '$latin/LiberationSans-Regular.ttf');
    await _loadFileFont(_shotFamily, '$latin/LiberationSans-Bold.ttf');
    const arabic = '/usr/share/fonts/paktype-naskh-basic-fonts';
    await _loadFileFont(_shotArabic, '$arabic/PakTypeNaskhBasic.ttf');
    await _loadFileFont(_shotArabic, '/usr/share/fonts/kacst/KacstNaskh.ttf');
    await _loadAssetFont('DrawkitPen', 'packages/drawkit/fonts/DrawkitPen.ttf');

    final outDir = Directory.fromUri(Platform.script.resolve('../doc/images/'));
    outDir.createSync(recursive: true);

    Future<void> shoot(
      String name, {
      required int page,
      bool dark = false,
      bool rtl = false,
    }) async {
      demoArabic = rtl;
      final key = GlobalKey();
      final pages = galleryPages;
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: _frame(
            dark: dark,
            rtl: rtl,
            child: SizedBox(
              width: 1140,
              child: Builder(builder: pages[page].builder),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${outDir.path}$name.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    demoArabic = false;
    final titles = [for (final page in galleryPages) page.title];
    // ignore: avoid_print
    print('pages: $titles');

    int pageNamed(String needle) =>
        titles.indexWhere((title) => title.contains(needle));

    await shoot('gallery-buttons', page: pageNamed('Buttons'));
    await shoot('gallery-choices', page: pageNamed('Choices'));
    await shoot('gallery-type', page: pageNamed('Type'));
    await shoot('gallery-containers', page: pageNamed('Cards'));
    await shoot('gallery-type-dark', page: pageNamed('Type'), dark: true);
    await shoot('gallery-buttons-rtl', page: pageNamed('Buttons'), rtl: true);

    demoArabic = false;
  });
}

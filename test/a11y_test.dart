import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_sample.dart';

void main() {
  testWidgets('every control meets the Android tap target guideline', (
    tester,
  ) async {
    final semantics = await pumpA11ySample(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('every control meets the iOS tap target guideline', (
    tester,
  ) async {
    final semantics = await pumpA11ySample(tester);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('every tappable control carries a semantic label', (
    tester,
  ) async {
    final semantics = await pumpA11ySample(tester);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('text keeps WCAG contrast on the paper', (tester) async {
    final semantics = await pumpA11ySample(tester);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('large text scales the sample without overflow', (tester) async {
    tester.view.physicalSize = const Size(1500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SingleChildScrollView(child: a11ySample()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

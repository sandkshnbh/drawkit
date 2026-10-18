import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget host(Widget child) => harness.host(child);

  testWidgets('fires onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(DrawkitButton(onPressed: () => taps++, child: const Text('save'))),
    );
    await tester.tap(find.text('save'));
    expect(taps, 1);
  });

  testWidgets('disabled button ignores taps and marks semantics', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    await tester.pumpWidget(host(const DrawkitButton(child: Text('save'))));
    final semantics = tester.getSemantics(
      find.bySemanticsLabel(RegExp('save')),
    );
    expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
    final detectors = tester.widgetList<GestureDetector>(
      find.descendant(
        of: find.byType(DrawkitButton),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(detectors, isNotEmpty);
    expect(
      detectors.every((detector) => detector.onTap == null),
      isTrue,
      reason: 'a disabled button registers no tap handler',
    );
    await tester.tap(find.text('save'), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    semanticsHandle.dispose();
  });

  testWidgets('loading blocks presses', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        DrawkitButton(
          state: DrawkitButtonState.loading,
          onPressed: () => taps++,
          child: const Text('save'),
        ),
      ),
    );
    await tester.tap(find.text('save'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('keyboard activation works through the focus tree', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        DrawkitButton(
          autofocus: true,
          onPressed: () => taps++,
          child: const Text('run'),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('hover keeps state and resketch does not crash', (tester) async {
    await tester.pumpWidget(
      host(DrawkitButton(onPressed: () {}, child: const Text('hover'))),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('hover')));
    await tester.pump();
    await gesture.moveTo(const Offset(1, 1));
    await tester.pump();
  });

  testWidgets('disposes focus node and tickers cleanly', (tester) async {
    await harness.disposeSmoke(
      tester,
      host(DrawkitButton(onPressed: () {}, child: const Text('bye'))),
    );
  });
}

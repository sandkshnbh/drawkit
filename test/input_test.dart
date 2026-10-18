import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget host(Widget child) => harness.host(child, width: 260);

  group('DrawkitInput', () {
    testWidgets('typing reaches the controller and onChanged', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final seen = <String>[];
      await tester.pumpWidget(
        host(DrawkitInput(controller: controller, onChanged: seen.add)),
      );
      await tester.tap(find.byType(DrawkitInput));
      await tester.enterText(find.byType(EditableText), 'hello');
      expect(controller.text, 'hello');
      expect(seen, ['hello']);
    });

    testWidgets('placeholder shows while empty and hides after typing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const DrawkitInput(placeholder: 'type here')),
      );
      expect(find.text('type here'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'x');
      await tester.pump();
      expect(find.text('type here'), findsNothing);
    });

    testWidgets('disabled input is read-only', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(DrawkitInput(controller: controller, enabled: false)),
      );
      await tester.enterText(find.byType(EditableText), 'nope');
      expect(controller.text, isEmpty);
    });

    testWidgets('focus ring state follows the focus node', (tester) async {
      await tester.pumpWidget(host(const DrawkitInput()));
      await tester.tap(find.byType(DrawkitInput));
      await tester.pump();
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('disposes owned controller and focus node', (tester) async {
      await harness.disposeSmoke(tester, host(const DrawkitInput()));
    });
  });

  group('DrawkitTextarea', () {
    testWidgets('grows with its content', (tester) async {
      await tester.pumpWidget(host(const DrawkitTextarea(minLines: 2)));
      final before = tester.getSize(find.byType(DrawkitTextarea)).height;
      await tester.enterText(find.byType(EditableText), 'a\nb\nc\nd\ne');
      await tester.pump();
      final after = tester.getSize(find.byType(DrawkitTextarea)).height;
      expect(after, greaterThan(before));
    });

    testWidgets('multiline input keeps newlines', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(DrawkitTextarea(controller: controller)));
      await tester.enterText(find.byType(EditableText), 'one\ntwo');
      expect(controller.text, 'one\ntwo');
    });

    testWidgets('disposes cleanly', (tester) async {
      await harness.disposeSmoke(tester, host(const DrawkitTextarea()));
    });
  });
}

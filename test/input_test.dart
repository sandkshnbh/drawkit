import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: DrawkitTheme(
        data: const DrawkitStyle(boil: 0),
        child: SizedBox(width: 260, child: child),
      ),
    ),
  );

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
      await tester.pumpWidget(host(const DrawkitInput()));
      await tester.pumpWidget(const SizedBox());
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
      await tester.pumpWidget(host(const DrawkitTextarea()));
      await tester.pumpWidget(const SizedBox());
    });
  });
}

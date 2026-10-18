import 'dart:ui' show Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget host(Widget child) => harness.host(child, width: 360);

  group('DrawkitAccordion', () {
    Widget accordion({bool allowMultiple = true, Set<int> open = const {}}) =>
        DrawkitAccordion(
          allowMultiple: allowMultiple,
          initiallyExpanded: open,
          sections: const [
            DrawkitAccordionSection(title: 'Pencils', child: Text('2B and HB')),
            DrawkitAccordionSection(title: 'Paper', child: Text('A5 ruled')),
          ],
        );

    testWidgets('a header unfolds and folds its body', (tester) async {
      await tester.pumpWidget(host(accordion()));
      expect(find.text('2B and HB'), findsNothing);

      await tester.tap(find.text('Pencils'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2B and HB'), findsOneWidget);

      await tester.tap(find.text('Pencils'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2B and HB'), findsNothing);
    });

    testWidgets('single-open mode closes the previous section', (tester) async {
      await tester.pumpWidget(host(accordion(allowMultiple: false, open: {0})));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2B and HB'), findsOneWidget);

      await tester.tap(find.text('Paper'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('A5 ruled'), findsOneWidget);
      expect(find.text('2B and HB'), findsNothing);
    });

    testWidgets('announce their expansion to semantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(host(accordion(open: {1})));
      await tester.pump(const Duration(milliseconds: 300));
      final node = tester.getSemantics(
        find
            .ancestor(of: find.text('Paper'), matching: find.byType(Semantics))
            .first,
      );
      expect(node.flagsCollection.isExpanded, Tristate.isTrue);
      semanticsHandle.dispose();
    });
  });
}

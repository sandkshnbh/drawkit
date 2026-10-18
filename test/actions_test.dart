import 'dart:ui' show Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      Directionality(
        textDirection: direction,
        child: Center(
          child: DrawkitTheme(data: const DrawkitStyle(boil: 0), child: child),
        ),
      );

  group('DrawkitIconButton', () {
    testWidgets('fires onPressed and announces its label', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        host(
          DrawkitIconButton(
            semanticLabel: 'close',
            onPressed: () => taps++,
            child: const Text('x'),
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('close')), findsOneWidget);
      await tester.tap(find.text('x'));
      expect(taps, 1);
      semanticsHandle.dispose();
    });

    testWidgets('disabled ignores taps and announces itself disabled', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DrawkitIconButton(
            semanticLabel: 'close',
            onPressed: null,
            child: const Text('x'),
          ),
        ),
      );
      final semantics = tester.getSemantics(
        find.bySemanticsLabel(RegExp('close')),
      );
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.text('x'), warnIfMissed: false);
      await tester.pump();
      semanticsHandle.dispose();
    });
  });

  group('DrawkitFab', () {
    testWidgets('fires onPressed on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          DrawkitFab(
            semanticLabel: 'compose',
            onPressed: () => taps++,
            child: const Text('+'),
          ),
        ),
      );
      await tester.tap(find.text('+'));
      expect(taps, 1);
    });

    testWidgets('disabled fab ignores taps and announces itself disabled', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DrawkitFab(semanticLabel: 'compose', child: Text('+'))),
      );
      final semantics = tester.getSemantics(
        find.bySemanticsLabel(RegExp('compose')),
      );
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.text('+'), warnIfMissed: false);
      await tester.pump();
      semanticsHandle.dispose();
    });
  });

  group('DrawkitSegmentedButton', () {
    const segments = [
      DrawkitSegment(value: 'a', label: 'one'),
      DrawkitSegment(value: 'b', label: 'two'),
      DrawkitSegment(value: 'c', label: 'three'),
    ];

    testWidgets('a tap reports the value, not the position', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(
        host(
          DrawkitSegmentedButton<String>(
            segments: segments,
            selected: 'a',
            onChanged: seen.add,
          ),
        ),
      );
      await tester.tap(find.text('three'));
      expect(seen, ['c']);
    });

    testWidgets('the wash sits under the selected segment in both directions', (
      tester,
    ) async {
      Rect washAt(WidgetTester tester, TextDirection direction) {
        final surface = tester.widget<DrawkitSurface>(
          find.descendant(
            of: find.byType(DrawkitSegmentedButton<String>),
            matching: find.byType(DrawkitSurface),
          ),
        );
        final layers = surface.builder(
          const Size(300, 40),
          const RoughOptions(seed: 7),
        );
        return layers[1].path.getBounds();
      }

      await tester.pumpWidget(
        host(
          const DrawkitSegmentedButton<String>(
            segments: segments,
            selected: 'c',
            onChanged: null,
          ),
        ),
      );
      expect(washAt(tester, TextDirection.ltr).center.dx, greaterThan(200));

      await tester.pumpWidget(
        host(
          const DrawkitSegmentedButton<String>(
            segments: segments,
            selected: 'c',
            onChanged: null,
          ),
          direction: TextDirection.rtl,
        ),
      );
      expect(washAt(tester, TextDirection.rtl).center.dx, lessThan(100));
      expect(
        tester.getCenter(find.text('two')).dx,
        lessThan(tester.getCenter(find.text('one')).dx),
      );
    });

    testWidgets('disabled control ignores taps and never takes focus', (
      tester,
    ) async {
      final probe = FocusNode();
      addTearDown(probe.dispose);
      await tester.pumpWidget(
        host(
          Column(
            children: [
              const DrawkitSegmentedButton<String>(
                segments: segments,
                selected: 'a',
                onChanged: null,
              ),
              Focus(
                focusNode: probe,
                child: const SizedBox(width: 8, height: 8),
              ),
            ],
          ),
        ),
      );
      probe.requestFocus();
      await tester.pump();
      expect(probe.hasFocus, isTrue);
      await tester.tap(find.text('two'), warnIfMissed: false);
      await tester.pump();
      expect(probe.hasFocus, isTrue);
    });
  });

  group('DrawkitSlider', () {
    testWidgets('a tap lands on the value under the finger', (tester) async {
      double? seen;
      await tester.pumpWidget(
        host(
          DrawkitSlider(value: 0.5, divisions: 4, onChanged: (v) => seen = v),
        ),
      );
      final rect = tester.getRect(find.byType(DrawkitSlider));
      final inner = rect.width - 20;
      await tester.tapAt(Offset(rect.left + 10 + inner * 0.25, rect.center.dy));
      expect(seen, closeTo(0.25, 1e-9));
    });

    testWidgets('dragging increases the value', (tester) async {
      final seen = <double>[];
      await tester.pumpWidget(
        host(DrawkitSlider(value: 0.25, onChanged: seen.add)),
      );
      await tester.drag(find.byType(DrawkitSlider), const Offset(200, 0));
      expect(seen, isNotEmpty);
      expect(seen.last, greaterThan(0.5));
    });

    testWidgets('arrow keys step by one division', (tester) async {
      double value = 0.25;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitSlider(
              value: value,
              divisions: 4,
              autofocus: true,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, closeTo(0.5, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, closeTo(0.25, 1e-9));
    });

    testWidgets('in RTL the fill grows from the right edge', (tester) async {
      double? seen;
      await tester.pumpWidget(
        host(
          DrawkitSlider(value: 0.5, divisions: 4, onChanged: (v) => seen = v),
          direction: TextDirection.rtl,
        ),
      );
      final rect = tester.getRect(find.byType(DrawkitSlider));
      final inner = rect.width - 20;
      await tester.tapAt(Offset(rect.left + 10 + inner * 0.25, rect.center.dy));
      expect(seen, closeTo(0.75, 1e-9));
    });

    testWidgets('disabled slider ignores input', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const DrawkitSlider(
            value: 0.5,
            semanticLabel: 'volume',
            onChanged: null,
          ),
        ),
      );
      final semantics = tester.getSemantics(
        find.bySemanticsLabel(RegExp('volume')),
      );
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
      final rect = tester.getRect(find.byType(DrawkitSlider));
      await tester.tapAt(Offset(rect.left + 100, rect.center.dy));
      await tester.pump();
      semanticsHandle.dispose();
    });
  });

  group('DrawkitStepper', () {
    testWidgets('minus and plus report clamped values', (tester) async {
      var value = 1;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitStepper(
              value: value,
              max: 2,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('+'));
      await tester.pump();
      expect(value, 2);
      await tester.tap(find.text('−'), warnIfMissed: false);
      await tester.pump();
      expect(value, 1);
    });

    testWidgets('the boundary button disables itself', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      var value = 2;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitStepper(
              value: value,
              max: 2,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      final plus = tester.getSemantics(
        find.bySemanticsLabel(RegExp('increase')),
      );
      expect(plus.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.text('+'), warnIfMissed: false);
      expect(value, 2);
      semanticsHandle.dispose();
    });
  });

  group('DrawkitSearchField', () {
    testWidgets('typing shows the clear button, clearing empties the field', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      final controller = TextEditingController();
      final seen = <String>[];
      await tester.pumpWidget(
        host(
          DrawkitSearchField(
            controller: controller,
            placeholder: 'search the sketches',
            onChanged: seen.add,
          ),
        ),
      );
      expect(find.text('search the sketches'), findsOneWidget);
      expect(find.bySemanticsLabel('clear'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'boil');
      await tester.pump();
      expect(seen, ['boil']);

      await tester.tap(find.bySemanticsLabel('clear'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(seen.last, isEmpty);
      expect(find.bySemanticsLabel('clear'), findsNothing);
      semanticsHandle.dispose();
      controller.dispose();
    });

    testWidgets('the magnifier sits at the leading edge in both directions', (
      tester,
    ) async {
      Offset circleCentre(WidgetTester tester) {
        final surface = tester.widget<DrawkitSurface>(
          find.descendant(
            of: find.byType(DrawkitSearchField),
            matching: find.byType(DrawkitSurface),
          ),
        );
        final layers = surface.builder(
          const Size(300, 37),
          const RoughOptions(seed: 7),
        );
        return layers[1].path.getBounds().center;
      }

      await tester.pumpWidget(host(const DrawkitSearchField()));
      expect(circleCentre(tester).dx, lessThan(60));

      await tester.pumpWidget(
        host(const DrawkitSearchField(), direction: TextDirection.rtl),
      );
      expect(circleCentre(tester).dx, greaterThan(240));
    });
  });
}

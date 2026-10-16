import 'dart:ui' show CheckedState, Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: DrawkitTheme(data: const DrawkitStyle(boil: 0), child: child),
    ),
  );

  group('DrawkitCheckbox', () {
    testWidgets('tap fires onChanged with the inverted value', (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitCheckbox(
              value: seen.isNotEmpty && seen.last,
              onChanged: (v) {
                setState(() => seen.add(v));
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DrawkitCheckbox));
      expect(seen, [true]);
    });

    testWidgets('semantics expose checked and enabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const DrawkitCheckbox(
            value: true,
            onChanged: null,
            semanticLabel: 'terms',
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('terms'));
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('space toggles through the focus tree', (tester) async {
      var flips = 0;
      await tester.pumpWidget(
        host(
          DrawkitCheckbox(
            value: false,
            autofocus: true,
            onChanged: (_) => flips++,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(flips, 1);
    });

    testWidgets('check draws on without crashing and settles', (tester) async {
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitCheckbox(
              value: false,
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DrawkitCheckbox));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('disposes controllers cleanly', (tester) async {
      await tester.pumpWidget(
        host(DrawkitCheckbox(value: false, onChanged: (_) {})),
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('DrawkitRadio', () {
    testWidgets('tap reports its own value', (tester) async {
      int? picked;
      await tester.pumpWidget(
        host(
          DrawkitRadio<int>(
            value: 2,
            groupValue: 1,
            onChanged: (v) => picked = v,
          ),
        ),
      );
      await tester.tap(find.byType(DrawkitRadio<int>));
      expect(picked, 2);
    });

    testWidgets('semantics show the picked state of a group', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              DrawkitRadio<int>(
                value: 1,
                groupValue: 2,
                onChanged: null,
                semanticLabel: 'one',
              ),
              DrawkitRadio<int>(
                value: 2,
                groupValue: 2,
                onChanged: null,
                semanticLabel: 'two',
              ),
            ],
          ),
        ),
      );
      final one = tester.getSemantics(find.bySemanticsLabel('one'));
      final two = tester.getSemantics(find.bySemanticsLabel('two'));
      expect(one.flagsCollection.isChecked, CheckedState.isFalse);
      expect(one.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(two.flagsCollection.isChecked, CheckedState.isTrue);
      handle.dispose();
    });

    testWidgets('dot animates in when the group value matches', (tester) async {
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitRadio<int>(
              value: 1,
              groupValue: 2,
              onChanged: (v) => setState(() {}),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DrawkitRadio<int>));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('disposes controllers cleanly', (tester) async {
      await tester.pumpWidget(
        host(DrawkitRadio<int>(value: 1, groupValue: 1, onChanged: (_) {})),
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('DrawkitToggle', () {
    testWidgets('tap flips the value', (tester) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DrawkitToggle(
              value: false,
              onChanged: (v) => setState(() => seen.add(v)),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DrawkitToggle));
      expect(seen, [true]);
    });

    testWidgets('disabled toggle ignores taps', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitToggle(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(DrawkitToggle), warnIfMissed: false);
    });

    testWidgets('keyboard flips it and the knob settles', (tester) async {
      var flips = 0;
      await tester.pumpWidget(
        host(
          DrawkitToggle(
            value: false,
            autofocus: true,
            onChanged: (_) => flips++,
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(flips, 1);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('disposes controllers cleanly', (tester) async {
      await tester.pumpWidget(
        host(DrawkitToggle(value: true, onChanged: (_) {})),
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(const SizedBox());
    });
  });
}

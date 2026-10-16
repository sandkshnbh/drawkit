import 'dart:ui' show SemanticsAction, Tristate;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      Directionality(
        textDirection: direction,
        child: DrawkitTheme(
          data: const DrawkitStyle(boil: 0),
          child: Center(child: SizedBox(width: 360, child: child)),
        ),
      );

  group('DrawkitAvatar', () {
    testWidgets('draws a disc of the requested size', (tester) async {
      await tester.pumpWidget(
        host(const Center(child: DrawkitAvatar(child: Text('AB')))),
      );
      expect(find.text('AB'), findsOneWidget);
      expect(tester.getSize(find.byType(DrawkitAvatar)), const Size(40, 40));
    });

    testWidgets('announces its label instead of the initials', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const DrawkitAvatar(semanticLabel: 'Ada Lovelace', child: Text('AL')),
        ),
      );
      expect(find.bySemanticsLabel('Ada Lovelace'), findsOneWidget);
      semanticsHandle.dispose();
    });

    testWidgets('group overlaps the discs', (tester) async {
      await tester.pumpWidget(
        host(
          const Center(
            child: DrawkitAvatarGroup(max: 4, children: [Text('A'), Text('B')]),
          ),
        ),
      );
      final a = tester.getCenter(find.text('A')).dx;
      final b = tester.getCenter(find.text('B')).dx;
      expect(b - a, closeTo(40 - 12, 0.5));
      expect(tester.getSize(find.byType(DrawkitAvatarGroup)).width, 68);
    });

    testWidgets('group collapses the overflow into +n', (tester) async {
      await tester.pumpWidget(
        host(
          const Center(
            child: DrawkitAvatarGroup(
              max: 2,
              children: [Text('A'), Text('B'), Text('C'), Text('D')],
            ),
          ),
        ),
      );
      expect(find.text('+2'), findsOneWidget);
      expect(tester.getSize(find.byType(DrawkitAvatarGroup)).width, 96);
    });

    testWidgets('group mirrors in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitAvatarGroup(max: 4, children: [Text('A'), Text('B')]),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getCenter(find.text('A')).dx >
            tester.getCenter(find.text('B')).dx,
        isTrue,
      );
    });
  });

  group('DrawkitFigure', () {
    testWidgets('frames the child and captions it beneath', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitFigure(
            caption: 'plate I — the kettle',
            padding: EdgeInsets.all(8),
            child: SizedBox(width: 120, height: 80, child: Text('img')),
          ),
        ),
      );
      expect(find.text('img'), findsOneWidget);
      expect(find.text('plate I — the kettle'), findsOneWidget);
      final frame = tester.getRect(find.byType(DrawkitSurface).first);
      final caption = tester.getRect(find.text('plate I — the kettle'));
      expect(caption.top > frame.bottom, isTrue);
      expect(tester.getRect(find.text('img')).left - frame.left, closeTo(8, 1));
    });

    testWidgets('a captionless figure is just the frame', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitFigure(child: SizedBox(width: 60, height: 40))),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('DrawkitHeading', () {
    testWidgets('scales with the level', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrawkitHeading(text: 'Big'),
              DrawkitHeading(text: 'Medium', level: 2),
              DrawkitHeading(text: 'Small', level: 3),
            ],
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Big')).style!.fontSize, 28);
      expect(tester.widget<Text>(find.text('Medium')).style!.fontSize, 22);
      expect(tester.widget<Text>(find.text('Small')).style!.fontSize, 18);
    });

    testWidgets('underline adds the pen rule', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitHeading(text: 'Ruled', underline: true)),
      );
      expect(
        find.descendant(
          of: find.byType(DrawkitHeading),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });
  });

  group('DrawkitRating', () {
    double starX(int i) => i * (26 + 4) + 13;

    testWidgets('tapping a star reports that count', (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        host(DrawkitRating(value: 1, onChanged: picked.add)),
      );
      final origin = tester.getTopLeft(find.byType(DrawkitRating));
      await tester.tapAt(origin + Offset(starX(2), 13));
      await tester.pump();
      expect(picked, [3]);
    });

    testWidgets('tapping the current value clears one', (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        host(DrawkitRating(value: 3, onChanged: picked.add)),
      );
      final origin = tester.getTopLeft(find.byType(DrawkitRating));
      await tester.tapAt(origin + Offset(starX(2), 13));
      await tester.pump();
      expect(picked, [2]);
    });

    testWidgets('a null onChanged makes it read-only', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(host(const DrawkitRating(value: 3)));
      final origin = tester.getTopLeft(find.byType(DrawkitRating));
      await tester.tapAt(origin + Offset(starX(2), 13));
      await tester.pump();
      final node = tester.getSemantics(find.byType(DrawkitRating));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.value, '3 of 5 stars');
      semanticsHandle.dispose();
    });

    testWidgets('announces slider value and increase handler', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final picked = <int>[];
      await tester.pumpWidget(
        host(DrawkitRating(value: 2, onChanged: picked.add)),
      );
      final node = tester.getSemantics(find.byType(DrawkitRating));
      expect(node.value, '2 of 5 stars');
      expect(node.increasedValue, '3 of 5 stars');
      tester.semantics.performAction(
        find.semantics.byLabel('rating'),
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(picked, [3]);
      semanticsHandle.dispose();
    });
  });

  group('DrawkitDoodle', () {
    testWidgets('is invisible to semantics', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DrawkitDoodle(kind: DrawkitDoodleKind.star)),
      );
      expect(find.bySemanticsLabel(RegExp(r'.')), findsNothing);
      semanticsHandle.dispose();
    });

    testWidgets('builds the right number of strokes per kind', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitDoodle(kind: DrawkitDoodleKind.burst)),
      );
      final surface = tester.widget<DrawkitSurface>(
        find.byType(DrawkitSurface),
      );
      final layers = surface.builder(
        const Size(40, 40),
        const RoughOptions(seed: 7, roughness: 1, boil: 0),
      );
      expect(layers, hasLength(8));

      await tester.pumpWidget(
        host(const DrawkitDoodle(kind: DrawkitDoodleKind.star)),
      );
      final star = tester.widget<DrawkitSurface>(find.byType(DrawkitSurface));
      expect(
        star.builder(
          const Size(40, 40),
          const RoughOptions(seed: 7, roughness: 1, boil: 0),
        ),
        hasLength(1),
      );
    });

    testWidgets('sizes itself square', (tester) async {
      await tester.pumpWidget(
        host(
          const Center(
            child: DrawkitDoodle(kind: DrawkitDoodleKind.spiral, size: 64),
          ),
        ),
      );
      expect(tester.getSize(find.byType(DrawkitDoodle)), const Size(64, 64));
    });
  });

  group('DrawkitMarquee', () {
    Future<double> dx(WidgetTester tester) async {
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(DrawkitMarquee),
          matching: find.byType(Transform),
        ),
      );
      return transform.transform.storage[12];
    }

    testWidgets('slides a copy behind the seam', (tester) async {
      await tester.pumpWidget(
        host(const DrawkitMarquee(child: Text('all work and no play'))),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('all work and no play'), findsNWidgets(2));
      final t0 = await dx(tester);
      await tester.pump(const Duration(milliseconds: 400));
      final t1 = await dx(tester);
      expect(t1 < t0, isTrue);
    });

    testWidgets('mirrors the flow in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitMarquee(child: Text('كل العمل ولا لعب')),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(await dx(tester) > 0, isTrue);
    });

    testWidgets('parks under reduced motion', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const DrawkitMarquee(child: Text('still'))),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(await dx(tester), 0);
    });
  });
}

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget host(Widget child) => harness.host(child, width: 320);

  group('DrawkitDivider', () {
    testWidgets('stretches and disposes cleanly', (tester) async {
      await tester.pumpWidget(host(const DrawkitDivider()));
      expect(tester.getSize(find.byType(DrawkitDivider)).height, 10);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('DrawkitCard', () {
    testWidgets('pads its child by 16 and wraps it in a surface', (
      tester,
    ) async {
      await tester.pumpWidget(host(const DrawkitCard(child: Text('inside'))));
      expect(find.text('inside'), findsOneWidget);
      expect(find.byType(DrawkitSurface), findsOneWidget);
      final size = tester.getSize(find.text('inside'));
      final cardSize = tester.getSize(find.byType(DrawkitCard));
      expect(cardSize.width - size.width, 32);
    });
  });

  group('DrawkitBadge', () {
    testWidgets('renders both variants', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrawkitBadge(child: Text('v1')),
              DrawkitBadge(
                variant: DrawkitBadgeVariant.scribble,
                child: Text('v2'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('v1'), findsOneWidget);
      expect(find.text('v2'), findsOneWidget);
    });
  });

  group('DrawkitList', () {
    testWidgets('draws one surface per item', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitList(
            children: [Text('first'), Text('second'), Text('third')],
          ),
        ),
      );
      expect(find.text('second'), findsOneWidget);
      expect(find.byType(DrawkitSurface), findsNWidgets(3));
    });

    testWidgets('check marker variant renders', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitList(
            marker: DrawkitListMarker.check,
            children: [Text('done')],
          ),
        ),
      );
      expect(find.byType(DrawkitSurface), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

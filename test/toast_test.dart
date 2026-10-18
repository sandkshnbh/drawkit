import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget routeHost(
    Widget Function(BuildContext context) home, {
    TextDirection direction = TextDirection.ltr,
  }) => harness.routeHost(home, direction: direction);

  group('DrawkitToast', () {
    testWidgets('appears, then auto-dismisses after its duration', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      showDrawkitToast(ctx, message: 'saved to the sketchbook');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('saved to the sketchbook'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.text('saved to the sketchbook'), findsNothing);
    });

    testWidgets('the handle closes early exactly once', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      );

      final handle = showDrawkitToast(ctx, message: 'hurry');
      await tester.pump();
      handle.close();
      handle.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('hurry'), findsNothing);
    });
  });
}

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart' as harness;

void main() {
  Widget routeHost(
    Widget Function(BuildContext context) home, {
    TextDirection direction = TextDirection.ltr,
  }) => harness.routeHost(home, direction: direction);

  group('DrawkitDialog', () {
    testWidgets('opens over the scrim and pops with a value', (tester) async {
      String? result;
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return Center(
                child: DrawkitButton(
                  onPressed: () async {
                    result = await showDrawkitDialog<String>(
                      context: ctx,
                      child: DrawkitDialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Delete the sketch?'),
                            const SizedBox(height: 14),
                            DrawkitButton(
                              onPressed: () => Navigator.of(ctx).pop('deleted'),
                              child: const Text('yes'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Delete the sketch?'), findsNothing);
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Delete the sketch?'), findsOneWidget);

      await tester.tap(find.text('yes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(result, 'deleted');
      expect(find.text('Delete the sketch?'), findsNothing);
    });

    testWidgets('barrier tap dismisses with null', (tester) async {
      var completed = false;
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return Center(
                child: DrawkitButton(
                  onPressed: () {
                    showDrawkitDialog(
                      context: ctx,
                      child: const DrawkitDialog(child: Text('hi there')),
                    ).whenComplete(() => completed = true);
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('hi there'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(completed, isTrue);
      expect(find.text('hi there'), findsNothing);
    });

    testWidgets('a non-dismissible barrier ignores taps', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return Center(
                child: DrawkitButton(
                  onPressed: () => showDrawkitDialog(
                    context: ctx,
                    barrierDismissible: false,
                    child: const DrawkitDialog(child: Text('stuck')),
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('stuck'), findsOneWidget);
    });
  });

  group('DrawkitSheet', () {
    testWidgets('slides up from the bottom and barrier-taps away', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost(
          (context) => Builder(
            builder: (context) {
              ctx = context;
              return Center(
                child: DrawkitButton(
                  onPressed: () => showDrawkitSheet(
                    context: ctx,
                    child: const Text('sheet body'),
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('sheet body'), findsOneWidget);
      expect(tester.getCenter(find.text('sheet body')).dy, greaterThan(300));

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('sheet body'), findsNothing);
    });

    testWidgets('the end edge is direction-aware', (tester) async {
      Future<Offset> openAt(TextDirection direction) async {
        await tester.pumpWidget(const SizedBox());
        late BuildContext ctx;
        await tester.pumpWidget(
          routeHost(
            (context) => Builder(
              builder: (context) {
                ctx = context;
                return Center(
                  child: DrawkitButton(
                    onPressed: () => showDrawkitSheet(
                      context: ctx,
                      edge: DrawkitSheetEdge.end,
                      child: const Text('drawer'),
                    ),
                    child: const Text('open'),
                  ),
                );
              },
            ),
            direction: direction,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        return tester.getTopLeft(find.text('drawer'));
      }

      final ltr = await openAt(TextDirection.ltr);
      expect(ltr.dx, greaterThan(400));
      final rtl = await openAt(TextDirection.rtl);
      expect(rtl.dx, lessThan(40));
    });
  });
}

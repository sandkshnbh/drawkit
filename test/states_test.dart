import 'dart:async';

import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(
    Widget child, {
    TextDirection direction = TextDirection.ltr,
    bool disableAnimations = false,
  }) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Center(
        child: DrawkitTheme(data: const DrawkitStyle(boil: 0), child: child),
      ),
    ),
  );

  Widget routeHost(
    Widget Function(BuildContext context) home, {
    bool disableAnimations = false,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: DrawkitTheme(
        data: const DrawkitStyle(boil: 0),
        child: Navigator(
          onGenerateRoute: (settings) => PageRouteBuilder(
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) =>
                home(context),
          ),
        ),
      ),
    ),
  );

  group('DrawkitInput validation', () {
    testWidgets('an error replaces the helper', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 260,
            child: DrawkitInput(
              placeholder: 'email',
              helper: 'We never share it.',
              error: 'That address looks off.',
            ),
          ),
        ),
      );

      expect(find.text('That address looks off.'), findsOneWidget);
      expect(find.text('We never share it.'), findsNothing);
      final message = tester.widget<Text>(find.text('That address looks off.'));
      expect(message.style?.color, DrawkitPalette.error);
    });

    testWidgets('a helper shows alone, muted', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 260,
            child: DrawkitInput(helper: 'We never share it.'),
          ),
        ),
      );

      final message = tester.widget<Text>(find.text('We never share it.'));
      expect(message.style?.color, DrawkitPalette.inkMuted);
    });

    testWidgets('the error message is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 260,
            child: DrawkitInput(error: 'Required field.'),
          ),
        ),
      );

      final node = tester.getSemantics(find.text('Required field.'));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('clearing the error brings the helper back', (tester) async {
      Widget field(String? error) => host(
        SizedBox(
          width: 260,
          child: DrawkitInput(helper: 'We never share it.', error: error),
        ),
      );

      await tester.pumpWidget(field('Required field.'));
      expect(find.text('Required field.'), findsOneWidget);

      await tester.pumpWidget(field(null));
      expect(find.text('Required field.'), findsNothing);
      expect(find.text('We never share it.'), findsOneWidget);
    });

    testWidgets('the textarea shares the same message chrome', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 260,
            child: DrawkitTextarea(error: 'Tell us a little more.'),
          ),
        ),
      );

      expect(find.text('Tell us a little more.'), findsOneWidget);
    });
  });

  group('DrawkitEmpty', () {
    testWidgets('renders doodle, title, message and action', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        host(
          DrawkitEmpty(
            title: 'No sketches yet',
            message: 'Everything you draw will land here.',
            action: DrawkitButton(
              onPressed: () => pressed = true,
              child: const Text('Start one'),
            ),
          ),
        ),
      );

      expect(find.byType(DrawkitDoodle), findsOneWidget);
      expect(find.text('No sketches yet'), findsOneWidget);
      expect(find.text('Everything you draw will land here.'), findsOneWidget);
      await tester.tap(find.text('Start one'));
      expect(pressed, isTrue);
    });

    testWidgets('the title is a header for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const DrawkitEmpty(title: 'No sketches yet')),
      );

      final node = tester.getSemantics(find.text('No sketches yet'));
      expect(node.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('lays out in RTL without changing content', (tester) async {
      await tester.pumpWidget(
        host(
          const DrawkitEmpty(
            title: 'لا توجد رسومات بعد',
            message: 'كل ما ترسمه سيظهر هنا.',
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(find.text('لا توجد رسومات بعد'), findsOneWidget);
    });
  });

  group('DrawkitToast actions', () {
    testWidgets('an action runs then closes the toast', (tester) async {
      var undone = false;
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost((context) {
          ctx = context;
          return Center(
            child: DrawkitButton(
              onPressed: () {
                showDrawkitToast(
                  ctx,
                  message: 'Note deleted',
                  action: DrawkitToastAction(
                    label: 'Undo',
                    onPressed: () => undone = true,
                  ),
                );
              },
              child: const Text('toast'),
            ),
          );
        }),
      );

      await tester.tap(find.text('toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Note deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(undone, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Note deleted'), findsNothing);
    });

    testWidgets('only actionless toasts let taps pass through', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost((context) {
          ctx = context;
          return Center(
            child: DrawkitButton(
              onPressed: () => showDrawkitToast(ctx, message: 'saved'),
              child: const Text('plain'),
            ),
          );
        }),
      );

      await tester.tap(find.text('plain'));
      await tester.pump();
      expect(
        find.ancestor(
          of: find.text('saved'),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 3000));

      showDrawkitToast(
        ctx,
        message: 'deleted',
        action: DrawkitToastAction(label: 'Undo', onPressed: () {}),
      );
      await tester.pump();
      expect(
        find.ancestor(
          of: find.text('deleted'),
          matching: find.byType(IgnorePointer),
        ),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 6000));
    });

    testWidgets('the action carries button semantics', (tester) async {
      final handle = tester.ensureSemantics();
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost((context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      );

      showDrawkitToast(
        ctx,
        message: 'deleted',
        action: DrawkitToastAction(label: 'Undo', onPressed: () {}),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final node = tester.getSemantics(find.bySemanticsLabel('Undo'));
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
      await tester.pump(const Duration(milliseconds: 6000));
    });

    testWidgets('an action toast lingers longer than a plain one', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        routeHost((context) {
          ctx = context;
          return const SizedBox.shrink();
        }),
      );

      showDrawkitToast(
        ctx,
        message: 'deleted',
        action: DrawkitToastAction(label: 'Undo', onPressed: () {}),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2600));
      expect(find.text('deleted'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2800));
      await tester.pumpAndSettle();
      expect(find.text('deleted'), findsNothing);
    });
  });

  group('DrawkitRefresh', () {
    Widget scrollable({required Future<void> Function() onRefresh}) =>
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: DrawkitTheme(
              data: const DrawkitStyle(boil: 0),
              child: SizedBox(
                height: 400,
                child: DrawkitRefresh(
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < 30; i++)
                        SizedBox(height: 40, child: Text('row $i')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('an armed pull refreshes once and spins while pending', (
      tester,
    ) async {
      final completer = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        scrollable(
          onRefresh: () {
            calls++;
            return completer.future;
          },
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 120));
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(DrawkitSpinner), findsOneWidget);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(DrawkitSpinner), findsNothing);
    });

    testWidgets('a short pull settles back without refreshing', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        scrollable(
          onRefresh: () {
            calls++;
            return Future<void>.value();
          },
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 40));
      await tester.pump();
      expect(calls, 0);
      expect(find.byType(DrawkitSpinner), findsNothing);

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(DrawkitDoodle), findsNothing);
    });

    testWidgets('mid-drag the arrow doodle follows the pull', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        scrollable(
          onRefresh: () {
            calls++;
            return Future<void>.value();
          },
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(find.byType(DrawkitDoodle), findsOneWidget);
      expect(find.byType(DrawkitSpinner), findsNothing);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(calls, 0);
      expect(find.byType(DrawkitDoodle), findsNothing);
    });

    testWidgets('reduced motion refreshes without animating', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: DrawkitTheme(
              data: const DrawkitStyle(boil: 0),
              child: SizedBox(
                height: 400,
                child: DrawkitRefresh(
                  onRefresh: () async => calls++,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < 30; i++)
                        SizedBox(height: 40, child: Text('row $i')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 120));
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(DrawkitSpinner), findsNothing);
    });
  });
}

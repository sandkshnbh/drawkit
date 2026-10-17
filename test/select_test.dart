import 'package:drawkit/drawkit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fruits = [
    DrawkitSelectOption(value: 'apple', label: 'Apple'),
    DrawkitSelectOption(value: 'banana', label: 'Banana'),
    DrawkitSelectOption(value: 'cherry', label: 'Cherry'),
  ];

  Widget host(Widget child) => WidgetsApp(
    color: DrawkitPalette.light.paper,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        ),
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: DrawkitTheme(
        data: const DrawkitStyle(boil: 0),
        child: Center(child: SizedBox(width: 260, child: child)),
      ),
    ),
  );

  testWidgets('shows the placeholder until a value is chosen', (tester) async {
    await tester.pumpWidget(
      host(
        const DrawkitSelect<String>(
          options: fruits,
          value: null,
          onChanged: _noop,
        ),
      ),
    );
    expect(find.text('choose…'), findsOneWidget);
  });

  testWidgets('opens on tap and lists every option', (tester) async {
    await tester.pumpWidget(
      host(
        DrawkitSelect<String>(
          options: fruits,
          value: 'apple',
          onChanged: _noop,
        ),
      ),
    );
    expect(find.text('Apple'), findsOneWidget);
    await tester.tap(find.byType(DrawkitSelect<String>));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Cherry'), findsOneWidget);
  });

  testWidgets('picking an option reports it and closes the menu', (
    tester,
  ) async {
    final picked = <String>[];
    await tester.pumpWidget(
      host(
        DrawkitSelect<String>(
          options: fruits,
          value: 'apple',
          onChanged: picked.add,
        ),
      ),
    );
    await tester.tap(find.byType(DrawkitSelect<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(picked, ['banana']);
    expect(find.text('Cherry'), findsNothing);
  });

  testWidgets('an outside tap closes the menu without picking', (tester) async {
    final picked = <String>[];
    await tester.pumpWidget(
      host(
        DrawkitSelect<String>(
          options: fruits,
          value: 'apple',
          onChanged: picked.add,
        ),
      ),
    );
    await tester.tap(find.byType(DrawkitSelect<String>));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);
    await tester.tapAt(const Offset(60, 60));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsNothing);
    expect(picked, isEmpty);
  });

  testWidgets('keyboard opens with enter and escape closes', (tester) async {
    await tester.pumpWidget(
      host(
        DrawkitSelect<String>(
          options: fruits,
          value: 'apple',
          autofocus: true,
          onChanged: _noop,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Cherry'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Cherry'), findsNothing);
  });

  testWidgets('disabled select never opens', (tester) async {
    await tester.pumpWidget(
      host(
        const DrawkitSelect<String>(
          options: fruits,
          value: 'apple',
          onChanged: null,
        ),
      ),
    );
    await tester.tap(find.byType(DrawkitSelect<String>), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsNothing);
  });

  testWidgets('disposes focus node cleanly', (tester) async {
    await tester.pumpWidget(
      host(
        DrawkitSelect<String>(
          options: fruits,
          value: 'apple',
          onChanged: _noop,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
  });
}

void _noop(String _) {}

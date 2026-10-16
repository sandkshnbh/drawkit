import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: DrawkitTheme(
        data: const DrawkitStyle(boil: 0),
        child: SizedBox(width: 240, child: child),
      ),
    ),
  );

  testWidgets('underline wraps and draws per line box', (tester) async {
    await tester.pumpWidget(
      host(
        const DrawkitUnderline(
          text: 'The pen keeps going across a very long sentence that has to wrap onto more than one line to be drawn.',
        ),
      ),
    );
    final size = tester.getSize(find.byType(DrawkitUnderline));
    expect(size.height, greaterThan(40));
    expect(find.byType(DrawkitSurface), findsOneWidget);
  });

  testWidgets('highlight renders the wash and keeps the text', (tester) async {
    await tester.pumpWidget(
      host(
        const DrawkitHighlight(
          text: 'important marker note',
          style: DrawkitStyle(boil: 0),
        ),
      ),
    );
    expect(find.text('important marker note'), findsOneWidget);
  });

  testWidgets('circle sizes to its text', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DrawkitTheme(
            data: const DrawkitStyle(boil: 0),
            child: const DrawkitCircle(text: 'circled'),
          ),
        ),
      ),
    );
    expect(find.text('circled'), findsOneWidget);
    final size = tester.getSize(find.byType(DrawkitCircle));
    expect(size.width, greaterThan(0));
    expect(size.width, lessThan(200));
  });

  testWidgets('empty text draws nothing and does not crash', (tester) async {
    await tester.pumpWidget(host(const DrawkitUnderline(text: '')));
    expect(find.byType(DrawkitSurface), findsOneWidget);
  });

  testWidgets('disposes cleanly', (tester) async {
    await tester.pumpWidget(host(const DrawkitCircle(text: 'bye')));
    await tester.pumpWidget(const SizedBox());
  });
}

import 'package:drawkit/drawkit.dart';
import 'package:drawkit/src/engine/rough.dart' show sampleLine;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
      WidgetsApp(
        color: DrawkitPalette.light.paper,
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
              settings: settings,
              transitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  builder(context),
            ),
        home: Directionality(
          textDirection: direction,
          child: DrawkitTheme(
            data: const DrawkitStyle(boil: 0),
            child: Center(child: SizedBox(width: 360, child: child)),
          ),
        ),
      );

  Widget routeHost(Widget Function(BuildContext context) home) =>
      Directionality(
        textDirection: TextDirection.ltr,
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
      );

  group('engine guards', () {
    test('smooth tolerates an empty point list', () {
      expect(smooth(const <Offset>[], close: true).getBounds(), Rect.zero);
    });

    test('roughEllipse refuses degenerate radii', () {
      const options = RoughOptions(seed: 7);
      expect(roughEllipse(0, 0, 0, 10, options).getBounds(), Rect.zero);
      expect(roughEllipse(0, 0, 10, -1, options).getBounds(), Rect.zero);
      expect(roughEllipse(0, 0, 10, 10, options).getBounds().isEmpty, isFalse);
    });

    test('sampleLine survives a zero step', () {
      expect(sampleLine(0, 0, 10, 0, 0).length, 3);
    });
  });

  testWidgets('a longer stagger child list re-keys without throwing', (
    tester,
  ) async {
    Widget app(List<Widget> children) =>
        host(DrawkitStagger(children: children));
    await tester.pumpWidget(app(const [Text('a'), Text('b')]));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(app(const [Text('a'), Text('b'), Text('c')]));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('rating taps map through the reading direction', (tester) async {
    var ltr = 0;
    await tester.pumpWidget(
      host(DrawkitRating(value: 0, onChanged: (v) => ltr = v)),
    );
    var rect = tester.getRect(find.byType(DrawkitRating));
    await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
    await tester.pump();
    expect(ltr, 1);

    var rtl = 0;
    await tester.pumpWidget(
      host(
        DrawkitRating(value: 0, onChanged: (v) => rtl = v),
        direction: TextDirection.rtl,
      ),
    );
    rect = tester.getRect(find.byType(DrawkitRating));
    await tester.tapAt(Offset(rect.right - 8, rect.center.dy));
    await tester.pump();
    expect(rtl, 1);
  });

  testWidgets('a hidden floating nav ignores hit tests', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        Column(
          children: [
            SizedBox(
              height: 300,
              child: ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 30; i++)
                    SizedBox(height: 40, child: Text('row $i')),
                ],
              ),
            ),
            DrawkitFloatingNavBar(
              destinations: const [
                DrawkitNavDestination(label: 'Home'),
                DrawkitNavDestination(label: 'Work'),
              ],
              selected: 0,
              onChanged: (_) {},
              hideOnScroll: true,
              scrollController: controller,
              animate: false,
            ),
          ],
        ),
      ),
    );
    final bar = find.byType(DrawkitFloatingNavBar);
    IgnorePointer ignore() => tester.widget<IgnorePointer>(
      find.descendant(of: bar, matching: find.byType(IgnorePointer)).first,
    );
    expect(ignore().ignoring, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(ignore().ignoring, isTrue);
    expect(
      tester
          .widget<ExcludeSemantics>(
            find
                .descendant(of: bar, matching: find.byType(ExcludeSemantics))
                .first,
          )
          .excluding,
      isTrue,
    );
  });

  testWidgets('a dialog route mounts one themed frame', (tester) async {
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
    final future = showDrawkitDialog<Object>(
      context: ctx,
      child: const Text('hello'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(DrawkitDialog), findsOneWidget);

    final textStyle = tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('hello'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;
    expect(textStyle.color, DrawkitPalette.light.ink);
    expect(textStyle.decoration, TextDecoration.none);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await future, isNull);
  });

  testWidgets('the command palette rides a single dialog frame', (
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
    final future = showDrawkitCommandPalette<String>(
      context: ctx,
      commands: const [DrawkitCommand(label: 'Open sketch', value: 'open')],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(DrawkitDialog), findsOneWidget);
    expect(find.text('Open sketch'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await future, isNull);
  });

  testWidgets('month paging keeps the keyboard cursor in view', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      host(
        DrawkitDatePicker(
          value: DateTime(2024, 1, 31),
          today: DateTime(2024, 1, 15),
          onChanged: (date) => picked = date,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel(RegExp('next month')));
    await tester.pump();
    expect(find.text('February 2024'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked, DateTime(2024, 2, 29));
  });

  testWidgets('the fab label inks like the outline', (tester) async {
    await tester.pumpWidget(host(const DrawkitFab(child: Text('+'))));
    final styles = tester.widgetList<DefaultTextStyle>(
      find.ancestor(
        of: find.text('+'),
        matching: find.byType(DefaultTextStyle),
      ),
    );
    expect(
      styles.any((s) => s.style.color == DrawkitPalette.light.pen),
      isTrue,
    );
  });

  testWidgets('a long menu scrolls instead of overflowing', (tester) async {
    await tester.pumpWidget(
      host(
        DrawkitMenu(
          items: [
            for (var i = 0; i < 40; i++)
              DrawkitMenuItem(label: 'item $i', onSelected: () {}),
          ],
          child: const Text('edit'),
        ),
      ),
    );
    await tester.tap(find.text('edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('item 0'), findsOneWidget);

    await tester.drag(find.text('item 0'), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final last = tester.getRect(find.text('item 39'));
    expect(last.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
  });

  testWidgets('a disabled input never takes focus', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(DrawkitInput(focusNode: node, enabled: false, placeholder: 'name')),
    );
    await tester.tap(find.byType(EditableText), warnIfMissed: false);
    await tester.pump();
    expect(node.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('crumb taps land across the whole touch target', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        DrawkitBreadcrumb(
          items: [
            DrawkitBreadcrumbItem(label: 'Home', onTap: () => taps++),
            const DrawkitBreadcrumbItem(label: 'Now'),
          ],
        ),
      ),
    );
    final rect = tester.getRect(
      find
          .descendant(
            of: find.byType(DrawkitBreadcrumb),
            matching: find.byType(DrawkitTapTarget),
          )
          .first,
    );
    await tester.tapAt(Offset(rect.left + 2, rect.top + 2));
    await tester.pump();
    expect(taps, 1);
  });
}

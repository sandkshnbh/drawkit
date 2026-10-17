import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(
        color: DrawkitPalette.ink,
        fontSize: 14,
        height: 1.4,
        decoration: TextDecoration.none,
      ),
      child: DrawkitTheme(
        data: const DrawkitStyle(boil: 0),
        child: ColoredBox(color: DrawkitPalette.paper, child: child),
      ),
    ),
  );

  Widget sample() => host(
    Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawkitButton(
            semanticLabel: 'save',
            onPressed: () {},
            child: const Text('save'),
          ),
          const SizedBox(height: 10),
          DrawkitIconButton(
            semanticLabel: 'close',
            onPressed: () {},
            child: const Text('✕'),
          ),
          const SizedBox(height: 10),
          DrawkitFab(
            semanticLabel: 'new page',
            onPressed: () {},
            child: const Text('+'),
          ),
          const SizedBox(height: 10),
          DrawkitCheckbox(
            value: true,
            semanticLabel: 'ruled',
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          DrawkitRadio<String>(
            value: 'a',
            groupValue: 'a',
            semanticLabel: 'option a',
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          DrawkitToggle(
            value: true,
            semanticLabel: 'dark ink',
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          DrawkitSlider(value: 0.5, semanticLabel: 'width', onChanged: (_) {}),
          const SizedBox(height: 10),
          DrawkitStepper(
            value: 2,
            max: 10,
            semanticLabel: 'copies',
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          const SizedBox(width: 260, child: DrawkitInput(placeholder: 'name')),
          const SizedBox(height: 10),
          DrawkitChip(
            selected: true,
            onChanged: (_) {},
            child: const Text('tag'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 300,
            child: DrawkitSegmentedButton<String>(
              segments: const [
                DrawkitSegment(value: 'pen', label: 'pen'),
                DrawkitSegment(value: 'ink', label: 'ink'),
                DrawkitSegment(value: 'wash', label: 'wash'),
              ],
              selected: 'pen',
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 10),
          DrawkitTabs(
            labels: const ['Sketch', 'Ink', 'Export'],
            active: 0,
            onChanged: (_) {},
          ),
          const SizedBox(height: 10),
          DrawkitPager(count: 5, page: 0, onPage: (_) {}),
          const SizedBox(height: 10),
          DrawkitRating(value: 3, onChanged: (_) {}),
          const SizedBox(height: 10),
          DrawkitAccordion(
            sections: [
              DrawkitAccordionSection(
                title: 'how it works',
                child: const Text('a rough line, drawn twice.'),
              ),
              DrawkitAccordionSection(
                title: 'shortcuts',
                child: const Text('tab moves focus.'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(label: 'docs', onTap: () {}),
              DrawkitBreadcrumbItem(label: 'guides', onTap: () {}),
              const DrawkitBreadcrumbItem(label: 'here'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            width: 160,
            child: DrawkitNavRail(
              destinations: const [
                DrawkitNavDestination(label: 'Home'),
                DrawkitNavDestination(label: 'Notes'),
              ],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 10),
          DrawkitMenu(
            items: [
              DrawkitMenuItem(label: 'Cut', onSelected: () {}),
              DrawkitMenuItem(label: 'Copy', onSelected: () {}),
            ],
            child: const Text('view'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 220,
            child: DrawkitSelect<String>(
              options: const [
                DrawkitSelectOption(value: 'ink', label: 'Ink'),
                DrawkitSelectOption(value: 'wash', label: 'Wash'),
              ],
              value: 'ink',
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 10),
          DrawkitDatePicker(
            value: DateTime(2026, 6, 15),
            today: DateTime(2026, 6, 15),
            onChanged: (_) {},
          ),
        ],
      ),
    ),
  );

  Future<SemanticsHandle> pumpSample(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(sample());
    await tester.pump();
    return semantics;
  }

  testWidgets('every control meets the Android tap target guideline', (
    tester,
  ) async {
    final semantics = await pumpSample(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('every control meets the iOS tap target guideline', (
    tester,
  ) async {
    final semantics = await pumpSample(tester);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('every tappable control carries a semantic label', (
    tester,
  ) async {
    final semantics = await pumpSample(tester);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('text keeps WCAG contrast on the paper', (tester) async {
    final semantics = await pumpSample(tester);
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('large text scales the sample without overflow', (tester) async {
    tester.view.physicalSize = const Size(1500, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SingleChildScrollView(child: sample()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

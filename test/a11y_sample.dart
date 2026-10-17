import 'package:drawkit/drawkit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget a11yHost(
  Widget child, {
  DrawkitPalette palette = DrawkitPalette.light,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: DefaultTextStyle(
    style: TextStyle(
      color: palette.ink,
      fontSize: 14,
      height: 1.4,
      decoration: TextDecoration.none,
    ),
    child: DrawkitTheme(
      data: palette.style.copyWith(boil: 0),
      child: ColoredBox(color: palette.paper, child: child),
    ),
  ),
);

Widget a11ySample({DrawkitPalette palette = DrawkitPalette.light}) => a11yHost(
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
        DrawkitCheckbox(value: true, semanticLabel: 'ruled', onChanged: (_) {}),
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
        const SizedBox(height: 10),
        DrawkitFloatingNavBar(
          destinations: const [
            DrawkitNavDestination(label: 'Feeds', icon: Text('✉'), badge: 2),
            DrawkitNavDestination(label: 'Notes', icon: Text('✎')),
            DrawkitNavDestination(label: 'Files', icon: Text('▤')),
          ],
          selected: 0,
          onChanged: (_) {},
        ),
        const SizedBox(height: 10),
        DrawkitFabMenu(
          semanticLabel: 'quick actions',
          items: [
            DrawkitFabMenuItem(label: 'New note', onPressed: () {}),
            DrawkitFabMenuItem(label: 'New sketch', onPressed: () {}),
          ],
        ),
      ],
    ),
  ),
  palette: palette,
);

Future<SemanticsHandle> pumpA11ySample(
  WidgetTester tester, {
  DrawkitPalette palette = DrawkitPalette.light,
}) async {
  tester.view.physicalSize = const Size(1500, 2900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final semantics = tester.ensureSemantics();
  await tester.pumpWidget(a11ySample(palette: palette));
  await tester.pump();
  return semantics;
}

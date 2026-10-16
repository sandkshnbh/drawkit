import 'dart:ui' show PointerDeviceKind;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const DrawkitGalleryApp());

const _sidebarWidth = 210.0;

class DrawkitGalleryApp extends StatelessWidget {
  const DrawkitGalleryApp({super.key});

  @override
  Widget build(BuildContext context) => WidgetsApp(
    title: 'drawkit gallery',
    color: DrawkitPalette.paper,
    debugShowCheckedModeBanner: false,
    pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
        PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        ),
    home: const Gallery(),
  );
}

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: const TextStyle(
      color: DrawkitPalette.ink,
      fontSize: 14,
      height: 1.4,
      decoration: TextDecoration.none,
    ),
    child: ColoredBox(
      color: DrawkitPalette.paper,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            pages: galleryPages,
            selected: _page,
            onSelect: (i) => setState(() => _page = i),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _DragScrollBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      galleryPages[_page].title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: DrawkitPalette.ink,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      galleryPages[_page].subtitle,
                      style: const TextStyle(
                        color: DrawkitPalette.inkMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    galleryPages[_page].builder(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class GalleryPage {
  const GalleryPage(this.title, this.subtitle, this.builder);

  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

/// Filled in per milestone; see the individual page builders below.
final List<GalleryPage> galleryPages = [
  GalleryPage(
    'Surface',
    'The shared sketch surface: seeded chrome behind any child, one boil clock.',
    (context) => const SurfacePage(),
  ),
  GalleryPage(
    'Button',
    'Three variants, four states, three tones — real widget behaviour in front.',
    (context) => const ButtonPage(),
  ),
  GalleryPage(
    'Checkbox · Radio · Toggle',
    'The choice controls: check draws on, dot scales in, knob travels.',
    (context) => const ChoicePage(),
  ),
  GalleryPage(
    'Input · Textarea',
    'Sketch outline behind a real EditableText; focus ring, placeholder, growth.',
    (context) => const FieldPage(),
  ),
];

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.pages,
    required this.selected,
    required this.onSelect,
  });

  final List<GalleryPage> pages;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: _sidebarWidth,
    decoration: const BoxDecoration(
      color: DrawkitPalette.surface,
      border: Border(
        right: BorderSide(color: DrawkitPalette.inkFaint, width: 1),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Text(
            'drawkit',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: DrawkitPalette.pen,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: pages.length,
            itemBuilder: (context, i) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                color: i == selected ? DrawkitPalette.paper : null,
                child: Text(
                  pages[i].title,
                  style: TextStyle(
                    color: i == selected
                        ? DrawkitPalette.pen
                        : DrawkitPalette.inkMuted,
                    fontWeight: i == selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DragScrollBehavior extends ScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

// ---------------------------------------------------------------------------
// Surface page

class SurfacePage extends StatefulWidget {
  const SurfacePage({super.key});

  @override
  State<SurfacePage> createState() => _SurfacePageState();
}

class _SurfacePageState extends State<SurfacePage> {
  double roughness = 1;
  double boil = 0.3;
  int? seed = 42;
  bool animate = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 360,
        height: 130,
        child: DrawkitSurface(
          builder: (size, options) => [
            DrawkitLayer(
              roughRoundedRect(
                3,
                3,
                size.width - 6,
                size.height - 6,
                10,
                options,
              ),
              Paint()
                ..color = DrawkitPalette.pen
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round,
            ),
          ],
          style: DrawkitStyle(roughness: roughness, boil: boil, seed: seed),
          seed: seed,
          animate: animate,
          resketchOnPointer: true,
          child: const Center(child: Text('hover me — I am redrawn')),
        ),
      ),
      const SizedBox(height: 24),
      _NumberStepper(
        label: 'roughness',
        value: roughness,
        step: 0.1,
        min: 0,
        max: 3,
        onChanged: (v) => setState(() => roughness = v),
      ),
      _NumberStepper(
        label: 'boil',
        value: boil,
        step: 0.1,
        min: 0,
        max: 1.5,
        onChanged: (v) => setState(() => boil = v),
      ),
      _NumberStepper(
        label: 'seed',
        value: seed?.toDouble() ?? -1,
        step: 1,
        min: -1,
        max: 1000000,
        onChanged: (v) => setState(() => seed = v < 0 ? null : v.round()),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          DrawkitButton(
            onPressed: () => setState(() => animate = !animate),
            child: Text(animate ? 'boil: on' : 'boil: off'),
          ),
        ],
      ),
    ],
  );
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double step;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: DrawkitPalette.inkMuted,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        DrawkitButton(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          onPressed: value <= min
              ? null
              : () => onChanged((value - step).clamp(min, max)),
          child: const Text('−'),
        ),
        SizedBox(
          width: 90,
          child: Center(
            child: Text(
              value < 0 ? 'random' : value.toStringAsFixed(step < 1 ? 1 : 0),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        DrawkitButton(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          onPressed: value >= max
              ? null
              : () => onChanged((value + step).clamp(min, max)),
          child: const Text('+'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Button page

class ButtonPage extends StatefulWidget {
  const ButtonPage({super.key});

  @override
  State<ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  DrawkitButtonState state = DrawkitButtonState.idle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 18,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final variant in DrawkitButtonVariant.values)
            DrawkitButton(
              variant: variant,
              onPressed: () {},
              child: Text(variant.name),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 18,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final tone in DrawkitTone.values)
            DrawkitButton(
              tone: tone,
              onPressed: () {},
              child: Text('tone: ${tone.name}'),
            ),
          const DrawkitButton(onPressed: null, child: Text('disabled')),
        ],
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          for (final s in DrawkitButtonState.values)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DrawkitButton(
                state: s,
                onPressed: () {},
                child: Text('state: ${s.name}'),
              ),
            ),
        ],
      ),
      const SizedBox(height: 26),
      Wrap(
        spacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DrawkitButton(
            variant: DrawkitButtonVariant.solid,
            state: state,
            onPressed: () {
              setState(() {
                state = switch (state) {
                  DrawkitButtonState.idle => DrawkitButtonState.loading,
                  DrawkitButtonState.loading => DrawkitButtonState.success,
                  DrawkitButtonState.success => DrawkitButtonState.error,
                  DrawkitButtonState.error => DrawkitButtonState.idle,
                };
              });
            },
            child: Text('cycle state: ${state.name}'),
          ),
          const Text(
            'Tab to me for the focus ring →',
            style: TextStyle(
              color: DrawkitPalette.inkMuted,
              decoration: TextDecoration.none,
            ),
          ),
          const DrawkitButton(
            autofocus: false,
            onPressed: _noop,
            child: Text('focus me'),
          ),
        ],
      ),
    ],
  );
}

void _noop() {}

// ---------------------------------------------------------------------------
// Choice page

class ChoicePage extends StatefulWidget {
  const ChoicePage({super.key});

  @override
  State<ChoicePage> createState() => _ChoicePageState();
}

class _ChoicePageState extends State<ChoicePage> {
  bool terms = true;
  bool newsletter = false;
  bool darkInk = false;
  String? fruit = 'apple';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ChoiceRow(
        control: DrawkitCheckbox(
          value: terms,
          onChanged: (v) => setState(() => terms = v),
        ),
        text: 'I accept the scribbles (checked, with the check drawn on)',
        onTap: () => setState(() => terms = !terms),
      ),
      _ChoiceRow(
        control: DrawkitCheckbox(
          value: newsletter,
          onChanged: (v) => setState(() => newsletter = v),
        ),
        text: 'Send me one doodle a week',
        onTap: () => setState(() => newsletter = !newsletter),
      ),
      _ChoiceRow(
        control: const DrawkitCheckbox(value: false, onChanged: null),
        text: 'Disabled checkbox — the ink stays, the hand stops',
        onTap: null,
      ),
      const SizedBox(height: 26),
      for (final f in const ['apple', 'banana', 'cherry'])
        _ChoiceRow(
          control: DrawkitRadio<String>(
            value: f,
            groupValue: fruit,
            onChanged: (v) => setState(() => fruit = v),
          ),
          text: 'Radio: $f',
          onTap: () => setState(() => fruit = f),
        ),
      const SizedBox(height: 26),
      _ChoiceRow(
        control: DrawkitToggle(
          value: darkInk,
          onChanged: (v) => setState(() => darkInk = v),
        ),
        text: 'Dark ink (toggle — the knob travels 20px)',
        onTap: () => setState(() => darkInk = !darkInk),
      ),
      _ChoiceRow(
        control: const DrawkitToggle(value: true, onChanged: null),
        text: 'Disabled toggle',
        onTap: null,
      ),
      const SizedBox(height: 18),
      const Text(
        'Tab moves focus, Space/Enter flips — the focus ring answers.',
        style: TextStyle(
          color: DrawkitPalette.inkMuted,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.control,
    required this.text,
    required this.onTap,
  });

  final Widget control;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          control,
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(decoration: TextDecoration.none)),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Field page

class FieldPage extends StatefulWidget {
  const FieldPage({super.key});

  @override
  State<FieldPage> createState() => _FieldPageState();
}

class _FieldPageState extends State<FieldPage> {
  final name = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Name',
        style: TextStyle(
          color: DrawkitPalette.inkMuted,
          decoration: TextDecoration.none,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: 300,
        child: DrawkitInput(
          controller: name,
          placeholder: 'e.g. Scribbly McPenface',
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Notes',
        style: TextStyle(
          color: DrawkitPalette.inkMuted,
          decoration: TextDecoration.none,
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: 420,
        child: DrawkitTextarea(
          controller: notes,
          placeholder: 'What should the pen remember?',
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(height: 22),
      const SizedBox(
        width: 300,
        child: DrawkitInput(
          placeholder: 'disabled — no cursor, no edits',
          enabled: false,
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'name: ${name.text.isEmpty ? '…' : name.text}\nnotes: ${notes.text.isEmpty ? '…' : notes.text.replaceAll('\n', ' ⏎ ')}',
        style: const TextStyle(
          color: DrawkitPalette.inkMuted,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );
}

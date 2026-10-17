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
  bool _rtl = false;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
    child: DefaultTextStyle(
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
              rtl: _rtl,
              onToggleRtl: (v) => setState(() => _rtl = v),
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
  GalleryPage(
    'Select',
    'Chevron in the reserved gutter, overlay menu with sketched frame and check.',
    (context) => const SelectPage(),
  ),
  GalleryPage(
    'Divider · Card · Badge · List',
    'Surface decorations: rules, frames, pills, and per-item markers.',
    (context) => const DecorationsPage(),
  ),
  GalleryPage(
    'Underline · Highlight · Circle',
    'Text decorations drawn per line box, measured with a TextPainter.',
    (context) => const TextPage(),
  ),
  GalleryPage(
    'Arrow · Composites',
    'Chip, tabs, tooltip, alert, steps, kbd, quote, pager — several strokes, one seed.',
    (context) => const CompositePage(),
  ),
  GalleryPage(
    'Motion',
    'Draw-on tracing, staggered lists, and the error shake — one shared pen.',
    (context) => const MotionPage(),
  ),
  GalleryPage(
    'Actions',
    'Segments, slider, stepper, search, icon buttons, and the floating pen.',
    (context) => const ActionsPage(),
  ),
  GalleryPage(
    'Feedback',
    'Dialogs, sheets, toasts, progress bars, spinners, and loading skeletons.',
    (context) => const FeedbackPage(),
  ),
  GalleryPage(
    'Menus',
    'Dropdowns, popovers, an accordion, a command palette, and a date picker.',
    (context) => const MenusPage(),
  ),
  GalleryPage(
    'Structure',
    'App bar, nav rail, bottom bar, breadcrumb, and a ruled table.',
    (context) => const StructurePage(),
  ),
  GalleryPage(
    'Content',
    'Headings, avatars, a captioned figure, stars, doodles, and a ticker.',
    (context) => const ContentPage(),
  ),
  GalleryPage(
    'States',
    'Validation, empty margins, undoable toasts, and a pull-to-refresh.',
    (context) => const StatesPage(),
  ),
  GalleryPage(
    'Focus & Keyboard',
    'One ring on every control — Tab, arrows, Home/End, Enter, Escape.',
    (context) => const FocusPage(),
  ),
];

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.pages,
    required this.selected,
    required this.onSelect,
    required this.rtl,
    required this.onToggleRtl,
  });

  final List<GalleryPage> pages;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool rtl;
  final ValueChanged<bool> onToggleRtl;

  @override
  Widget build(BuildContext context) => Container(
    width: _sidebarWidth,
    decoration: const BoxDecoration(
      color: DrawkitPalette.surface,
      border: BorderDirectional(
        end: BorderSide(color: DrawkitPalette.inkFaint, width: 1),
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
              fontSize: 26,
              fontFamily: 'DrawkitPen',
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
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Row(
            children: [
              const Text(
                'RTL',
                style: TextStyle(
                  color: DrawkitPalette.inkMuted,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 10),
              DrawkitToggle(value: rtl, onChanged: onToggleRtl),
            ],
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
          semanticLabel: 'accept the scribbles',
          onChanged: (v) => setState(() => terms = v),
        ),
        text: 'I accept the scribbles (checked, with the check drawn on)',
        onTap: () => setState(() => terms = !terms),
      ),
      _ChoiceRow(
        control: DrawkitCheckbox(
          value: newsletter,
          semanticLabel: 'send me one doodle a week',
          onChanged: (v) => setState(() => newsletter = v),
        ),
        text: 'Send me one doodle a week',
        onTap: () => setState(() => newsletter = !newsletter),
      ),
      _ChoiceRow(
        control: const DrawkitCheckbox(
          value: false,
          semanticLabel: 'disabled checkbox',
          onChanged: null,
        ),
        text: 'Disabled checkbox — the ink stays, the hand stops',
        onTap: null,
      ),
      const SizedBox(height: 26),
      for (final f in const ['apple', 'banana', 'cherry'])
        _ChoiceRow(
          control: DrawkitRadio<String>(
            value: f,
            groupValue: fruit,
            semanticLabel: 'radio $f',
            onChanged: (v) => setState(() => fruit = v),
          ),
          text: 'Radio: $f',
          onTap: () => setState(() => fruit = f),
        ),
      const SizedBox(height: 26),
      _ChoiceRow(
        control: DrawkitToggle(
          value: darkInk,
          semanticLabel: 'dark ink',
          onChanged: (v) => setState(() => darkInk = v),
        ),
        text: 'Dark ink (toggle — the knob travels 20px)',
        onTap: () => setState(() => darkInk = !darkInk),
      ),
      _ChoiceRow(
        control: const DrawkitToggle(
          value: true,
          semanticLabel: 'disabled toggle',
          onChanged: null,
        ),
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

// ---------------------------------------------------------------------------
// Select page

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> {
  String? fruit = 'banana';

  static const _fruits = [
    DrawkitSelectOption(value: 'apple', label: 'Apple'),
    DrawkitSelectOption(value: 'banana', label: 'Banana'),
    DrawkitSelectOption(value: 'cherry', label: 'Cherry'),
    DrawkitSelectOption(value: 'durian', label: 'Durian (probably a mistake)'),
    DrawkitSelectOption(value: 'elderberry', label: 'Elderberry'),
    DrawkitSelectOption(value: 'fig', label: 'Fig'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 260,
        child: DrawkitSelect<String>(
          options: _fruits,
          value: fruit,
          onChanged: (v) => setState(() => fruit = v),
        ),
      ),
      const SizedBox(height: 22),
      const SizedBox(
        width: 260,
        child: DrawkitSelect<String>(
          options: _fruits,
          value: null,
          onChanged: null,
          semanticLabel: 'disabled select',
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'picked: ${fruit ?? '—'}',
        style: const TextStyle(
          color: DrawkitPalette.inkMuted,
          decoration: TextDecoration.none,
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Decorations page

class DecorationsPage extends StatefulWidget {
  const DecorationsPage({super.key});

  @override
  State<DecorationsPage> createState() => _DecorationsPageState();
}

class _DecorationsPageState extends State<DecorationsPage> {
  DrawkitListMarker marker = DrawkitListMarker.dash;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'divider',
        style: TextStyle(
          color: DrawkitPalette.inkMuted,
          decoration: TextDecoration.none,
        ),
      ),
      const DrawkitDivider(),
      const SizedBox(height: 18),
      SizedBox(
        width: 360,
        child: DrawkitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A card',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The frame is one seeded stroke; put anything inside.',
                style: TextStyle(
                  color: DrawkitPalette.inkMuted,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  DrawkitBadge(child: Text('outline')),
                  SizedBox(width: 10),
                  DrawkitBadge(
                    variant: DrawkitBadgeVariant.scribble,
                    child: Text('scribble'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          DrawkitButton(
            onPressed: () => setState(() {
              marker = marker == DrawkitListMarker.dash
                  ? DrawkitListMarker.check
                  : DrawkitListMarker.dash;
            }),
            child: Text('marker: ${marker.name}'),
          ),
          const SizedBox(width: 18),
        ],
      ),
      const SizedBox(height: 12),
      DrawkitList(
        marker: marker,
        children: const [
          Text('Seeded randomness makes every mount a fresh sketch.'),
          Text(
            'Boil frames come from the variants generator, three per stroke.',
          ),
          Text('The marker gutter is 24px of reserved padding.'),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Text decoration page

class TextPage extends StatelessWidget {
  const TextPage({super.key});

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: DrawkitPalette.ink,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitUnderline(
            text: 'Every wrapped line gets its own underline stroke, so a sentence that crosses lines stays ruled to the last word.',
            textStyle: body,
          ),
          const SizedBox(height: 22),
          const DrawkitHighlight(
            text: 'Important, but not shouting: the marker wash is one 6px scribble at 30% in multiply.',
            textStyle: body,
          ),
          const SizedBox(height: 22),
          const DrawkitCircle(
            text: 'circled on arrival',
            textStyle: TextStyle(
              fontSize: 20,
              height: 1.5,
              color: DrawkitPalette.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Composite page

class CompositePage extends StatefulWidget {
  const CompositePage({super.key});

  @override
  State<CompositePage> createState() => _CompositePageState();
}

class _CompositePageState extends State<CompositePage> {
  bool chip = true;
  int tab = 0;
  int page = 0;
  final targetKey = GlobalKey();
  final fromKey = GlobalKey();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DrawkitChip(
        selected: chip,
        onChanged: (v) => setState(() => chip = v),
        child: const Text('dashed'),
      ),
      const SizedBox(height: 24),
      DrawkitTabs(
        labels: const ['overview', 'details', 'notes'],
        active: tab,
        onChanged: (i) => setState(() => tab = i),
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 160,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PositionedDirectional(
              top: 8,
              start: 8,
              child: DrawkitTooltip(
                target: targetKey,
                child: const Text('the target is down there'),
              ),
            ),
            PositionedDirectional(
              top: 110,
              start: 260,
              child: SizedBox(
                key: targetKey,
                width: 90,
                height: 48,
                child: const DrawkitButton(
                  onPressed: _noop,
                  child: Text('target'),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const DrawkitAlert(
        tag: Text('rant'),
        child: Text('The sketch layer never lies, the browser sometimes does.'),
      ),
      const SizedBox(height: 24),
      const DrawkitSteps(
        children: [
          Text('Pick a seed'),
          Text('Watch the strokes boil'),
          Text('Ship the sketch'),
        ],
      ),
      const SizedBox(height: 24),
      const Row(
        children: [
          DrawkitKbd(child: Text('⌘K')),
          SizedBox(width: 10),
          DrawkitKbd(child: Text('⇧⏎')),
        ],
      ),
      const SizedBox(height: 24),
      const DrawkitQuote(
        text: 'Any sufficiently advanced CSS is indistinguishable from a canvas library.',
        footer: Text('— the internet, paraphrased'),
      ),
      const SizedBox(height: 24),
      DrawkitPager(
        count: 5,
        page: page,
        onPage: (i) => setState(() => page = i),
      ),
      const SizedBox(height: 26),
      SizedBox(
        height: 110,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PositionedDirectional(
              top: 0,
              start: 0,
              child: SizedBox(
                key: fromKey,
                width: 90,
                height: 36,
                child: const DrawkitButton(
                  onPressed: _noop,
                  child: Text('from'),
                ),
              ),
            ),
            PositionedDirectional(
              top: 60,
              start: 240,
              child: SizedBox(
                key: _toKey,
                width: 90,
                height: 48,
                child: const DrawkitButton(onPressed: _noop, child: Text('to')),
              ),
            ),
            Positioned.fill(
              child: DrawkitArrow(from: fromKey, to: _toKey),
            ),
          ],
        ),
      ),
    ],
  );
}

final GlobalKey _toKey = GlobalKey();

// ---------------------------------------------------------------------------
// Motion page

class MotionPage extends StatefulWidget {
  const MotionPage({super.key});

  @override
  State<MotionPage> createState() => _MotionPageState();
}

class _MotionPageState extends State<MotionPage> {
  final DrawkitShakeController _shake = DrawkitShakeController();
  int _run = 0;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: DrawkitPalette.ink,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sketch-in — every stroke below traces itself on mount',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitSketchIn(
            key: ValueKey('sketch$_run'),
            child: DrawkitCard(
              child: const Text(
                'The frame draws first, the words were already written.',
                style: body,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Stagger — one clock, a step apart', style: body),
          const SizedBox(height: 10),
          DrawkitStagger(
            key: ValueKey('stagger$_run'),
            step: const Duration(milliseconds: 120),
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final task in const [
                'sketch the outline',
                'boil for three frames',
                'mirror for RTL',
                'ship it',
              ])
                DrawkitCard(child: Text(task, style: body)),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Shake — the wrong! wiggle', style: body),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DrawkitShake(
                  controller: _shake,
                  child: DrawkitInput(placeholder: 'not an email'),
                ),
              ),
              const SizedBox(width: 10),
              DrawkitButton(
                onPressed: _shake.shake,
                child: const Text('shake it'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          DrawkitButton(
            onPressed: () => setState(() => _run++),
            child: const Text('replay the drawing'),
          ),
        ],
      ),
    );
  }
}

class ActionsPage extends StatefulWidget {
  const ActionsPage({super.key});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  String _view = 'grid';
  double _size = 0.4;
  int _copies = 1;
  String _query = '';
  bool _favourite = false;

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: DrawkitPalette.ink,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Segmented — one frame, a scribbled wash for the pick',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitSegmentedButton<String>(
            segments: const [
              DrawkitSegment(value: 'grid', label: 'Grid'),
              DrawkitSegment(value: 'list', label: 'List'),
              DrawkitSegment(value: 'kanban', label: 'Kanban'),
            ],
            selected: _view,
            onChanged: (value) => setState(() => _view = value),
          ),
          const SizedBox(height: 22),
          Text(
            'Slider — stroke width ${_size.toStringAsFixed(2)}',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitSlider(
            value: _size,
            divisions: 20,
            onChanged: (value) => setState(() => _size = value),
          ),
          const SizedBox(height: 22),
          Text(
            'Stepper — $_copies ${_copies == 1 ? 'copy' : 'copies'}',
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DrawkitStepper(
                value: _copies,
                min: 1,
                max: 9,
                onChanged: (value) => setState(() => _copies = value),
              ),
              const Spacer(),
              DrawkitIconButton(
                semanticLabel: 'Favourite',
                tone: _favourite ? DrawkitTone.accent : DrawkitTone.neutral,
                variant: _favourite
                    ? DrawkitButtonVariant.solid
                    : DrawkitButtonVariant.outline,
                onPressed: () => setState(() => _favourite = !_favourite),
                child: Text(_favourite ? '★' : '☆'),
              ),
              const SizedBox(width: 8),
              DrawkitIconButton(
                semanticLabel: 'Delete',
                tone: DrawkitTone.danger,
                onPressed: () => setState(() => _copies = 1),
                child: const Text('×'),
              ),
              const SizedBox(width: 16),
              DrawkitFab(
                semanticLabel: 'Add sketch',
                size: 44,
                tone: DrawkitTone.accent,
                onPressed: () =>
                    setState(() => _copies = (_copies + 1).clamp(1, 9)),
                child: const Text('+'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Search — the magnifier holds the leading gutter',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitSearchField(
            placeholder: 'search the sketchbook…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          Text(
            _query.isEmpty
                ? 'nothing typed yet'
                : 'you are looking for: $_query',
            style: body.copyWith(color: DrawkitPalette.inkMuted),
          ),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String _last = 'nothing yet';
  double _progress = 0.35;

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: DrawkitPalette.ink,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Modals — the panel traces itself in', style: body),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DrawkitButton(
                onPressed: () async {
                  final answer = await showDrawkitDialog<bool>(
                    context: context,
                    child: DrawkitDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tear this page out?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: DrawkitPalette.ink,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'The ink is still wet — nothing is saved yet.',
                            style: body,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DrawkitButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('keep'),
                              ),
                              const SizedBox(width: 10),
                              DrawkitButton(
                                variant: DrawkitButtonVariant.solid,
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('tear it'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  if (!mounted) return;
                  setState(() => _last = 'dialog answered: $answer');
                },
                child: const Text('open dialog'),
              ),
              DrawkitButton(
                onPressed: () => showDrawkitSheet(
                  context: context,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sketchbook options',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: DrawkitPalette.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Drag the handle down or tap the scrim to fold it away.',
                        style: body,
                      ),
                      const SizedBox(height: 14),
                      DrawkitButton(
                        variant: DrawkitButtonVariant.solid,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('done'),
                      ),
                    ],
                  ),
                ),
                child: const Text('bottom sheet'),
              ),
              DrawkitButton(
                onPressed: () => showDrawkitSheet(
                  context: context,
                  edge: DrawkitSheetEdge.end,
                  child: const Text('a quiet side drawer', style: body),
                ),
                child: const Text('side sheet'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Toasts — bottom pills that excuse themselves',
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DrawkitButton(
                onPressed: () => showDrawkitToast(
                  context,
                  message: 'saved to the sketchbook',
                ),
                child: const Text('toast ok'),
              ),
              const SizedBox(width: 10),
              DrawkitButton(
                tone: DrawkitTone.danger,
                onPressed: () => showDrawkitToast(
                  context,
                  message: 'the ink ran out',
                  tone: DrawkitTone.danger,
                ),
                child: const Text('toast fail'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Progress — ${(_progress * 100).round()}%', style: body),
          const SizedBox(height: 10),
          DrawkitProgressBar(
            value: _progress,
            semanticLabel: 'gallery progress',
          ),
          const SizedBox(height: 12),
          DrawkitSlider(
            value: _progress,
            divisions: 20,
            onChanged: (value) => setState(() => _progress = value),
          ),
          const SizedBox(height: 12),
          const DrawkitProgressBar(semanticLabel: 'waiting'),
          const SizedBox(height: 22),
          Row(
            children: [
              const DrawkitSpinner(),
              const SizedBox(width: 14),
              const Expanded(child: DrawkitSkeleton(lines: 2, spacing: 8)),
              const SizedBox(width: 14),
              const DrawkitSkeleton.circle(),
            ],
          ),
          const SizedBox(height: 22),
          Text(_last, style: body.copyWith(color: DrawkitPalette.inkMuted)),
        ],
      ),
    );
  }
}

class MenusPage extends StatefulWidget {
  const MenusPage({super.key});

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  bool _ruled = true;
  bool _graph = false;
  DateTime? _date = DateTime(2026, 10, 16);
  String _last = 'nothing yet';

  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitPalette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Menus — panels that fold away', style: body),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DrawkitMenu(
                semanticLabel: 'view options',
                items: [
                  DrawkitMenuItem(
                    label: 'Ruled paper',
                    checked: _ruled,
                    onSelected: () => setState(() => _ruled = true),
                  ),
                  DrawkitMenuItem(
                    label: 'Graph paper',
                    checked: _graph,
                    onSelected: () => setState(() => _graph = true),
                  ),
                  const DrawkitMenuItem.divider(),
                  const DrawkitMenuItem(label: 'Tracing paper', hint: '⌘T'),
                  DrawkitMenuItem(
                    label: 'Save sheet',
                    hint: '⌘S',
                    onSelected: () =>
                        showDrawkitToast(context, message: 'sheet saved'),
                  ),
                ],
                child: const Text('view'),
              ),
              DrawkitPopover(
                semanticLabel: 'pen options',
                trigger: const Text(
                  'pen options',
                  style: TextStyle(
                    fontSize: 14,
                    color: DrawkitPalette.ink,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nib', style: body),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final nib in const [
                          'fine',
                          'medium',
                          'broad',
                        ]) ...[
                          DrawkitButton(
                            onPressed: () => showDrawkitToast(
                              context,
                              message: '$nib nib loaded',
                            ),
                            child: Text(nib),
                          ),
                          if (nib != 'broad') const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Any widget can open a popover.',
                      style: TextStyle(
                        fontSize: 12,
                        color: DrawkitPalette.inkMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              DrawkitButton(
                onPressed: () async {
                  final result = await showDrawkitCommandPalette<String>(
                    context: context,
                    commands: const [
                      DrawkitCommand(
                        label: 'Open sheet',
                        value: 'open',
                        hint: '⌘O',
                      ),
                      DrawkitCommand(
                        label: 'Save sheet',
                        value: 'save',
                        hint: '⌘S',
                      ),
                      DrawkitCommand(
                        label: 'Export as PNG',
                        value: 'export',
                        keywords: ['image', 'picture'],
                      ),
                      DrawkitCommand(
                        label: 'Clear page',
                        value: 'clear',
                        keywords: ['erase', 'wipe'],
                      ),
                    ],
                  );
                  if (!mounted || result == null) return;
                  setState(() => _last = 'command: $result');
                },
                child: const Text('command palette'),
              ),
              DrawkitButton(
                onPressed: () async {
                  final picked = await showDrawkitDatePicker(
                    context: context,
                    initialDate: _date,
                  );
                  if (!mounted || picked == null) return;
                  setState(() => _date = picked);
                },
                child: const Text('pick a date'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Accordion — headers unfold on a sketch line',
            style: body,
          ),
          const SizedBox(height: 10),
          const DrawkitAccordion(
            initiallyExpanded: {1},
            sections: [
              DrawkitAccordionSection(
                title: 'Pencils',
                child: Text(
                  'HB, 2B, and one grudging 4H kept for margins.',
                  style: body,
                ),
              ),
              DrawkitAccordionSection(
                title: 'Paper',
                child: Text(
                  'Ruled, graph, and the good cotton stock.',
                  style: body,
                ),
              ),
              DrawkitAccordionSection(
                title: 'Ink',
                child: Text(
                  'Waterproof black, and a red for corrections.',
                  style: body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _date == null
                ? 'Date picker — nothing picked'
                : 'Date picker — ${_date!.year}-${_date!.month}-${_date!.day}',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitDatePicker(
            value: _date,
            onChanged: (date) => setState(() => _date = date),
            semanticLabel: 'sheet date',
          ),
          const SizedBox(height: 22),
          Text(_last, style: body.copyWith(color: DrawkitPalette.inkMuted)),
        ],
      ),
    );
  }
}

class StructurePage extends StatefulWidget {
  const StructurePage({super.key});

  @override
  State<StructurePage> createState() => _StructurePageState();
}

class _StructurePageState extends State<StructurePage> {
  int _rail = 0;
  int _bottom = 0;

  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitPalette.ink,
    decoration: TextDecoration.none,
  );

  static const destinations = [
    DrawkitNavDestination(label: 'Inbox', icon: Text('✉')),
    DrawkitNavDestination(label: 'Drafts', icon: Text('✎')),
    DrawkitNavDestination(label: 'Archive', icon: Text('▤')),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitAppBar(
            leading: Text(
              '←',
              style: TextStyle(fontSize: 18, decoration: TextDecoration.none),
            ),
            title: Text('Sketchbook'),
            actions: [
              Text(
                'save',
                style: TextStyle(
                  fontSize: 14,
                  color: DrawkitPalette.inkMuted,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '⋯',
                style: TextStyle(fontSize: 18, decoration: TextDecoration.none),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Navigation — both bars mirror in RTL', style: body),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrawkitNavRail(
                destinations: destinations,
                selected: _rail,
                onChanged: (i) => setState(() => _rail = i),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    'rail picked: ${destinations[_rail].label.toLowerCase()}',
                    style: body.copyWith(color: DrawkitPalette.inkMuted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          DrawkitBottomNav(
            destinations: destinations,
            selected: _bottom,
            onChanged: (i) => setState(() => _bottom = i),
          ),
          const SizedBox(height: 22),
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(
                label: 'Sketchbook',
                onTap: () =>
                    showDrawkitToast(context, message: 'back to the book'),
              ),
              DrawkitBreadcrumbItem(
                label: 'Pencils',
                onTap: () =>
                    showDrawkitToast(context, message: 'pencil drawer'),
              ),
              const DrawkitBreadcrumbItem(label: 'HB'),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'A ruled ledger — header line, faint row rules',
            style: body,
          ),
          const SizedBox(height: 6),
          DrawkitTable(
            columns: const [
              DrawkitTableColumn(label: 'Pencil', flex: 2),
              DrawkitTableColumn(label: 'Qty'),
              DrawkitTableColumn(label: 'Total'),
            ],
            rows: const [
              [
                Text('HB', style: body),
                Text('12', style: body),
                Text('\$1.20', style: body),
              ],
              [
                Text('2B', style: body),
                Text('3', style: body),
                Text('\$0.60', style: body),
              ],
              [
                Text('4H', style: body),
                Text('1', style: body),
                Text('\$0.30', style: body),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  int _stars = 3;

  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitPalette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitHeading(text: 'The Content Kit', underline: true),
          const SizedBox(height: 8),
          const DrawkitHeading(
            text: 'display type, faces, plates, ink, and idle hands',
            level: 3,
            textStyle: TextStyle(color: DrawkitPalette.inkMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'A crowd — discs overlap, the overflow confesses',
            style: body,
          ),
          const SizedBox(height: 10),
          const DrawkitAvatarGroup(
            max: 3,
            overlap: 14,
            size: 44,
            children: [
              Text('HB'),
              Text('2B'),
              Text('4H'),
              Text('6B'),
              Text('9B'),
            ],
          ),
          const SizedBox(height: 22),
          DrawkitFigure(
            caption: 'fig 1 — the idle pen, mid-spiral',
            child: const Center(
              child: DrawkitDoodle(kind: DrawkitDoodleKind.spiral, size: 72),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Rating — tap a star, tap again to clear one ($_stars/5)',
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitRating(
            value: _stars,
            onChanged: (v) => setState(() => _stars = v),
            starSize: 30,
          ),
          const SizedBox(height: 22),
          const Text(
            'Doodles — decorative, silent, never interactive',
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final kind in DrawkitDoodleKind.values)
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: DrawkitDoodle(kind: kind, size: 36),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('A ticker — hover to pause it', style: body),
          const SizedBox(height: 8),
          const DrawkitMarquee(
            child: Text(
              'all work and no play makes the pen a dull tool',
              style: body,
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class StatesPage extends StatefulWidget {
  const StatesPage({super.key});

  @override
  State<StatesPage> createState() => _StatesPageState();
}

class _StatesPageState extends State<StatesPage> {
  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitPalette.ink,
    decoration: TextDecoration.none,
  );

  final TextEditingController _email = TextEditingController();
  String? _emailError;
  List<String> _notes = ['Sharpen the HB', 'Dust the eraser', 'Rinse the nib'];
  final List<int> _fetched = [3, 2, 1];

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _validate() {
    final text = _email.text.trim();
    setState(() {
      _emailError = text.contains('@')
          ? null
          : text.isEmpty
          ? 'An address, please — the pen refuses to guess.'
          : 'That is missing its @ — even the ink knows.';
    });
  }

  void _deleteNote(int index) {
    final removed = _notes[index];
    setState(() => _notes = [..._notes]..removeAt(index));
    showDrawkitToast(
      context,
      message: '“$removed” torn out',
      tone: DrawkitTone.neutral,
      action: DrawkitToastAction(
        label: 'Undo',
        onPressed: () =>
            setState(() => _notes = [..._notes]..insert(index, removed)),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _fetched.insert(0, _fetched.first + 1));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitHeading(text: 'The States Kit', underline: true),
          const SizedBox(height: 8),
          const DrawkitHeading(
            text: 'errors, empty margins, undo, and the pull',
            level: 3,
            textStyle: TextStyle(color: DrawkitPalette.inkMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            'Validation — the outline inks red, the message speaks',
            style: body,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 320,
            child: DrawkitInput(
              controller: _email,
              placeholder: 'you@sketchbook.paper',
              helper: 'We never share it.',
              error: _emailError,
              onSubmitted: (_) => _validate(),
            ),
          ),
          const SizedBox(height: 10),
          DrawkitButton(onPressed: _validate, child: const Text('Validate')),
          const SizedBox(height: 26),
          const Text('Notes — deleting offers an Undo', style: body),
          const SizedBox(height: 10),
          if (_notes.isEmpty)
            SizedBox(
              height: 220,
              child: DrawkitEmpty(
                doodle: DrawkitDoodleKind.burst,
                title: 'The margin is blank',
                message: 'Every note was torn out, but the pen remembers.',
                action: DrawkitButton(
                  onPressed: () => setState(
                    () => _notes = ['Sharpen the HB', 'Dust the eraser'],
                  ),
                  child: const Text('Write two back'),
                ),
              ),
            )
          else
            for (var i = 0; i < _notes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DrawkitCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(_notes[i], style: body)),
                      DrawkitIconButton(
                        semanticLabel: 'delete ${_notes[i]}',
                        onPressed: () => _deleteNote(i),
                        child: const Text('✕'),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 20),
          const Text(
            'Pull-to-refresh — drag the list down past the flip',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitCard(
            child: SizedBox(
              height: 200,
              child: DrawkitRefresh(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    for (final n in _fetched)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('fetched page $n', style: body),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Focus page

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitPalette.ink,
    decoration: TextDecoration.none,
  );

  static const hint = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: DrawkitPalette.inkMuted,
    decoration: TextDecoration.none,
  );

  double _inkLevel = 0.45;
  String _segment = 'pen';
  int _tab = 0;
  String? _pick = 'ink';
  DateTime _date = DateTime(2026, 6, 15);
  int _nav = 0;
  String _last = 'nothing yet — pressing a key would be a start';

  void _say(String note) => setState(() => _last = note);

  Future<void> _openDialog() async {
    await showDrawkitDialog<void>(
      context: context,
      child: DrawkitDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A page within the page',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: DrawkitPalette.ink,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escape folds it away; Tab never wanders outside; focus '
              'returns to the button that opened it.',
              style: body,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DrawkitButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _say('dialog closed — the trigger holds focus again');
                  },
                  child: const Text('close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitHeading(text: 'The Focus Kit', underline: true),
          const SizedBox(height: 8),
          const DrawkitHeading(
            text: 'one ring, drawn only while the keyboard is at work',
            level: 3,
            textStyle: TextStyle(color: DrawkitPalette.inkMuted),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tab to walk the page · arrows to move · Home/End to jump · '
            'Enter/Space to choose · Escape to close',
            style: hint,
          ),
          const SizedBox(height: 20),
          const Text(
            'Slider — Home, End, PageUp and PageDown; RTL mirrors the arrows',
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitSlider(
            value: _inkLevel,
            onChanged: (v) => setState(() {
              _inkLevel = v;
              _last = 'ink level ${(v * 100).round()}%';
            }),
          ),
          const SizedBox(height: 22),
          const Text(
            'Segments and tabs — the selection owns the single tab stop',
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitSegmentedButton<String>(
            segments: const [
              DrawkitSegment(value: 'pen', label: 'pen'),
              DrawkitSegment(value: 'pencil', label: 'pencil'),
              DrawkitSegment(value: 'brush', label: 'brush'),
            ],
            selected: _segment,
            onChanged: (v) => setState(() {
              _segment = v;
              _last = 'drawing with the $v';
            }),
          ),
          const SizedBox(height: 12),
          DrawkitTabs(
            labels: const ['Sketch', 'Ink', 'Export'],
            active: _tab,
            onChanged: (i) => setState(() {
              _tab = i;
              _last = 'tab: ${const ['Sketch', 'Ink', 'Export'][i]}';
            }),
          ),
          const SizedBox(height: 10),
          Text(
            const [
              'a rough start, all construction lines',
              'the damp layer, still catching light',
              'a clean file, corners folded shut',
            ][_tab],
            style: hint,
          ),
          const SizedBox(height: 22),
          const Text(
            'Accordion — Up/Down walk the headers, Enter folds a section',
            style: body,
          ),
          const SizedBox(height: 8),
          const DrawkitAccordion(
            sections: [
              DrawkitAccordionSection(
                title: 'What takes focus',
                child: Text(
                  'Anything with a story to tell the keyboard — buttons, '
                  'fields, rows, days, crumbs.',
                  style: hint,
                ),
              ),
              DrawkitAccordionSection(
                title: 'Where the ring comes from',
                child: Text(
                  'one helper inks the dashed holder around every control.',
                  style: hint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Select and menu — arrows walk, Escape hands focus back',
            style: body,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DrawkitSelect<String>(
                  options: const [
                    DrawkitSelectOption(value: 'ink', label: 'Ink'),
                    DrawkitSelectOption(value: 'wash', label: 'Wash'),
                    DrawkitSelectOption(value: 'gouache', label: 'Gouache'),
                  ],
                  value: _pick,
                  onChanged: (v) => setState(() {
                    _pick = v;
                    _last = 'medium: $v';
                  }),
                ),
              ),
              DrawkitMenu(
                semanticLabel: 'focus menu',
                items: [
                  DrawkitMenuItem(
                    label: 'Sharpen the HB',
                    onSelected: () => _say('the HB is sharp again'),
                  ),
                  DrawkitMenuItem(
                    label: 'Refill the well',
                    onSelected: () => _say('the well is full'),
                  ),
                  const DrawkitMenuItem.divider(),
                  const DrawkitMenuItem(label: 'Fold the page', enabled: false),
                ],
                child: const Text('maintenance', style: body),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Date picker — arrows walk days, PageUp/Down change months',
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitDatePicker(
            value: _date,
            today: DateTime(2026, 6, 15),
            onChanged: (d) => setState(() {
              _date = d;
              _last = 'dated ${d.year}-${d.month}-${d.day}';
            }),
          ),
          const SizedBox(height: 22),
          const Text(
            'Breadcrumb and nav rail — plain Tab stops, Enter to choose',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(
                label: 'kit',
                onTap: () => _say('back to the kit'),
              ),
              DrawkitBreadcrumbItem(
                label: 'focus',
                onTap: () => _say('still on the focus page'),
              ),
              const DrawkitBreadcrumbItem(label: 'here'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            width: 150,
            child: DrawkitNavRail(
              destinations: const [
                DrawkitNavDestination(label: 'Sketches'),
                DrawkitNavDestination(label: 'Swatches'),
                DrawkitNavDestination(label: 'Filed'),
              ],
              selected: _nav,
              onChanged: (i) => setState(() {
                _nav = i;
                _last = 'rail: ${const ['Sketches', 'Swatches', 'Filed'][i]}';
              }),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Dialog — Escape dismisses, Tab stays inside, focus comes home',
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitButton(
            onPressed: () => _openDialog(),
            child: const Text('Open a dialog'),
          ),
          const SizedBox(height: 16),
          Text('last action: $_last', style: hint),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

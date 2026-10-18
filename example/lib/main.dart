import 'dart:ui' show PointerDeviceKind;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const DrawkitGalleryApp());

final _sidebarWidth = 210.0;

class DrawkitGalleryApp extends StatelessWidget {
  const DrawkitGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return WidgetsApp(
      title: 'drawkit gallery',
      color: palette.paper,
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
}

class Gallery extends StatefulWidget {
  const Gallery({super.key});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  int _page = 0;
  bool _rtl = false;
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    final palette = _dark ? DrawkitPalette.dark : DrawkitPalette.light;
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: DrawkitTheme(
        data: palette.style,
        child: DefaultTextStyle(
          style: TextStyle(
            color: palette.ink,
            fontSize: 14,
            height: 1.4,
            decoration: TextDecoration.none,
          ),
          child: ColoredBox(
            color: palette.paper,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(
                  pages: galleryPages,
                  selected: _page,
                  onSelect: (i) => setState(() => _page = i),
                  rtl: _rtl,
                  onToggleRtl: (v) => setState(() => _rtl = v),
                  dark: _dark,
                  onToggleDark: (v) => setState(() => _dark = v),
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
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            galleryPages[_page].subtitle,
                            style: TextStyle(
                              color: palette.inkMuted,
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
      ),
    );
  }
}

class GalleryPage {
  const GalleryPage(this.group, this.title, this.subtitle, this.builder);

  final String group;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

/// Filled in per milestone; see the individual page builders below.
final List<GalleryPage> galleryPages = [
  GalleryPage(
    'Foundations',
    'Surface',
    'The shared sketch surface: seeded chrome behind any child, one boil clock.',
    (context) => const SurfacePage(),
  ),
  GalleryPage(
    'Foundations',
    'Ink · Palette',
    'Two papers side by side: the full palette, control by control.',
    (context) => const PalettePage(),
  ),
  GalleryPage(
    'Foundations',
    'Motion',
    'Draw-on tracing, staggered lists, and the error shake — one shared pen.',
    (context) => const MotionPage(),
  ),
  GalleryPage(
    'Foundations',
    'Focus & Keyboard',
    'One ring on every control — Tab, arrows, Home/End, Enter, Escape.',
    (context) => const FocusPage(),
  ),
  GalleryPage(
    'Actions',
    'Buttons',
    'Variants, states, tones — plus icon buttons, the floating pen, and the fab menu.',
    (context) => const ButtonPage(),
  ),
  GalleryPage(
    'Forms',
    'Fields',
    'Input, textarea, and search: real text editing behind a sketch outline.',
    (context) => const FieldPage(),
  ),
  GalleryPage(
    'Forms',
    'Choices',
    'Checkboxes, radios, toggles — and chips and segments for the wider picks.',
    (context) => const ChoicePage(),
  ),
  GalleryPage(
    'Forms',
    'Select & Dates',
    'A dropdown and a calendar: pick one value out of many.',
    (context) => const SelectPage(),
  ),
  GalleryPage(
    'Forms',
    'Values',
    'Slider, stepper, and stars: numbers and ratings with a drawn response.',
    (context) => const ValuesPage(),
  ),
  GalleryPage(
    'Navigation',
    'Navigation',
    'App bar, rail, bottom bar, breadcrumb, pager — and the floating capsule.',
    (context) => const NavigationPage(),
  ),
  GalleryPage(
    'Navigation',
    'Tabs & Steps',
    'Tabs that slide the underline, steps that count the walk.',
    (context) => const TabsPage(),
  ),
  GalleryPage(
    'Overlays',
    'Menus & Popovers',
    'Dropdowns, popovers, the tooltip, and the command palette.',
    (context) => const MenusPage(),
  ),
  GalleryPage(
    'Overlays',
    'Dialogs & Sheets',
    'Modals and drawers that trace themselves in over the page.',
    (context) => const DialogsPage(),
  ),
  GalleryPage(
    'Feedback',
    'Feedback & States',
    'Toasts, alerts, validation, empty margins, loading, and the pull.',
    (context) => const FeedbackPage(),
  ),
  GalleryPage(
    'Display',
    'Cards & Tables',
    'Frames, rules, badges, lists, the accordion, and a ruled ledger.',
    (context) => const ContainersPage(),
  ),
  GalleryPage(
    'Display',
    'Type & Ink',
    'Headings, underline, highlight, circle, quote, and kbd.',
    (context) => const TypePage(),
  ),
  GalleryPage(
    'Display',
    'Pictures & Extras',
    'Faces, plates, doodles, arrows, and a ticker.',
    (context) => const PicturesPage(),
  ),
];

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.pages,
    required this.selected,
    required this.onSelect,
    required this.rtl,
    required this.onToggleRtl,
    required this.dark,
    required this.onToggleDark,
  });

  final List<GalleryPage> pages;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool rtl;
  final ValueChanged<bool> onToggleRtl;
  final bool dark;
  final ValueChanged<bool> onToggleDark;

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: palette.surface,
        border: BorderDirectional(
          end: BorderSide(color: palette.inkFaint, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: Text(
              'drawkit',
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'DrawkitPen',
                color: palette.pen,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pages.length,
              itemBuilder: (context, i) {
                final page = pages[i];
                final showGroup = i == 0 || pages[i - 1].group != page.group;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showGroup)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Text(
                          page.group.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: palette.inkMuted,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        color: i == selected ? palette.paper : null,
                        child: Text(
                          page.title,
                          style: TextStyle(
                            color: i == selected
                                ? palette.pen
                                : palette.inkMuted,
                            fontWeight: i == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'RTL',
                      style: TextStyle(
                        color: palette.inkMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DrawkitToggle(
                      value: rtl,
                      semanticLabel: 'RTL',
                      onChanged: onToggleRtl,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'dark',
                      style: TextStyle(
                        color: palette.inkMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DrawkitToggle(
                      value: dark,
                      semanticLabel: 'dark ink',
                      onChanged: onToggleDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return Column(
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
                  ..color = palette.pen
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
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: palette.inkMuted,
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
  bool _favourite = false;
  int _pages = 0;

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Variants — one frame, three finishes', style: body),
          const SizedBox(height: 10),
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
          const SizedBox(height: 22),
          Text('Tones — and the disabled hand', style: body),
          const SizedBox(height: 10),
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
          const SizedBox(height: 22),
          Text(
            'States — loading slows the boil, error and success re-ink',
            style: body,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in DrawkitButtonState.values)
                DrawkitButton(
                  state: s,
                  onPressed: () {},
                  child: Text('state: ${s.name}'),
                ),
            ],
          ),
          const SizedBox(height: 22),
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
              Text(
                'Tab to me for the focus ring →',
                style: body.copyWith(color: palette.inkMuted),
              ),
              const DrawkitButton(
                autofocus: false,
                onPressed: _noop,
                child: Text('focus me'),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Icon buttons — one glyph, a required label', style: body),
          const SizedBox(height: 10),
          Row(
            children: [
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
                semanticLabel: 'Clear the pages',
                tone: DrawkitTone.danger,
                onPressed: () => setState(() => _pages = 0),
                child: const Text('×'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Floating pen — the one action that never scrolls away',
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DrawkitFab(
                semanticLabel: 'add a page',
                onPressed: () => setState(() => _pages += 1),
                child: const Text('＋'),
              ),
              const SizedBox(width: 16),
              Text(
                _pages == 0
                    ? 'no new pages yet'
                    : '$_pages new ${_pages == 1 ? 'page' : 'pages'}',
                style: body.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Fab menu — labelled pills unfold above the circle',
            style: body,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: DrawkitFabMenu(
                semanticLabel: 'quick actions',
                items: [
                  DrawkitFabMenuItem(
                    label: 'New note',
                    icon: Text('✎'),
                    onPressed: () =>
                        showDrawkitToast(context, message: 'a fresh note'),
                  ),
                  DrawkitFabMenuItem(
                    label: 'New sketch',
                    icon: Text('✏'),
                    onPressed: () =>
                        showDrawkitToast(context, message: 'a blank page'),
                  ),
                  DrawkitFabMenuItem(
                    label: 'Import',
                    icon: Text('⌤'),
                    onPressed: () =>
                        showDrawkitToast(context, message: 'importing…'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  bool chip = true;
  String view = 'grid';

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return Column(
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
        const SizedBox(height: 26),
        Text(
          'Chip — a tag that picks itself',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        DrawkitChip(
          selected: chip,
          onChanged: (v) => setState(() => chip = v),
          child: Text('dashed'),
        ),
        const SizedBox(height: 26),
        Text(
          'Segments — one frame, a scribbled wash for the pick',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        DrawkitSegmentedButton<String>(
          segments: const [
            DrawkitSegment(value: 'grid', label: 'Grid'),
            DrawkitSegment(value: 'list', label: 'List'),
            DrawkitSegment(value: 'kanban', label: 'Kanban'),
          ],
          selected: view,
          onChanged: (value) => setState(() => view = value),
        ),
        const SizedBox(height: 26),
        Text(
          'Tab moves focus, Space/Enter flips — the focus ring answers.',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
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
  String _query = '';

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name',
          style: TextStyle(
            color: palette.inkMuted,
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
        Text(
          'Notes',
          style: TextStyle(
            color: palette.inkMuted,
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
        const SizedBox(height: 22),
        Text(
          'Search — the magnifier holds the leading gutter',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: DrawkitSearchField(
            placeholder: 'search the sketchbook…',
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _query.isEmpty ? 'nothing typed yet' : 'you are looking for: $_query',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'name: ${name.text.isEmpty ? '…' : name.text}\nnotes: ${notes.text.isEmpty ? '…' : notes.text.replaceAll('\n', ' ⏎ ')}',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
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
  DateTime? _date = DateTime(2026, 10, 16);

  static const _fruits = [
    DrawkitSelectOption(value: 'apple', label: 'Apple'),
    DrawkitSelectOption(value: 'banana', label: 'Banana'),
    DrawkitSelectOption(value: 'cherry', label: 'Cherry'),
    DrawkitSelectOption(value: 'durian', label: 'Durian (probably a mistake)'),
    DrawkitSelectOption(value: 'elderberry', label: 'Elderberry'),
    DrawkitSelectOption(value: 'fig', label: 'Fig'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return Column(
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
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _date == null
              ? 'Date picker — nothing picked'
              : 'Date picker — ${_date!.year}-${_date!.month}-${_date!.day}',
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        DrawkitDatePicker(
          value: _date,
          onChanged: (date) => setState(() => _date = date),
          semanticLabel: 'sheet date',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Containers page

class ContainersPage extends StatefulWidget {
  const ContainersPage({super.key});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage> {
  DrawkitListMarker marker = DrawkitListMarker.dash;

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  TextStyle get caption => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.inkMuted,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Card — one seeded frame around anything', style: caption),
          const SizedBox(height: 10),
          DrawkitCard(
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
                Text(
                  'The frame is one seeded stroke; put anything inside.',
                  style: caption,
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
          const SizedBox(height: 22),
          Text('Divider — a hand rule that stays hand-drawn', style: caption),
          const SizedBox(height: 10),
          const DrawkitDivider(),
          const SizedBox(height: 22),
          Text('List — the marker gutter redraws per pick', style: caption),
          const SizedBox(height: 10),
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
          SizedBox(height: 12),
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
          const SizedBox(height: 22),
          Text('Accordion — headers unfold on a sketch line', style: caption),
          const SizedBox(height: 10),
          DrawkitAccordion(
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
            'Table — a ruled ledger, header line, faint row rules',
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitTable(
            columns: [
              DrawkitTableColumn(label: 'Pencil', flex: 2),
              DrawkitTableColumn(label: 'Qty'),
              DrawkitTableColumn(label: 'Total'),
            ],
            rows: [
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

// ---------------------------------------------------------------------------
// Text decoration page

class TypePage extends StatelessWidget {
  const TypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    final body = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: palette.ink,
      decoration: TextDecoration.none,
    );
    final caption = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: palette.inkMuted,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitHeading(text: 'The Type Kit', underline: true),
          const SizedBox(height: 8),
          DrawkitHeading(
            text: 'display type with the pen in the margins',
            level: 3,
            textStyle: TextStyle(color: palette.inkMuted),
          ),
          const SizedBox(height: 22),
          Text(
            'Underline — every wrapped line gets its own stroke',
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitUnderline(
            text: 'Every wrapped line gets its own underline stroke, so a sentence that crosses lines stays ruled to the last word.',
            textStyle: body,
          ),
          const SizedBox(height: 22),
          Text('Highlight — a marker wash at 30% multiply', style: caption),
          const SizedBox(height: 10),
          DrawkitHighlight(
            text: 'Important, but not shouting: the marker wash is one 6px scribble at 30% in multiply.',
            textStyle: body,
          ),
          const SizedBox(height: 22),
          Text('Circle — the word, circled on arrival', style: caption),
          const SizedBox(height: 10),
          DrawkitCircle(
            text: 'circled on arrival',
            textStyle: TextStyle(
              fontSize: 20,
              height: 1.5,
              color: palette.ink,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 26),
          Text('Quote — the margin remembers who said it', style: caption),
          const SizedBox(height: 10),
          DrawkitQuote(
            text: 'Any sufficiently advanced CSS is indistinguishable from a canvas library.',
            footer: Text('— the internet, paraphrased'),
          ),
          const SizedBox(height: 26),
          Text('Kbd — keys drawn like keys', style: caption),
          const SizedBox(height: 10),
          Row(
            children: [
              DrawkitKbd(child: Text('⌘K')),
              SizedBox(width: 10),
              DrawkitKbd(child: Text('⇧⏎')),
            ],
          ),
        ],
      ),
    );
  }
}

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
    final palette = DrawkitTheme.of(context).palette;
    final body = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: palette.ink,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sketch-in — every stroke below traces itself on mount',
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitSketchIn(
            key: ValueKey('sketch$_run'),
            child: DrawkitCard(
              child: Text(
                'The frame draws first, the words were already written.',
                style: body,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Stagger — one clock, a step apart', style: body),
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
          Text('Shake — the wrong! wiggle', style: body),
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

class ValuesPage extends StatefulWidget {
  const ValuesPage({super.key});

  @override
  State<ValuesPage> createState() => _ValuesPageState();
}

class _ValuesPageState extends State<ValuesPage> {
  double _size = 0.4;
  int _copies = 1;
  int _stars = 3;

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    final body = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: palette.ink,
      decoration: TextDecoration.none,
    );
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          DrawkitStepper(
            value: _copies,
            min: 1,
            max: 9,
            semanticLabel: 'copies',
            onChanged: (value) => setState(() => _copies = value),
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
  double _progress = 0.35;
  final TextEditingController _email = TextEditingController();
  String? _emailError;
  List<String> _notes = ['Sharpen the HB', 'Dust the eraser', 'Rinse the nib'];
  final List<int> _fetched = [3, 2, 1];

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

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
    await Future<void>.delayed(Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _fetched.insert(0, _fetched.first + 1));
  }

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Row(
            children: [
              DrawkitSpinner(),
              SizedBox(width: 14),
              Expanded(child: DrawkitSkeleton(lines: 2, spacing: 8)),
              SizedBox(width: 14),
              DrawkitSkeleton.circle(),
            ],
          ),
          const SizedBox(height: 22),
          Text('Alert — a margin note in ink', style: body),
          const SizedBox(height: 10),
          DrawkitAlert(
            tag: Text('rant'),
            child: Text(
              'The sketch layer never lies, the browser sometimes does.',
            ),
          ),
          const SizedBox(height: 26),
          Text(
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
          Text('Notes — deleting offers an Undo', style: body),
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
          Text(
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
          Text(
            'Progress and skeletons keep the page honest while it waits',
            style: body.copyWith(color: palette.inkMuted),
          ),
        ],
      ),
    );
  }
}

class DialogsPage extends StatefulWidget {
  const DialogsPage({super.key});

  @override
  State<DialogsPage> createState() => _DialogsPageState();
}

class _DialogsPageState extends State<DialogsPage> {
  String _last = 'nothing yet';

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modals — the panel traces itself in', style: body),
          SizedBox(height: 10),
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
                          Text(
                            'Tear this page out?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
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
                child: Text('open dialog'),
              ),
              DrawkitButton(
                onPressed: () => showDrawkitSheet(
                  context: context,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sketchbook options',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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
                child: Text('bottom sheet'),
              ),
              DrawkitButton(
                onPressed: () => showDrawkitSheet(
                  context: context,
                  edge: DrawkitSheetEdge.end,
                  child: Text('a quiet side drawer', style: body),
                ),
                child: Text('side sheet'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Toasts — bottom pills that excuse themselves', style: body),
          SizedBox(height: 10),
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
          Text(_last, style: body.copyWith(color: palette.inkMuted)),
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
  final _tipTarget = GlobalKey();
  String _last = 'nothing yet';

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menus — panels that fold away', style: body),
          SizedBox(height: 10),
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
                  DrawkitMenuItem.divider(),
                  DrawkitMenuItem(label: 'Tracing paper', hint: '⌘T'),
                  DrawkitMenuItem(
                    label: 'Save sheet',
                    hint: '⌘S',
                    onSelected: () =>
                        showDrawkitToast(context, message: 'sheet saved'),
                  ),
                ],
                child: Text('view'),
              ),
              DrawkitPopover(
                semanticLabel: 'pen options',
                trigger: Text(
                  'pen options',
                  style: TextStyle(
                    fontSize: 14,
                    color: palette.ink,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nib', style: body),
                    SizedBox(height: 8),
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
                    Text(
                      'Any widget can open a popover.',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.inkMuted,
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
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Tooltip — a sketched card with an arrow to its target',
            style: body,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  child: DrawkitTooltip(
                    target: _tipTarget,
                    child: const Text('the target is down there'),
                  ),
                ),
                PositionedDirectional(
                  top: 70,
                  start: 240,
                  child: SizedBox(
                    key: _tipTarget,
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
          const SizedBox(height: 10),
          Text(_last, style: body.copyWith(color: palette.inkMuted)),
        ],
      ),
    );
  }
}

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _rail = 0;
  int _bottom = 0;
  int _labels = 0;
  int _flexible = 0;
  int _scrolling = 0;
  int _page = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  static const destinations = [
    DrawkitNavDestination(label: 'Inbox', icon: Text('✉'), badge: 3),
    DrawkitNavDestination(label: 'Drafts', icon: Text('✎')),
    DrawkitNavDestination(label: 'Archive', icon: Text('▤')),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DrawkitAppBar(
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
                  color: palette.inkMuted,
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
          Text(
            'Rail — destinations stack down the side; everything mirrors '
            'in RTL',
            style: body.copyWith(color: palette.inkMuted),
          ),
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
                    style: body.copyWith(color: palette.inkMuted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Bottom bar — one paper strip across the foot',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitBottomNav(
            destinations: destinations,
            selected: _bottom,
            onChanged: (i) => setState(() => _bottom = i),
          ),
          const SizedBox(height: 22),
          Text(
            'Floating — a capsule hovering above the content, badge on the '
            'icon',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitFloatingNavBar(
            destinations: destinations,
            selected: _labels,
            onChanged: (i) => setState(() => _labels = i),
          ),
          const SizedBox(height: 8),
          Text(
            'picked: ${destinations[_labels].label.toLowerCase()}',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 22),
          Text(
            'Floating, flexible — only the pick opens into a label',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitFloatingNavBar(
            destinations: destinations,
            selected: _flexible,
            showLabels: false,
            onChanged: (i) => setState(() => _flexible = i),
          ),
          const SizedBox(height: 8),
          Text(
            'picked: ${destinations[_flexible].label.toLowerCase()}',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 22),
          Text(
            'Scroll-aware — scrolling forward tucks the bar away, the '
            'first pull back brings it home',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Column(
              children: [
                Expanded(
                  child: DrawkitCard(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: 40,
                      itemBuilder: (context, i) => SizedBox(
                        height: 34,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text('row $i', style: body),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DrawkitFloatingNavBar(
                  destinations: destinations,
                  selected: _scrolling,
                  hideOnScroll: true,
                  scrollController: _scrollController,
                  onChanged: (i) => setState(() => _scrolling = i),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Breadcrumb — the trail, last stop in bold',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
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
              DrawkitBreadcrumbItem(label: 'HB'),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Pager — page numbers in a sketch row',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitPager(
            count: 5,
            page: _page,
            onPage: (i) => setState(() => _page = i),
          ),
        ],
      ),
    );
  }
}

class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  int tab = 0;

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tabs — the pick gets a drawn underline of its own',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitTabs(
            labels: ['overview', 'details', 'notes'],
            active: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          const SizedBox(height: 26),
          Text(
            'Steps — the walk, numbered in the margins',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitSteps(
            children: [
              Text('Pick a seed'),
              Text('Watch the strokes boil'),
              Text('Ship the sketch'),
            ],
          ),
        ],
      ),
    );
  }
}

class PicturesPage extends StatefulWidget {
  const PicturesPage({super.key});

  @override
  State<PicturesPage> createState() => _PicturesPageState();
}

class _PicturesPageState extends State<PicturesPage> {
  final _arrowFrom = GlobalKey();
  final _arrowTo = GlobalKey();

  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A crowd — discs overlap, the overflow confesses', style: body),
          const SizedBox(height: 10),
          DrawkitAvatarGroup(
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
          Text('Doodles — decorative, silent, never interactive', style: body),
          SizedBox(height: 10),
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
          Text('A ticker — hover to pause it', style: body),
          SizedBox(height: 8),
          DrawkitMarquee(
            child: Text(
              'all work and no play makes the pen a dull tool',
              style: body,
            ),
          ),
          const SizedBox(height: 22),
          Text('An arrow — a line from one point to another', style: body),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  child: SizedBox(
                    key: _arrowFrom,
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
                    key: _arrowTo,
                    width: 90,
                    height: 48,
                    child: const DrawkitButton(
                      onPressed: _noop,
                      child: Text('to'),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DrawkitArrow(from: _arrowFrom, to: _arrowTo),
                ),
              ],
            ),
          ),
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
  TextStyle get body => TextStyle(
    fontSize: 14,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.ink,
    decoration: TextDecoration.none,
  );

  TextStyle get hint => TextStyle(
    fontSize: 13,
    height: 1.5,
    color: DrawkitTheme.of(context).palette.inkMuted,
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
    final palette = DrawkitTheme.of(context).palette;
    await showDrawkitDialog<void>(
      context: context,
      child: DrawkitDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A page within the page',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escape folds it away; Tab never wanders outside; focus '
              'returns to the button that opened it.',
              style: body,
            ),
            SizedBox(height: 16),
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
    final palette = DrawkitTheme.of(context).palette;
    return SizedBox(
      width: 460,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawkitHeading(text: 'The Focus Kit', underline: true),
          const SizedBox(height: 8),
          DrawkitHeading(
            text: 'one ring, drawn only while the keyboard is at work',
            level: 3,
            textStyle: TextStyle(color: palette.inkMuted),
          ),
          const SizedBox(height: 12),
          Text(
            'Tab to walk the page · arrows to move · Home/End to jump · '
            'Enter/Space to choose · Escape to close',
            style: hint,
          ),
          SizedBox(height: 20),
          Text(
            'Slider — Home, End, PageUp and PageDown; RTL mirrors the arrows',
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitSlider(
            value: _inkLevel,
            onChanged: (v) => setState(() {
              _inkLevel = v;
              _last = 'ink level ${(v * 100).round()}%';
            }),
          ),
          const SizedBox(height: 22),
          Text(
            'Segments and tabs — the selection owns the single tab stop',
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitSegmentedButton<String>(
            segments: [
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
            [
              'a rough start, all construction lines',
              'the damp layer, still catching light',
              'a clean file, corners folded shut',
            ][_tab],
            style: hint,
          ),
          SizedBox(height: 22),
          Text(
            'Accordion — Up/Down walk the headers, Enter folds a section',
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitAccordion(
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
          SizedBox(height: 22),
          Text(
            'Select and menu — arrows walk, Escape hands focus back',
            style: body,
          ),
          SizedBox(height: 8),
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
                child: Text('maintenance', style: body),
              ),
            ],
          ),
          SizedBox(height: 22),
          Text(
            'Date picker — arrows walk days, PageUp/Down change months',
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitDatePicker(
            value: _date,
            today: DateTime(2026, 6, 15),
            onChanged: (d) => setState(() {
              _date = d;
              _last = 'dated ${d.year}-${d.month}-${d.day}';
            }),
          ),
          const SizedBox(height: 22),
          Text(
            'Breadcrumb and nav rail — plain Tab stops, Enter to choose',
            style: body,
          ),
          SizedBox(height: 10),
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
          Text(
            'Dialog — Escape dismisses, Tab stays inside, focus comes home',
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitButton(
            onPressed: () => _openDialog(),
            child: Text('Open a dialog'),
          ),
          SizedBox(height: 16),
          Text('last action: $_last', style: hint),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class PalettePage extends StatelessWidget {
  const PalettePage({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 22,
    runSpacing: 22,
    children: const [
      _PalettePanel(name: 'paper light', palette: DrawkitPalette.light),
      _PalettePanel(name: 'ink dark', palette: DrawkitPalette.dark),
    ],
  );
}

class _PalettePanel extends StatelessWidget {
  const _PalettePanel({required this.name, required this.palette});

  final String name;
  final DrawkitPalette palette;

  @override
  Widget build(BuildContext context) => DrawkitTheme(
    data: palette.style,
    child: Container(
      width: 520,
      padding: const EdgeInsets.all(18),
      color: palette.paper,
      child: DefaultTextStyle(
        style: TextStyle(
          color: palette.ink,
          fontSize: 14,
          height: 1.4,
          decoration: TextDecoration.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Swatch(name: 'pen', color: palette.pen, paper: palette.paper),
                _Swatch(name: 'ink', color: palette.ink, paper: palette.paper),
                _Swatch(
                  name: 'muted',
                  color: palette.inkMuted,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: 'faint',
                  color: palette.inkFaint,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: 'error',
                  color: palette.error,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: 'success',
                  color: palette.success,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: 'neutral',
                  color: palette.neutral,
                  paper: palette.paper,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DrawkitButton(onPressed: () {}, child: const Text('outline')),
                DrawkitButton(
                  variant: DrawkitButtonVariant.solid,
                  onPressed: () {},
                  child: const Text('solid'),
                ),
                DrawkitButton(
                  tone: DrawkitTone.danger,
                  onPressed: () {},
                  child: const Text('danger'),
                ),
                const DrawkitCheckbox(
                  value: true,
                  semanticLabel: 'sample checkbox',
                  onChanged: null,
                ),
                DrawkitToggle(
                  value: true,
                  semanticLabel: 'sample toggle',
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            DrawkitInput(placeholder: 'placeholder ink'),
            const SizedBox(height: 10),
            Text(
              'tone text darkens (or lightens) until it clears 4.5:1',
              style: TextStyle(
                color: palette.inkMuted,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color, required this.paper});

  final String name;
  final Color color;
  final Color paper;

  @override
  Widget build(BuildContext context) {
    final ratio = drawkitContrast(color, paper);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: paper, width: 1),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$name ${ratio.toStringAsFixed(1)}:1',
          style: TextStyle(
            fontSize: 12,
            color: DrawkitTheme.of(context).palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

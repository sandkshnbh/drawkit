import 'dart:ui' show PointerDeviceKind;

import 'package:drawkit/drawkit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'l10n.dart';

void main() => runApp(DrawkitGalleryApp());

final _sidebarWidth = 210.0;

class DrawkitGalleryApp extends StatelessWidget {
  const DrawkitGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = DrawkitTheme.of(context).palette;
    return WidgetsApp(
      title: tr('drawkit gallery', 'معرض drawkit'),
      color: palette.paper,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) =>
                builder(context),
          ),
      home: Gallery(),
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
    demoArabic = _rtl;
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
                    behavior: _DragScrollBehavior(),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(28),
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
                          SizedBox(height: 6),
                          Text(
                            galleryPages[_page].subtitle,
                            style: TextStyle(
                              color: palette.inkMuted,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 24),
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
  GalleryPage(this.group, this.title, this.subtitle, this.builder);

  final String group;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

/// Filled in per milestone; see the individual page builders below.
List<GalleryPage> get galleryPages => [
  GalleryPage(
    tr('Foundations', 'الأساسات'),
    tr('Surface', 'السطح'),
    tr(
      'The shared sketch surface: seeded chrome behind any child, one boil clock.',
      'سطح الرسم المشترك: إطار مبذور خلف أي محتوى، وساعة غليان واحدة.',
    ),
    (context) => SurfacePage(),
  ),
  GalleryPage(
    tr('Foundations', 'الأساسات'),
    tr('Ink · Palette', 'الحبر · اللوحة'),
    tr(
      'Two papers side by side: the full palette, control by control.',
      'ورقتان جنباً إلى جنب: اللوحة الكاملة، عنصراً عنصراً.',
    ),
    (context) => const PalettePage(),
  ),
  GalleryPage(
    tr('Foundations', 'الأساسات'),
    tr('Motion', 'الحركة'),
    tr(
      'Draw-on tracing, staggered lists, and the error shake — one shared pen.',
      'ترسيم يترافق، وقوائم متتابعة، واهتزاز الخطأ — قلم واحد مشترك.',
    ),
    (context) => const MotionPage(),
  ),
  GalleryPage(
    tr('Foundations', 'الأساسات'),
    tr('Focus & Keyboard', 'التركيز ولوحة المفاتيح'),
    tr(
      'One ring on every control — Tab, arrows, Home/End, Enter, Escape.',
      'حلقة واحدة على كل عنصر — Tab والأسهم وHome/End وEnter وEscape.',
    ),
    (context) => const FocusPage(),
  ),
  GalleryPage(
    tr('Actions', 'الأفعال'),
    tr('Buttons', 'الأزرار'),
    tr(
      'Variants, states, tones — plus icon buttons, the floating pen, and the fab menu.',
      'أنماط وحالات وألوان — مع أزرار الأيقونات والقلم العائم وقائمة الإجراءات.',
    ),
    (context) => const ButtonPage(),
  ),
  GalleryPage(
    tr('Forms', 'النماذج'),
    tr('Fields', 'الحقول'),
    tr(
      'Input, textarea, and search: real text editing behind a sketch outline.',
      'إدخال ونص متعدد وبحث: تحرير حقيقي خلف إطار مرسوم.',
    ),
    (context) => const FieldPage(),
  ),
  GalleryPage(
    tr('Forms', 'النماذج'),
    tr('Choices', 'الخيارات'),
    tr(
      'Checkboxes, radios, toggles — and chips and segments for the wider picks.',
      'مربعات اختيار وراديو ومفاتيح — مع الرقائق والمقاطع للاختيارات الأوسع.',
    ),
    (context) => const ChoicePage(),
  ),
  GalleryPage(
    tr('Forms', 'النماذج'),
    tr('Select & Dates', 'القوائم والتواريخ'),
    tr(
      'A dropdown and a calendar: pick one value out of many.',
      'قائمة منسدلة وتقويم: اختر قيمة واحدة من كثير.',
    ),
    (context) => const SelectPage(),
  ),
  GalleryPage(
    tr('Forms', 'النماذج'),
    tr('Values', 'القيم'),
    tr(
      'Slider, stepper, and stars: numbers and ratings with a drawn response.',
      'منزلق وعدّاد ونجوم: أرقام وتقييمات باستجابة مرسومة.',
    ),
    (context) => const ValuesPage(),
  ),
  GalleryPage(
    tr('Navigation', 'التنقل'),
    tr('Navigation', 'التنقل'),
    tr(
      'App bar, rail, bottom bar, breadcrumb, pager — and the floating capsule.',
      'شريط علوي ومسار وشريط سفلي وفتات وناقل — والكبسولة العائمة.',
    ),
    (context) => const NavigationPage(),
  ),
  GalleryPage(
    tr('Navigation', 'التنقل'),
    tr('Tabs & Steps', 'التبويبات والخطوات'),
    tr(
      'Tabs that slide the underline, steps that count the walk.',
      'تبويبات تزحزح الخط، وخطوات تعدّ المشوار.',
    ),
    (context) => const TabsPage(),
  ),
  GalleryPage(
    tr('Overlays', 'الطبقات العلوية'),
    tr('Menus & Popovers', 'القوائم والمنبثقات'),
    tr(
      'Dropdowns, popovers, the tooltip, and the command palette.',
      'قوائم منسدلة ومنبثقات وتلميح ولوحة أوامر.',
    ),
    (context) => const MenusPage(),
  ),
  GalleryPage(
    tr('Overlays', 'الطبقات العلوية'),
    tr('Dialogs & Sheets', 'الحوارات واللوحات'),
    tr(
      'Modals and drawers that trace themselves in over the page.',
      'نوافذ ودرج يترسمان فوق الصفحة.',
    ),
    (context) => const DialogsPage(),
  ),
  GalleryPage(
    tr('Feedback', 'التغذية الراجعة'),
    tr('Feedback & States', 'التغذية والحالات'),
    tr(
      'Toasts, alerts, validation, empty margins, loading, and the pull.',
      'تنبيهات وتحذيرات وتحقق وهوامش فارغة وتحميل وسحب.',
    ),
    (context) => const FeedbackPage(),
  ),
  GalleryPage(
    tr('Display', 'العرض'),
    tr('Cards & Tables', 'البطاقات والجداول'),
    tr(
      'Frames, rules, badges, lists, the accordion, and a ruled ledger.',
      'إطارات وقواعد وشارات وقوائم وأكورديون وسجل مسطّر.',
    ),
    (context) => const ContainersPage(),
  ),
  GalleryPage(
    tr('Display', 'العرض'),
    tr('Type & Ink', 'الخط والحبر'),
    tr(
      'Headings, underline, highlight, circle, quote, and kbd.',
      'عناوين وخط سفلي وتظليل ودائرة واقتباس ومفاتيح.',
    ),
    (context) => const TypePage(),
  ),
  GalleryPage(
    tr('Display', 'العرض'),
    tr('Pictures & Extras', 'الصور والإضافات'),
    tr(
      'Faces, plates, doodles, arrows, and a ticker.',
      'وجوه وألواح وخربشات وأسهم وشريط متحرك.',
    ),
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
                      tr('RTL', 'الاتجاه'),
                      style: TextStyle(
                        color: palette.inkMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DrawkitToggle(
                      value: rtl,
                      semanticLabel: tr('RTL', 'الاتجاه'),
                      onChanged: onToggleRtl,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      tr('dark', 'داكن'),
                      style: TextStyle(
                        color: palette.inkMuted,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DrawkitToggle(
                      value: dark,
                      semanticLabel: tr('dark ink', 'حبر داكن'),
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
            child: Center(
              child: Text(
                tr('hover me — I am redrawn', 'مرّر فوقي — أُعيد رسمي'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _NumberStepper(
          label: tr('roughness', 'الخشونة'),
          value: roughness,
          step: 0.1,
          min: 0,
          max: 3,
          onChanged: (v) => setState(() => roughness = v),
        ),
        _NumberStepper(
          label: tr('boil', 'الغليان'),
          value: boil,
          step: 0.1,
          min: 0,
          max: 1.5,
          onChanged: (v) => setState(() => boil = v),
        ),
        _NumberStepper(
          label: tr('seed', 'البذرة'),
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
              child: Text(
                animate
                    ? tr('boil: on', 'الغليان: مفعّل')
                    : tr('boil: off', 'الغليان: متوقف'),
              ),
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
                value < 0
                    ? tr('random', 'عشوائي')
                    : value.toStringAsFixed(step < 1 ? 1 : 0),
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
          Text(
            tr(
              'Variants — one frame, three finishes',
              'الأنماط — إطار واحد وثلاث لمسات',
            ),
            style: body,
          ),
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
                  child: Text(ar(variant.name)),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr('Tones — and the disabled hand', 'الألوان — واليد المعطّلة'),
            style: body,
          ),
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
                  child: Text(
                    tr('tone: ${tone.name}', 'اللون: ${ar(tone.name)}'),
                  ),
                ),
              DrawkitButton(
                onPressed: null,
                child: Text(tr('disabled', 'معطّل')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'States — loading slows the boil, error and success re-ink',
              'الحالات — التحميل يبطئ الغليان، والخطأ والنجاح يعيدان الحبر',
            ),
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
                  child: Text(tr('state: ${s.name}', 'الحالة: ${ar(s.name)}')),
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
                child: Text(
                  tr(
                    'cycle state: ${state.name}',
                    'بدّل الحالة: ${ar(state.name)}',
                  ),
                ),
              ),
              Text(
                tr(
                  'Tab to me for the focus ring →',
                  'اضغط Tab لترى حلقة التركيز ←',
                ),
                style: body.copyWith(color: palette.inkMuted),
              ),
              DrawkitButton(
                autofocus: false,
                onPressed: _noop,
                child: Text(tr('focus me', 'ركّز عليّ')),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            tr(
              'Icon buttons — one glyph, a required label',
              'أزرار الأيقونات — رمز واحد ووسم لازم',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DrawkitIconButton(
                semanticLabel: tr('Favourite', 'المفضلة'),
                tone: _favourite ? DrawkitTone.accent : DrawkitTone.neutral,
                variant: _favourite
                    ? DrawkitButtonVariant.solid
                    : DrawkitButtonVariant.outline,
                onPressed: () => setState(() => _favourite = !_favourite),
                child: Text(_favourite ? '★' : '☆'),
              ),
              const SizedBox(width: 8),
              DrawkitIconButton(
                semanticLabel: tr('Clear the pages', 'امسح الصفحات'),
                tone: DrawkitTone.danger,
                onPressed: () => setState(() => _pages = 0),
                child: const Text('×'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Floating pen — the one action that never scrolls away',
              'القلم العائم — الفعل الذي لا يبتعد بالتمرير',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DrawkitFab(
                semanticLabel: tr('add a page', 'أضف صفحة'),
                onPressed: () => setState(() => _pages += 1),
                child: const Text('＋'),
              ),
              const SizedBox(width: 16),
              Text(
                _pages == 0
                    ? tr('no new pages yet', 'لا صفحات جديدة بعد')
                    : _pages == 1
                    ? tr('1 new page', 'صفحة جديدة واحدة')
                    : tr('$_pages new pages', '$_pages صفحات جديدة'),
                style: body.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Fab menu — labelled pills unfold above the circle',
              'قائمة الإجراءات — أقراص معنونة تتفتح فوق الدائرة',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: DrawkitFabMenu(
                semanticLabel: tr('quick actions', 'إجراءات سريعة'),
                items: [
                  DrawkitFabMenuItem(
                    label: tr('New note', 'ملاحظة جديدة'),
                    icon: Text('✎'),
                    onPressed: () => showDrawkitToast(
                      context,
                      message: tr('a fresh note', 'ملاحظة جديدة'),
                    ),
                  ),
                  DrawkitFabMenuItem(
                    label: tr('New sketch', 'رسمة جديدة'),
                    icon: Text('✏'),
                    onPressed: () => showDrawkitToast(
                      context,
                      message: tr('a blank page', 'صفحة بيضاء'),
                    ),
                  ),
                  DrawkitFabMenuItem(
                    label: tr('Import', 'استيراد'),
                    icon: Text('⌤'),
                    onPressed: () => showDrawkitToast(
                      context,
                      message: tr('importing…', 'يستورد…'),
                    ),
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
            semanticLabel: tr('accept the scribbles', 'اقبل الخربشات'),
            onChanged: (v) => setState(() => terms = v),
          ),
          text: tr(
            'I accept the scribbles (checked, with the check drawn on)',
            'أقبل الخربشات (محدد، والعلامة مرسومة)',
          ),
          onTap: () => setState(() => terms = !terms),
        ),
        _ChoiceRow(
          control: DrawkitCheckbox(
            value: newsletter,
            semanticLabel: tr(
              'send me one doodle a week',
              'أرسل لي خربشة كل أسبوع',
            ),
            onChanged: (v) => setState(() => newsletter = v),
          ),
          text: tr('Send me one doodle a week', 'أرسل لي خربشة كل أسبوع'),
          onTap: () => setState(() => newsletter = !newsletter),
        ),
        _ChoiceRow(
          control: DrawkitCheckbox(
            value: false,
            semanticLabel: tr('disabled checkbox', 'مربع اختيار معطّل'),
            onChanged: null,
          ),
          text: tr(
            'Disabled checkbox — the ink stays, the hand stops',
            'مربع اختيار معطّل — الحبر يبقى واليد تتوقف',
          ),
          onTap: null,
        ),
        const SizedBox(height: 26),
        for (final f in const ['apple', 'banana', 'cherry'])
          _ChoiceRow(
            control: DrawkitRadio<String>(
              value: f,
              groupValue: fruit,
              semanticLabel: tr('radio $f', 'اختيار $f'),
              onChanged: (v) => setState(() => fruit = v),
            ),
            text: tr('Radio: $f', 'اختيار: ${ar(f)}'),
            onTap: () => setState(() => fruit = f),
          ),
        const SizedBox(height: 26),
        _ChoiceRow(
          control: DrawkitToggle(
            value: darkInk,
            semanticLabel: tr('dark ink', 'حبر داكن'),
            onChanged: (v) => setState(() => darkInk = v),
          ),
          text: tr(
            'Dark ink (toggle — the knob travels 20px)',
            'حبر داكن (مفتاح — المقبض يتحرك 20px)',
          ),
          onTap: () => setState(() => darkInk = !darkInk),
        ),
        _ChoiceRow(
          control: DrawkitToggle(
            value: true,
            semanticLabel: tr('disabled toggle', 'مفتاح معطّل'),
            onChanged: null,
          ),
          text: tr('Disabled toggle', 'مفتاح معطّل'),
          onTap: null,
        ),
        const SizedBox(height: 26),
        Text(
          tr('Chip — a tag that picks itself', 'رقاقة — وسم يختار نفسه'),
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        DrawkitChip(
          selected: chip,
          onChanged: (v) => setState(() => chip = v),
          child: Text(tr('dashed', 'متقطع')),
        ),
        SizedBox(height: 26),
        Text(
          tr(
            'Segments — one frame, a scribbled wash for the pick',
            'المقاطع — إطار واحد وغسلة خربشة للاختيار',
          ),
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 10),
        DrawkitSegmentedButton<String>(
          segments: [
            DrawkitSegment(value: 'grid', label: tr('Grid', 'شبكة')),
            DrawkitSegment(value: 'list', label: tr('List', 'قائمة')),
            DrawkitSegment(value: 'kanban', label: tr('Kanban', 'كانبان')),
          ],
          selected: view,
          onChanged: (value) => setState(() => view = value),
        ),
        const SizedBox(height: 26),
        Text(
          tr(
            'Tab moves focus, Space/Enter flips — the focus ring answers.',
            'Tab ينقل التركيز وSpace/Enter يبدّل — وحلقة التركيز تجيب.',
          ),
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
          tr('Name', 'الاسم'),
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
            placeholder: tr('e.g. Scribbly McPenface', 'مثال: خربوش بن قلم'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          tr('Notes', 'ملاحظات'),
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
            placeholder: tr(
              'What should the pen remember?',
              'ماذا يتذكر القلم؟',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: 300,
          child: DrawkitInput(
            placeholder: tr(
              'disabled — no cursor, no edits',
              'معطّل — لا مؤشر ولا تعديل',
            ),
            enabled: false,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          tr(
            'Search — the magnifier holds the leading gutter',
            'البحث — العدسة تحمل الهامش الأول',
          ),
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 300,
          child: DrawkitSearchField(
            placeholder: tr('search the sketchbook…', 'ابحث في دفتر الرسوم…'),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _query.isEmpty
              ? tr('nothing typed yet', 'لم يُكتب شيء بعد')
              : tr('you are looking for: $_query', 'تبحث عن: $_query'),
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          tr(
            'name: ${name.text.isEmpty ? '…' : name.text}\nnotes: ${notes.text.isEmpty ? '…' : notes.text.replaceAll('\n', ' ⏎ ')}',
            'الاسم: ${name.text.isEmpty ? '…' : name.text}\nملاحظات: ${notes.text.isEmpty ? '…' : notes.text.replaceAll('\n', ' ⏎ ')}',
          ),
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

  List<DrawkitSelectOption<String>> get _fruits => [
    DrawkitSelectOption(value: 'apple', label: tr('Apple', 'تفاحة')),
    DrawkitSelectOption(value: 'banana', label: tr('Banana', 'موزة')),
    DrawkitSelectOption(value: 'cherry', label: tr('Cherry', 'كرزة')),
    DrawkitSelectOption(
      value: 'durian',
      label: tr('Durian (probably a mistake)', 'دوريان (لعلها سهو)'),
    ),
    DrawkitSelectOption(
      value: 'elderberry',
      label: tr('Elderberry', 'توت البيلسان'),
    ),
    DrawkitSelectOption(value: 'fig', label: tr('Fig', 'تين')),
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
            placeholder: tr('choose…', 'اختر…'),
            onChanged: (v) => setState(() => fruit = v),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: 260,
          child: DrawkitSelect<String>(
            options: _fruits,
            value: null,
            placeholder: tr('choose…', 'اختر…'),
            onChanged: null,
            semanticLabel: tr('disabled select', 'قائمة معطّلة'),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          tr(
            'picked: ${fruit ?? '—'}',
            'المختار: ${fruit == null ? '—' : ar(fruit!)}',
          ),
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _date == null
              ? tr(
                  'Date picker — nothing picked',
                  'منتقي التاريخ — لم يُختر شيء',
                )
              : tr(
                  'Date picker — ${_date!.year}-${_date!.month}-${_date!.day}',
                  'منتقي التاريخ — ${_date!.year}-${_date!.month}-${_date!.day}',
                ),
          style: TextStyle(
            color: palette.inkMuted,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 10),
        DrawkitDatePicker(
          value: _date,
          onChanged: (date) => setState(() => _date = date),
          monthNames: monthNames,
          weekdayLabels: weekdayLabels,
          semanticLabel: tr('sheet date', 'تاريخ اللوحة'),
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
          Text(
            tr(
              'Card — one seeded frame around anything',
              'بطاقة — إطار مبذور حول أي شيء',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('A card', 'بطاقة'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(
                    'The frame is one seeded stroke; put anything inside.',
                    'الإطار خط مبذور واحد؛ ضع ما تشاء بالداخل.',
                  ),
                  style: caption,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    DrawkitBadge(child: Text(tr('outline', 'محدد'))),
                    SizedBox(width: 10),
                    DrawkitBadge(
                      variant: DrawkitBadgeVariant.scribble,
                      child: Text(tr('scribble', 'خربشة')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Divider — a hand rule that stays hand-drawn',
              'فاصل — مسطرة يد تبقى مرسومة',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          const DrawkitDivider(),
          const SizedBox(height: 22),
          Text(
            tr(
              'List — the marker gutter redraws per pick',
              'قائمة — هامش العلامات يُرسم عند كل اختيار',
            ),
            style: caption,
          ),
          SizedBox(height: 10),
          Row(
            children: [
              DrawkitButton(
                onPressed: () => setState(() {
                  marker = marker == DrawkitListMarker.dash
                      ? DrawkitListMarker.check
                      : DrawkitListMarker.dash;
                }),
                child: Text(
                  tr('marker: ${marker.name}', 'العلامة: ${ar(marker.name)}'),
                ),
              ),
              SizedBox(width: 18),
            ],
          ),
          SizedBox(height: 12),
          DrawkitList(
            marker: marker,
            children: [
              Text(
                tr(
                  'Seeded randomness makes every mount a fresh sketch.',
                  'العشوائية المبذورة تجعل كل ظهور رسمة جديدة.',
                ),
              ),
              Text(
                tr(
                  'Boil frames come from the variants generator, three per stroke.',
                  'إطارات الغليان تأتي من مولّد الصور، ثلاثة لكل خط.',
                ),
              ),
              Text(
                tr(
                  'The marker gutter is 24px of reserved padding.',
                  'هامش العلامة حشوة محجوزة 24px.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Accordion — headers unfold on a sketch line',
              'الأكورديون — رؤوس تتفتح على خط مرسوم',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitAccordion(
            initiallyExpanded: {1},
            sections: [
              DrawkitAccordionSection(
                title: tr('Pencils', 'أقلام رصاص'),
                child: Text(
                  tr(
                    'HB, 2B, and one grudging 4H kept for margins.',
                    'HB و2B و4H واحد متحفظ للهوامش.',
                  ),
                  style: body,
                ),
              ),
              DrawkitAccordionSection(
                title: tr('Paper', 'ورق'),
                child: Text(
                  tr(
                    'Ruled, graph, and the good cotton stock.',
                    'مسطر ومربعات والخام القطني الجيد.',
                  ),
                  style: body,
                ),
              ),
              DrawkitAccordionSection(
                title: tr('Ink', 'حبر'),
                child: Text(
                  tr(
                    'Waterproof black, and a red for corrections.',
                    'أسود مقاوم للماء وأحمر للتصحيحات.',
                  ),
                  style: body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Table — a ruled ledger, header line, faint row rules',
              'جدول — سجل مسطّر وخط رأس وقواعد صفوف باهتة',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitTable(
            columns: [
              DrawkitTableColumn(label: tr('Pencil', 'القلم'), flex: 2),
              DrawkitTableColumn(label: tr('Qty', 'الكمية')),
              DrawkitTableColumn(label: tr('Total', 'الإجمالي')),
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
          DrawkitHeading(
            text: tr('The Type Kit', 'طقم الخطوط'),
            underline: true,
          ),
          const SizedBox(height: 8),
          DrawkitHeading(
            text: tr(
              'display type with the pen in the margins',
              'خط عرضيّ والقلم في الهوامش',
            ),
            level: 3,
            textStyle: TextStyle(color: palette.inkMuted),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Underline — every wrapped line gets its own stroke',
              'الخط السفلي — كل سطر ملتف له خطه',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitUnderline(
            text: tr(
              'Every wrapped line gets its own underline stroke, so a sentence that crosses lines stays ruled to the last word.',
              'كل سطر ملتف له خط سفلي خاص، فتبقى الجملة الممتدة مسطّرة حتى آخر كلمة.',
            ),
            textStyle: body,
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Highlight — a marker wash at 30% multiply',
              'التظليل — غسلة قلم عريض عند 30% بالضرب',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitHighlight(
            text: tr(
              'Important, but not shouting: the marker wash is one 6px scribble at 30% in multiply.',
              'مهم، لكن دون صراخ: الغسلة خربشة 6px عند 30% بالضرب.',
            ),
            textStyle: body,
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Circle — the word, circled on arrival',
              'الدائرة — الكلمة تُطوّق عند الوصول',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitCircle(
            text: tr('circled on arrival', 'طُوّقت عند الوصول'),
            textStyle: TextStyle(
              fontSize: 20,
              height: 1.5,
              color: palette.ink,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            tr(
              'Quote — the margin remembers who said it',
              'الاقتباس — الهامش يتذكر قائله',
            ),
            style: caption,
          ),
          const SizedBox(height: 10),
          DrawkitQuote(
            text: tr(
              'Any sufficiently advanced CSS is indistinguishable from a canvas library.',
              'أي CSS متقدم بما يكفي لا يُميّز عن مكتبة رسم.',
            ),
            footer: Text(
              tr('— the internet, paraphrased', '— الإنترنت، مقتبساً'),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            tr('Kbd — keys drawn like keys', 'المفاتيح — أزرار كالأزرار'),
            style: caption,
          ),
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
            tr(
              'Sketch-in — every stroke below traces itself on mount',
              'الترسيم — كل خط أدناه يرسم نفسه عند الظهور',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitSketchIn(
            key: ValueKey('sketch$_run'),
            child: DrawkitCard(
              child: Text(
                tr(
                  'The frame draws first, the words were already written.',
                  'يُرسم الإطار أولاً، والكلمات كُتبت سلفاً.',
                ),
                style: body,
              ),
            ),
          ),
          SizedBox(height: 22),
          Text(
            tr(
              'Stagger — one clock, a step apart',
              'التتابع — ساعة واحدة وخطوة فارقة',
            ),
            style: body,
          ),
          SizedBox(height: 10),
          DrawkitStagger(
            key: ValueKey('stagger$_run'),
            step: Duration(milliseconds: 120),
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final task in [
                tr('sketch the outline', 'ارسم المخطط'),
                tr('boil for three frames', 'اغلِ ثلاث إطارات'),
                tr('mirror for RTL', 'انعكس لليمين'),
                tr('ship it', 'أطلقها'),
              ])
                DrawkitCard(child: Text(task, style: body)),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr('Shake — the wrong! wiggle', 'الاهتزاز — رجفة الخطأ!'),
            style: body,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DrawkitShake(
                  controller: _shake,
                  child: DrawkitInput(
                    placeholder: tr('not an email', 'ليست بريداً'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DrawkitButton(
                onPressed: _shake.shake,
                child: Text(tr('shake it', 'اهززها')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          DrawkitButton(
            onPressed: () => setState(() => _run++),
            child: Text(tr('replay the drawing', 'أعد الرسم')),
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
            tr(
              'Slider — stroke width ${_size.toStringAsFixed(2)}',
              'المنزلق — سماكة الخط ${_size.toStringAsFixed(2)}',
            ),
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
            _copies == 1
                ? tr('Stepper — 1 copy', 'العدّاد — نسخة واحدة')
                : tr('Stepper — $_copies copies', 'العدّاد — $_copies نسخ'),
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitStepper(
            value: _copies,
            min: 1,
            max: 9,
            semanticLabel: tr('copies', 'نسخ'),
            onChanged: (value) => setState(() => _copies = value),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Rating — tap a star, tap again to clear one ($_stars/5)',
              'التقييم — اضغط نجمة، وأعد الضغط لتُمسح واحدة ($_stars/5)',
            ),
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
  List<String> _notes = [
    tr('Sharpen the HB', 'اسنن HB'),
    tr('Dust the eraser', 'انفض الممحاة'),
    tr('Rinse the nib', 'اغسل السن'),
  ];
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
          ? tr(
              'An address, please — the pen refuses to guess.',
              'عنوان من فضلك — القلم يرفض التخمين.',
            )
          : tr(
              'That is missing its @ — even the ink knows.',
              'ينقصه @ — حتى الحبر يعرف.',
            );
    });
  }

  void _deleteNote(int index) {
    final removed = _notes[index];
    setState(() => _notes = [..._notes]..removeAt(index));
    showDrawkitToast(
      context,
      message: tr('“$removed” torn out', '“$removed” قُطعت'),
      tone: DrawkitTone.neutral,
      action: DrawkitToastAction(
        label: tr('Undo', 'تراجع'),
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
          Text(
            tr(
              'Progress — ${(_progress * 100).round()}%',
              'التقدم — ${(_progress * 100).round()}%',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitProgressBar(
            value: _progress,
            semanticLabel: tr('gallery progress', 'تقدم المعرض'),
          ),
          const SizedBox(height: 12),
          DrawkitSlider(
            value: _progress,
            divisions: 20,
            onChanged: (value) => setState(() => _progress = value),
          ),
          const SizedBox(height: 12),
          DrawkitProgressBar(semanticLabel: tr('waiting', 'ينتظر')),
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
          Text(
            tr('Alert — a margin note in ink', 'التنبيه — ملاحظة هامش بالحبر'),
            style: body,
          ),
          const SizedBox(height: 10),
          DrawkitAlert(
            tag: Text(tr('rant', 'شكوى')),
            child: Text(
              tr(
                'The sketch layer never lies, the browser sometimes does.',
                'طبقة الرسم لا تكذب أبداً، المتصفح يكذب أحياناً.',
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            tr(
              'Validation — the outline inks red, the message speaks',
              'التحقق — الإطار يحمرّ والرسالة تتكلم',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 320,
            child: DrawkitInput(
              controller: _email,
              placeholder: 'you@sketchbook.paper',
              helper: tr('We never share it.', 'لا نشاركها أبداً.'),
              error: _emailError,
              onSubmitted: (_) => _validate(),
            ),
          ),
          const SizedBox(height: 10),
          DrawkitButton(
            onPressed: _validate,
            child: Text(tr('Validate', 'تحقق')),
          ),
          const SizedBox(height: 26),
          Text(
            tr(
              'Notes — deleting offers an Undo',
              'الملاحظات — الحذف يعرض تراجعاً',
            ),
            style: body,
          ),
          const SizedBox(height: 10),
          if (_notes.isEmpty)
            SizedBox(
              height: 220,
              child: DrawkitEmpty(
                doodle: DrawkitDoodleKind.burst,
                title: tr('The margin is blank', 'الهامش فارغ'),
                message: tr(
                  'Every note was torn out, but the pen remembers.',
                  'قُطعت كل الملاحظات، لكن القلم يتذكر.',
                ),
                action: DrawkitButton(
                  onPressed: () => setState(
                    () => _notes = [
                      tr('Sharpen the HB', 'اسنن HB'),
                      tr('Dust the eraser', 'انفض الممحاة'),
                    ],
                  ),
                  child: Text(tr('Write two back', 'أعد كتابة اثنتين')),
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
            tr(
              'Pull-to-refresh — drag the list down past the flip',
              'اسحب للتحديث — اسحب القائمة للأسفل حتى الانقلاب',
            ),
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
                        child: Text(
                          tr('fetched page $n', 'صفحة مجلوبة $n'),
                          style: body,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Progress and skeletons keep the page honest while it waits',
              'التقدم والهياكل تحافظ على صدق الصفحة أثناء الانتظار',
            ),
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
  String _last = tr('nothing yet', 'لا شيء بعد');

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
            tr(
              'Modals — the panel traces itself in',
              'النوافذ — اللوحة ترسم نفسها',
            ),
            style: body,
          ),
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
                            tr('Tear this page out?', 'انزع هذه الصفحة؟'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              'The ink is still wet — nothing is saved yet.',
                              'الحبر ما زال رطباً — لم يُحفظ شيء بعد.',
                            ),
                            style: body,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DrawkitButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(tr('keep', 'أبقها')),
                              ),
                              const SizedBox(width: 10),
                              DrawkitButton(
                                variant: DrawkitButtonVariant.solid,
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(tr('tear it', 'انزعها')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  if (!mounted) return;
                  setState(
                    () => _last = tr(
                      'dialog answered: $answer',
                      'أجاب الحوار: $answer',
                    ),
                  );
                },
                child: Text(tr('open dialog', 'افتح الحوار')),
              ),
              DrawkitButton(
                onPressed: () => showDrawkitSheet(
                  context: context,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Sketchbook options', 'خيارات دفتر الرسوم'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(
                          'Drag the handle down or tap the scrim to fold it away.',
                          'اسحب المقبض للأسفل أو انقر خارج اللوحة لطيّها.',
                        ),
                        style: body,
                      ),
                      const SizedBox(height: 14),
                      DrawkitButton(
                        variant: DrawkitButtonVariant.solid,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(tr('done', 'تم')),
                      ),
                    ],
                  ),
                ),
                child: Text(tr('bottom sheet', 'لوحة سفلية')),
              ),
              DrawkitButton(
                onPressed: () => showDrawkitSheet(
                  context: context,
                  edge: DrawkitSheetEdge.end,
                  child: Text(
                    tr('a quiet side drawer', 'درج جانبي هادئ'),
                    style: body,
                  ),
                ),
                child: Text(tr('side sheet', 'لوحة جانبية')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Toasts — bottom pills that excuse themselves',
              'التنبيهات العابرة — أقراص سفلية تعتذر وتنصرف',
            ),
            style: body,
          ),
          SizedBox(height: 10),
          Row(
            children: [
              DrawkitButton(
                onPressed: () => showDrawkitToast(
                  context,
                  message: tr(
                    'saved to the sketchbook',
                    'حُفظت في دفتر الرسوم',
                  ),
                ),
                child: Text(tr('toast ok', 'تنبيه نجاح')),
              ),
              const SizedBox(width: 10),
              DrawkitButton(
                tone: DrawkitTone.danger,
                onPressed: () => showDrawkitToast(
                  context,
                  message: tr('the ink ran out', 'نفد الحبر'),
                  tone: DrawkitTone.danger,
                ),
                child: Text(tr('toast fail', 'تنبيه فشل')),
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
  String _last = tr('nothing yet', 'لا شيء بعد');

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
            tr('Menus — panels that fold away', 'القوائم — لوحات تُطوى بعيداً'),
            style: body,
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DrawkitMenu(
                semanticLabel: tr('view options', 'خيارات العرض'),
                items: [
                  DrawkitMenuItem(
                    label: tr('Ruled paper', 'ورق مسطر'),
                    checked: _ruled,
                    onSelected: () => setState(() => _ruled = true),
                  ),
                  DrawkitMenuItem(
                    label: tr('Graph paper', 'ورق مربعات'),
                    checked: _graph,
                    onSelected: () => setState(() => _graph = true),
                  ),
                  DrawkitMenuItem.divider(),
                  DrawkitMenuItem(
                    label: tr('Tracing paper', 'ورق شفاف'),
                    hint: '⌘T',
                  ),
                  DrawkitMenuItem(
                    label: tr('Save sheet', 'احفظ الورقة'),
                    hint: '⌘S',
                    onSelected: () => showDrawkitToast(
                      context,
                      message: tr('sheet saved', 'حُفظت الورقة'),
                    ),
                  ),
                ],
                child: Text(tr('view', 'عرض')),
              ),
              DrawkitPopover(
                semanticLabel: tr('pen options', 'خيارات القلم'),
                trigger: Text(
                  tr('pen options', 'خيارات القلم'),
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
                    Text(tr('Nib', 'السن'), style: body),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        for (final nib in ['fine', 'medium', 'broad']) ...[
                          DrawkitButton(
                            onPressed: () => showDrawkitToast(
                              context,
                              message: tr(
                                '$nib nib loaded',
                                'رُكّب السن ${ar(nib)}',
                              ),
                            ),
                            child: Text(ar(nib)),
                          ),
                          if (nib != 'broad') SizedBox(width: 8),
                        ],
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      tr(
                        'Any widget can open a popover.',
                        'أي عنصر يستطيع فتح منبثقة.',
                      ),
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
                    commands: [
                      DrawkitCommand(
                        label: tr('Open sheet', 'افتح الورقة'),
                        value: 'open',
                        hint: '⌘O',
                      ),
                      DrawkitCommand(
                        label: tr('Save sheet', 'احفظ الورقة'),
                        value: 'save',
                        hint: '⌘S',
                      ),
                      DrawkitCommand(
                        label: tr('Export as PNG', 'صدّر PNG'),
                        value: 'export',
                        keywords: [tr('image', 'صورة'), tr('picture', 'رسم')],
                      ),
                      DrawkitCommand(
                        label: tr('Clear page', 'امسح الصفحة'),
                        value: 'clear',
                        keywords: [tr('erase', 'محو'), tr('wipe', 'مسح')],
                      ),
                    ],
                  );
                  if (!mounted || result == null) return;
                  setState(
                    () =>
                        _last = tr('command: $result', 'الأمر: ${ar(result)}'),
                  );
                },
                child: Text(tr('command palette', 'لوحة الأوامر')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Tooltip — a sketched card with an arrow to its target',
              'التلميح — بطاقة مرسومة بسهم إلى هدفها',
            ),
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
                    child: Text(
                      tr('the target is down there', 'الهدف هناك بالأسفل'),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 70,
                  start: 240,
                  child: SizedBox(
                    key: _tipTarget,
                    width: 90,
                    height: 48,
                    child: DrawkitButton(
                      onPressed: _noop,
                      child: Text(tr('target', 'الهدف')),
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

  static List<DrawkitNavDestination> get destinations => [
    DrawkitNavDestination(
      label: tr('Inbox', 'الوارد'),
      icon: Text('✉'),
      badge: 3,
    ),
    DrawkitNavDestination(label: tr('Drafts', 'المسودات'), icon: Text('✎')),
    DrawkitNavDestination(label: tr('Archive', 'الأرشيف'), icon: Text('▤')),
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
            title: Text(tr('Sketchbook', 'دفتر الرسوم')),
            actions: [
              Text(
                ar('save'),
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
            tr(
              'Rail — destinations stack down the side; everything mirrors in RTL',
              'المسار — الوجهات تصطف على الجانب؛ وكل شيء ينعكس في RTL',
            ),
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
                    '${tr('rail picked: ', 'اختيار المسار: ')}${destinations[_rail].label.toLowerCase()}',
                    style: body.copyWith(color: palette.inkMuted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Bottom bar — one paper strip across the foot',
              'الشريط السفلي — شريحة ورق واحدة عبر القدم',
            ),
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
            tr(
              'Floating — a capsule hovering above the content, badge on the icon',
              'العائم — كبسولة تحوم فوق المحتوى، والشارة على الأيقونة',
            ),
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
            '${tr('picked: ', 'المختار: ')}${destinations[_labels].label.toLowerCase()}',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Floating, flexible — only the pick opens into a label',
              'عائم، مرن — الاختيار وحده ينفتح في تسمية',
            ),
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
            '${tr('picked: ', 'المختار: ')}${destinations[_flexible].label.toLowerCase()}',
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Scroll-aware — scrolling forward tucks the bar away, the first pull back brings it home',
              'يتابع التمرير — التمرير للأمام يخبئ الشريط، وأول سحبة للخلف تعيده',
            ),
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
                          child: Text(tr('row $i', 'صف $i'), style: body),
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
            tr(
              'Breadcrumb — the trail, last stop in bold',
              'الفتات — الدرب، ومحطته الأخيرة عريضة',
            ),
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(
                label: tr('Sketchbook', 'دفتر الرسوم'),
                onTap: () => showDrawkitToast(
                  context,
                  message: tr('back to the book', 'عودة إلى الدفتر'),
                ),
              ),
              DrawkitBreadcrumbItem(
                label: tr('Pencils', 'أقلام رصاص'),
                onTap: () => showDrawkitToast(
                  context,
                  message: tr('pencil drawer', 'جرّار الأقلام'),
                ),
              ),
              DrawkitBreadcrumbItem(label: 'HB'),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Pager — page numbers in a sketch row',
              'الترقيم — أرقام الصفحات في صف مرسوم',
            ),
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
            tr(
              'Tabs — the pick gets a drawn underline of its own',
              'التبويبات — لكل اختيار خط سفلي مرسوم',
            ),
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitTabs(
            labels: [
              tr('overview', 'نظرة عامة'),
              tr('details', 'تفاصيل'),
              tr('notes', 'ملاحظات'),
            ],
            active: tab,
            onChanged: (i) => setState(() => tab = i),
          ),
          const SizedBox(height: 26),
          Text(
            tr(
              'Steps — the walk, numbered in the margins',
              'الخطوات — المسير مرقّم في الهوامش',
            ),
            style: body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: 10),
          DrawkitSteps(
            children: [
              Text(tr('Pick a seed', 'اختر بذرة')),
              Text(tr('Watch the strokes boil', 'شاهد الخطوط تغلي')),
              Text(tr('Ship the sketch', 'أطلق الرسمة')),
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
          Text(
            tr(
              'A crowd — discs overlap, the overflow confesses',
              'حشد — أقراص متراكبة، والزائد يعترف',
            ),
            style: body,
          ),
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
            caption: tr(
              'fig 1 — the idle pen, mid-spiral',
              'شكل 1 — القلم العاطل، في منتصف الحلزون',
            ),
            child: const Center(
              child: DrawkitDoodle(kind: DrawkitDoodleKind.spiral, size: 72),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Doodles — decorative, silent, never interactive',
              'الخربشات — زخرفية صامتة غير تفاعلية',
            ),
            style: body,
          ),
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
          Text(
            tr('A ticker — hover to pause it', 'الشريط — مرّر للإيقاف المؤقت'),
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitMarquee(
            child: Text(
              tr(
                'all work and no play makes the pen a dull tool',
                'كل العمل بلا لعب يجعل القلم أداة بليدة',
              ),
              style: body,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'An arrow — a line from one point to another',
              'السهم — خط من نقطة إلى أخرى',
            ),
            style: body,
          ),
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
                    child: DrawkitButton(
                      onPressed: _noop,
                      child: Text(tr('from', 'من')),
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
                    child: DrawkitButton(
                      onPressed: _noop,
                      child: Text(tr('to', 'إلى')),
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
  String _last = tr(
    'nothing yet — pressing a key would be a start',
    'لا شيء بعد — ضغطة مفتاح بداية',
  );

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
              tr('A page within the page', 'صفحة داخل الصفحة'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: palette.ink,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                'Escape folds it away; Tab never wanders outside; focus returns to the button that opened it.',
                'Escape يطويها؛ وTab لا يشرد خارجها؛ ويعود التركيز إلى الزر الذي فتحها.',
              ),
              style: body,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DrawkitButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _say(
                      tr(
                        'dialog closed — the trigger holds focus again',
                        'أُغلق الحوار — والمُشغّل يمسك التركيز مجدداً',
                      ),
                    );
                  },
                  child: Text(tr('close', 'أغلق')),
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
          DrawkitHeading(
            text: tr('The Focus Kit', 'طقم التركيز'),
            underline: true,
          ),
          const SizedBox(height: 8),
          DrawkitHeading(
            text: tr(
              'one ring, drawn only while the keyboard is at work',
              'حلقة واحدة تُرسم فقط حين يعمل لوح المفاتيح',
            ),
            level: 3,
            textStyle: TextStyle(color: palette.inkMuted),
          ),
          const SizedBox(height: 12),
          Text(
            tr(
              'Tab to walk the page · arrows to move · Home/End to jump · Enter/Space to choose · Escape to close',
              'Tab يمشي في الصفحة · الأسهم للتنقل · Home/End للقفز · Enter/Space للاختيار · Escape للإغلاق',
            ),
            style: hint,
          ),
          SizedBox(height: 20),
          Text(
            tr(
              'Slider — Home, End, PageUp and PageDown; RTL mirrors the arrows',
              'المنزلق — Home وEnd وPageUp وPageDown؛ وفي RTL تنعكس الأسهم',
            ),
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitSlider(
            value: _inkLevel,
            onChanged: (v) => setState(() {
              _inkLevel = v;
              _last = tr(
                'ink level ${(v * 100).round()}%',
                'مستوى الحبر ${(v * 100).round()}%',
              );
            }),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Segments and tabs — the selection owns the single tab stop',
              'المقاطع والتبويبات — الاختيار يملك موقف Tab الوحيد',
            ),
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitSegmentedButton<String>(
            segments: [
              DrawkitSegment(value: 'pen', label: ar('pen')),
              DrawkitSegment(value: 'pencil', label: ar('pencil')),
              DrawkitSegment(value: 'brush', label: ar('brush')),
            ],
            selected: _segment,
            onChanged: (v) => setState(() {
              _segment = v;
              _last = tr('drawing with the $v', 'الرسم بـ${ar(v)}');
            }),
          ),
          SizedBox(height: 12),
          DrawkitTabs(
            labels: [
              tr('Sketch', 'رسم'),
              tr('Ink', 'حبر'),
              tr('Export', 'تصدير'),
            ],
            active: _tab,
            onChanged: (i) => setState(() {
              _tab = i;
              _last =
                  '${tr('tab: ', 'تبويب: ')}${[tr('Sketch', 'رسم'), tr('Ink', 'حبر'), tr('Export', 'تصدير')][i]}';
            }),
          ),
          SizedBox(height: 10),
          Text(
            [
              tr(
                'a rough start, all construction lines',
                'بداية خشنة، كلها خطوط بناء',
              ),
              'the damp layer, still catching light',
              'a clean file, corners folded shut',
            ][_tab],
            style: hint,
          ),
          SizedBox(height: 22),
          Text(
            tr(
              'Accordion — Up/Down walk the headers, Enter folds a section',
              'الأكورديون — Up/Down يمشيان بين الرؤوس، وEnter يطوي قسماً',
            ),
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitAccordion(
            sections: [
              DrawkitAccordionSection(
                title: tr('What takes focus', 'ما الذي يأخذ التركيز'),
                child: Text(
                  tr(
                    'Anything with a story to tell the keyboard — buttons, fields, rows, days, crumbs.',
                    'أي شيء له حكاية يرويها للوحة المفاتيح — أزرار وحقول وصفوف وأيام وفتات.',
                  ),
                  style: hint,
                ),
              ),
              DrawkitAccordionSection(
                title: tr('Where the ring comes from', 'من أين تأتي الحلقة'),
                child: Text(
                  tr(
                    'one helper inks the dashed holder around every control.',
                    'مساعد واحد يرسم الحاضنة المتقطعة حول كل عنصر.',
                  ),
                  style: hint,
                ),
              ),
            ],
          ),
          SizedBox(height: 22),
          Text(
            tr(
              'Select and menu — arrows walk, Escape hands focus back',
              'القائمة والمنسدلة — الأسهم تمشي وEscape يعيد التركيز',
            ),
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
                  options: [
                    DrawkitSelectOption(value: 'ink', label: tr('Ink', 'حبر')),
                    DrawkitSelectOption(
                      value: 'wash',
                      label: tr('Wash', 'غسلة'),
                    ),
                    DrawkitSelectOption(
                      value: 'gouache',
                      label: tr('Gouache', 'غواش'),
                    ),
                  ],
                  value: _pick,
                  onChanged: (v) => setState(() {
                    _pick = v;
                    _last = tr('medium: $v', 'الوسط: ${ar(v)}');
                  }),
                ),
              ),
              DrawkitMenu(
                semanticLabel: tr('focus menu', 'قائمة التركيز'),
                items: [
                  DrawkitMenuItem(
                    label: tr('Sharpen the HB', 'اسنن HB'),
                    onSelected: () =>
                        _say(tr('the HB is sharp again', 'HB حادّ من جديد')),
                  ),
                  DrawkitMenuItem(
                    label: tr('Refill the well', 'أعد ملء المحبرة'),
                    onSelected: () =>
                        _say(tr('the well is full', 'المحبرة ممتلئة')),
                  ),
                  const DrawkitMenuItem.divider(),
                  DrawkitMenuItem(
                    label: tr('Fold the page', 'اطوِ الصفحة'),
                    enabled: false,
                  ),
                ],
                child: Text(tr('maintenance', 'صيانة'), style: body),
              ),
            ],
          ),
          SizedBox(height: 22),
          Text(
            tr(
              'Date picker — arrows walk days, PageUp/Down change months',
              'منتقي التاريخ — الأسهم تمشي الأيام، وPageUp/Down يبدّلان الشهر',
            ),
            style: body,
          ),
          SizedBox(height: 8),
          DrawkitDatePicker(
            value: _date,
            today: DateTime(2026, 6, 15),
            monthNames: monthNames,
            weekdayLabels: weekdayLabels,
            onChanged: (d) => setState(() {
              _date = d;
              _last = tr(
                'dated ${d.year}-${d.month}-${d.day}',
                'بتاريخ ${d.year}-${d.month}-${d.day}',
              );
            }),
          ),
          SizedBox(height: 22),
          Text(
            tr(
              'Breadcrumb and nav rail — plain Tab stops, Enter to choose',
              'الفتات ومسار التنقل — مواقف Tab عادية وEnter للاختيار',
            ),
            style: body,
          ),
          SizedBox(height: 10),
          DrawkitBreadcrumb(
            items: [
              DrawkitBreadcrumbItem(
                label: tr('kit', 'الطقم'),
                onTap: () => _say(tr('back to the kit', 'عودة إلى الطقم')),
              ),
              DrawkitBreadcrumbItem(
                label: tr('focus', 'التركيز'),
                onTap: () => _say(
                  tr('still on the focus page', 'ما زلنا في صفحة التركيز'),
                ),
              ),
              DrawkitBreadcrumbItem(label: tr('here', 'هنا')),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 170,
            width: 150,
            child: DrawkitNavRail(
              destinations: [
                DrawkitNavDestination(label: tr('Sketches', 'رسوم')),
                DrawkitNavDestination(label: tr('Swatches', 'عينات')),
                DrawkitNavDestination(label: tr('Filed', 'مؤرشف')),
              ],
              selected: _nav,
              onChanged: (i) => setState(() {
                _nav = i;
                _last =
                    '${tr('rail: ', 'المسار: ')}${[tr('Sketches', 'رسوم'), tr('Swatches', 'عينات'), tr('Filed', 'مؤرشف')][i]}';
              }),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            tr(
              'Dialog — Escape dismisses, Tab stays inside, focus comes home',
              'الحوار — Escape يغلق وTab يبقى بالداخل والتركيز يعود',
            ),
            style: body,
          ),
          const SizedBox(height: 8),
          DrawkitButton(
            onPressed: () => _openDialog(),
            child: Text(tr('Open a dialog', 'افتح حواراً')),
          ),
          SizedBox(height: 16),
          Text('${tr('last action: ', 'آخر فعل: ')}$_last', style: hint),
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
    children: [
      _PalettePanel(
        name: tr('paper light', 'ورق فاتح'),
        palette: DrawkitPalette.light,
      ),
      _PalettePanel(
        name: tr('ink dark', 'حبر داكن'),
        palette: DrawkitPalette.dark,
      ),
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
                _Swatch(
                  name: ar('pen'),
                  color: palette.pen,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: ar('ink'),
                  color: palette.ink,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: tr('muted', 'خافت'),
                  color: palette.inkMuted,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: tr('faint', 'أخفت'),
                  color: palette.inkFaint,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: tr('error', 'خطأ'),
                  color: palette.error,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: tr('success', 'نجاح'),
                  color: palette.success,
                  paper: palette.paper,
                ),
                _Swatch(
                  name: tr('neutral', 'محايد'),
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
                DrawkitButton(
                  onPressed: () {},
                  child: Text(tr('outline', 'محدد')),
                ),
                DrawkitButton(
                  variant: DrawkitButtonVariant.solid,
                  onPressed: () {},
                  child: Text(tr('solid', 'مصمت')),
                ),
                DrawkitButton(
                  tone: DrawkitTone.danger,
                  onPressed: () {},
                  child: Text(tr('danger', 'خطر')),
                ),
                DrawkitCheckbox(
                  value: true,
                  semanticLabel: tr('sample checkbox', 'مربع عينة'),
                  onChanged: null,
                ),
                DrawkitToggle(
                  value: true,
                  semanticLabel: tr('sample toggle', 'مفتاح عينة'),
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            DrawkitInput(
              placeholder: tr('placeholder ink', 'حبر العنصر النائب'),
            ),
            const SizedBox(height: 10),
            Text(
              tr(
                'tone text darkens (or lightens) until it clears 4.5:1',
                'نص اللون يغمق (أو يفتح) حتى يتجاوز 4.5:1',
              ),
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
          '${ar(name)} ${ratio.toStringAsFixed(1)}:1',
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

# drawkit

Animated hand-drawn UI for Flutter. Real widgets on top, seeded pen strokes
behind, one shared boil clock — a Dart port of [drawably](https://github.com/dwhitedeveloper/drawably)
with **zero dependencies beyond the Flutter SDK** (no Material, no Cupertino).

```dart
import 'package:drawkit/drawkit.dart';

DrawkitButton(
  onPressed: () => save(),
  child: const Text('save'),
)
```

## How it works

- **The widget does the work, the pen is decoration.** Text fields are real
  `EditableText`s, the select is a real `RawMenuAnchor` menu, checkboxes are
  real focus/semantics-visible toggles. The sketch layer sits behind them and
  never participates in hit testing.
- **One seed, one sketch.** All randomness goes through a bit-exact port of
  the JS `mulberry32`; the same seed draws the same lines, down to the last
  wobble. Golden vectors from the original engine live in
  `test/fixtures/js_vectors.json`.
- **Boil, not frame loops.** Three pre-generated stroke frames swap on a
  shared 1200 ms clock (`variants(seed + i * 7919)`), the Dart equivalent of
  the CSS `step-end` keyframes. Controls with several animated pieces (a
  checkbox outline, its check, its focus ring) share one clock, so frames
  can never sample out of step.
- **Accents, not rebuilds.** Draw-on checks (`trimTo`) and the radio dot /
  toggle knob (`matrix`) are applied at paint time from live animations —
  frames stay cached.
- **Reduced motion respected.** `MediaQuery.disableAnimations` and
  `PlatformDispatcher.accessibilityFeatures.reduceMotion` freeze the boil on
  frame 0 and skip pointer re-sketches.
- **RTL follows the ambient `Directionality`.** Directional geometry
  (`start`/`end`) throughout, and painted anchors re-place themselves: the
  select chevron and menu edge, list gutters and markers, the toggle's
  resting side. LTR drawings are unchanged, stroke for stroke — the gallery
  sidebar has an RTL switch to compare.

## Widgets

| Group | Widgets |
| --- | --- |
| Controls | `DrawkitButton`, `DrawkitCheckbox`, `DrawkitRadio`, `DrawkitToggle`, `DrawkitInput`, `DrawkitTextarea`, `DrawkitSelect` |
| Surfaces | `DrawkitDivider`, `DrawkitCard`, `DrawkitBadge`, `DrawkitList` |
| Text | `DrawkitUnderline`, `DrawkitHighlight`, `DrawkitCircle` |
| Composites | `DrawkitArrow`, `DrawkitChip`, `DrawkitTabs`, `DrawkitTooltip`, `DrawkitAlert`, `DrawkitSteps`, `DrawkitKbd`, `DrawkitQuote`, `DrawkitPager` |
| Actions | `DrawkitSegmentedButton`, `DrawkitSlider`, `DrawkitStepper`, `DrawkitSearchField`, `DrawkitIconButton`, `DrawkitFab` |
| Motion | `DrawkitSketchIn`, `DrawkitStagger`, `DrawkitShake` |

Theming runs through `DrawkitTheme` + `DrawkitStyle` (`seed`, `roughness`,
`boil`, `strokeColor`, `fillColor`, `width`, `ink`); brand defaults match the
CSS custom properties.

The optional **DrawkitPen** typeface ships with the package — nothing loads it
unless a style asks for `fontFamily: 'DrawkitPen'`.

## Try it

```sh
cd example
flutter run -d chrome
```

The gallery exercises every widget: hover, press, focus (Tab), disabled
states, and the live knobs for roughness / boil / seed.

## Development

```sh
dart analyze
flutter test
(cd example && flutter test && flutter build web)
```

`flutter analyze` currently crashes on this checkout because the project path
contains non-ASCII characters (LSP JSON error); use `dart analyze`, which is
what CI runs too on ASCII paths.

## License

MIT. Ported from drawably (MIT) — see LICENSE for the full attribution note.

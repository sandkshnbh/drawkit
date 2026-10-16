## Unreleased

- **Motion** — `DrawkitSketchIn` traces every surface below it on mount (a
  `DrawkitSketchScope` carries the progress; surfaces trim at paint time, no
  per-tick rebuilds), `DrawkitStagger` draws a list in one clock, a step
  apart, and `DrawkitShake` / `DrawkitShakeController` play the damped
  "wrong!" wiggle. All three honor reduced motion. `drawkitEase` and
  `drawkitReduceMotion` moved to `style.dart` (same public API).
- **RTL** — every widget follows the ambient `Directionality`: layout uses
  directional geometry (`EdgeInsetsDirectional`), and painted anchors flip
  with it — the select chevron and menu alignment, the list gutter and
  markers, the toggle's resting side and travel, chip/tabs/pager spacing.
  LTR output is unchanged, stroke for stroke.
- **Fixed** — `DrawkitQuote`'s footer rule drew through the attribution text;
  it now rules the top of a 10px footer band spanning the quote's width, with
  the text starting 8px in (the `drawablyDivider` contract). The gallery's
  tooltip and arrow demos mirror in RTL (`PositionedDirectional`).
- **Fixed** — text decorations (`DrawkitUnderline`, `DrawkitHighlight`,
  `DrawkitCircle`) keep the `TextPainter`'s width, so the strokes stay aligned
  with the glyphs when the constraint is wider (single-line text shifted in
  RTL); `DrawkitKbd` keeps keycap glyph order LTR inside RTL paragraphs.
- **Fixed** — `DrawkitArrow` (and the tooltip's arrow) drew with stale
  measurements on the first frames: a repaint alone reused the frames cached
  for the surface's size, so the arrow only appeared after the next rebuild
  (any tap). The anchor poll now rebuilds, and arrows show as soon as the
  anchors land.

## 0.1.0

First release: the complete drawably port.

- **Engine** — `mulberry32` PRNG (bit-exact with the JS reference) and the full
  rough geometry: sampled lines, ellipses, rounded rects, checkmarks, scribble
  fills, double strokes, arrows, and the `variants` frame generator. Verified
  against golden vectors generated from the JS source (`test/fixtures/`).
- **Core** — `DrawkitSurface` (seeded chrome behind any child, one shared boil
  clock, pre-built frames, trim/matrix accent layers), `DrawkitStyle` /
  `DrawkitTheme`, `drawkitStroke` / `drawkitFillPaint`,
  `drawkitReduceMotion`.
- **Controls** — `DrawkitButton`, `DrawkitCheckbox`, `DrawkitRadio`,
  `DrawkitToggle`, `DrawkitInput`, `DrawkitTextarea`, `DrawkitSelect`.
- **Surfaces** — `DrawkitDivider`, `DrawkitCard`, `DrawkitBadge`,
  `DrawkitList`.
- **Text** — `DrawkitUnderline`, `DrawkitHighlight`, `DrawkitCircle`
  (per-line-box via `TextPainter`).
- **Composites** — `DrawkitArrow`, `DrawkitChip`, `DrawkitTabs`,
  `DrawkitTooltip`, `DrawkitAlert`, `DrawkitSteps`, `DrawkitKbd`,
  `DrawkitQuote`, `DrawkitPager`.
- **Typeface** — opt-in `DrawkitPen` family.
- **Gallery** — a web example app exercising every widget.

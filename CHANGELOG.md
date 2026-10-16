## Unreleased

- **RTL** — every widget follows the ambient `Directionality`: layout uses
  directional geometry (`EdgeInsetsDirectional`), and painted anchors flip
  with it — the select chevron and menu alignment, the list gutter and
  markers, the toggle's resting side and travel, chip/tabs/pager spacing.
  LTR output is unchanged, stroke for stroke.
- **Fixed** — `DrawkitQuote`'s footer rule drew through the attribution text;
  it now rules the top of a 10px footer band spanning the quote's width, with
  the text starting 8px in (the `drawablyDivider` contract). The gallery's
  tooltip and arrow demos mirror in RTL (`PositionedDirectional`).

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

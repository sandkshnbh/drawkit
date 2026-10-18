## Unreleased

- **Audit fixes (P1)** — the parity and polish half of the AUDIT.md sweep.
  Semantics grew roles wherever the engine can hear them: `tab`/`tabBar`
  on the segments and tabs, `table`/`row`/`cell`/`columnHeader` on the
  table, and a strictly gated `progressBar` (value plus min/max) on the
  determinate bar. The command palette reworked: `DrawkitCommand` carries
  `leading`, `group`, and `enabled`; groups draw headers, disabled rows
  are skipped by the roving highlight and refused on Enter, the list
  scroll-reveals the highlight, a repeated invoke no longer pops twice,
  and `showDrawkitCommandPalette` gained `filterCallback` and
  `initialSelection`. `DrawkitDialog` stopped double-announcing (route
  semantics are opt-in via `routeSemantics`/`semanticLabel`), paints its
  scrim from the resolved palette, and `showDrawkitDialog` grew
  `barrierLabel`, `requestFocus`, `useRootNavigator`, `routeSettings`,
  `transitionDuration`, `anchorPoint`, and `fullscreenDialog`.
  `DrawkitSheet` is a stateful draggable now — the handle follows the
  finger on a widened strip, a fling or a 30% drag dismisses, otherwise
  it settles back — meets the dialog's parity set plus `enableDrag`,
  `isScrollControlled`, and `maxHeightFactor`, and yields to the
  keyboard via `viewInsets`. The date picker gained
  `selectableDayPredicate`, `onDisplayedMonthChanged`, `headerText`/
  `footerText`, and a typed `DrawkitDatePickerMode.input` entry with
  date parsing and announced errors, all threaded through its show
  function. `DrawkitHighlight` skips its repaint boundary so blend modes
  multiply through the real backdrop, `DrawkitButton` announced-loading
  text is overridable, the toasts expose `plainLinger`/`actionLinger`,
  and the sketch-in, stagger, and shake animations retune live from
  their widgets instead of latching, while reduced motion short-circuits
  every one of them. The engine stays total: `ellipsePoints` and
  `variants` survive non-positive counts. Tests hardened to prove the fixes: the
  gallery guidelines now walk RTL and dark pages at a 1.2 text scaler
  and smoke the dialog and toast under reduced motion, the example
  exercises sidebar selection and the RTL/dark toggles, a pixel test
  proves boil frames genuinely repaint, the palette and nav keyboard
  suites pin roving focus and disabled skipping, and
  `test/audit_fixes_test.dart` covers the badge clamp, popover mirroring
  and flipping, grab-handle gesture math, dialog focus restoration, the
  date picker predicate and typed entry, and reduced-motion standstills.
  278 tests.

- **Audit fixes (P0)** — the correctness half of the AUDIT.md sweep.
  Overlaid routes were mounting outside the kit's scope: the dialog, sheet,
  toast, and command palette now wrap their `pageBuilder` in a
  `DrawkitTheme` plus a route-level `DefaultTextStyle`
  (`drawkitRouteTextStyle`) that carries the readable ink, and
  `showDrawkitDialog` grew `maxWidth`/`padding` (the command palette
  dropped its second, nested copy of the frame). The date picker's month
  paging walks the keyboard cursor into the target month (day clamped),
  the menu tracks its anchor from the controller's info and scrolls long
  item lists instead of overflowing, the rating's taps and paint mirror
  together under RTL, the segmented focus ring lands on the visual
  first/last segment, and the floating bar, when hidden, ignores
  pointers, focus, and semantics. `DrawkitNavBar`'s badge stays a circle
  at any label length and its height scales with the text scaler,
  `DrawkitInput` hands focus back when it turns read-only, the
  breadcrumb's whole tap target is live, the FAB label inks with the pen,
  and `DrawkitSlider` asserts sane bounds. The disabled-mid-press reset
  defers a frame so sibling buttons rebuild safely; `DrawkitStagger`
  recomputes its schedule when the child count or duration changes; the
  refresh indicator swallows `onRefresh` errors; the marquee no longer
  announces its clone; the doodle clamps its stroke width; table and
  decoration surfaces survive unbounded intrinsics; and the engine guards
  empty `smooth`, degenerate `roughEllipse`, and zero-step `sampleLine`.
  Eight tests that could not fail were rewritten into real checks, and
  `test/audit_fixes_test.dart` pins the regressions. 262 tests.

- **Gallery reorganization** — the demo app is grouped by function now
  (Foundations, Actions, Forms, Navigation, Overlays, Feedback, Display) with
  uppercase section headers in the sidebar, and every page collects its whole
  family: Buttons absorbs the icon-button, fab, and fab-menu demos, Fields
  gains the search field, Choices gains chips and segments, Select & Dates
  gains the date picker, the new Values page holds the slider, stepper, and
  rating, Navigation absorbs the floating-capsule demos and gains the pager,
  the new Tabs & Steps page takes tabs and steps, Menus & Popovers gains the
  tooltip, the new Dialogs & Sheets page takes the modals, sheets, and
  toasts, Feedback & States absorbs validation, the empty state, undo, and
  pull-to-refresh, and Cards & Tables / Type & Ink / Pictures & Extras round
  out the display set. 17 gallery pages; no library changes.

- **Floating navigation** — `DrawkitFloatingNavBar` floats a paper capsule
  above the content (directional margin + bottom safe area) with the picked
  destination wearing a soft ink blob. Two label moods: `showLabels: true`
  keeps every label beside its glyph, `false` lets only the pick open into
  a label (flexible, `AnimatedSize`). `hideOnScroll` plus a
  `ScrollController` tuck the bar below the fold while the list moves down
  and slide it back on the first upward flick (reduced motion snaps).
  `DrawkitNavDestination` grew a `badge` count — a small error-ink disc on
  the icon's corner, folded into the announced label ("Inbox, 3
  notifications") and drawn by the new `DrawkitNavBadge` in the floating
  bar, the rail, and the bottom bar alike. `DrawkitFabMenu` is the
  speed-dial sibling of `DrawkitFab`: labelled pills unfold above the
  circle (nearest action leads the stagger), the face turns 45°, Escape
  and outside taps fold it back, and focus walks from the top pill into
  the trigger. The gallery shipped the floating demos (both label moods, a
  scroll-aware list, and the speed dial). 249 tests.

- **Internal cleanup** — the keyboard intents the focusable controls share
  moved into `src/core/intents.dart` (one definition instead of fifteen
  private copies per widget), the popup panels (`DrawkitMenu`,
  `DrawkitPopover`, `DrawkitSelect`) share their positioner, check painter,
  and row widget through `src/widgets/drawkit_panel.dart`,
  `drawkitReduceMotion` lives in `core/motion.dart` (was `style.dart`), and
  `DrawkitTone` lives in `core/style.dart` (was `drawkit_button.dart`). No
  API or pixel changes.

- **Themes & Dark Mode** — `DrawkitPalette` is a value type with two presets
  now: `DrawkitPalette.light` (the CSS values, untouched) and
  `DrawkitPalette.dark` (night paper `#1D1E21`, indigo pen `#8B88FF`).
  `DrawkitStyle` carries a `palette` field and every widget resolves ink,
  tone, paper, and chrome through it, so
  `DrawkitTheme(data: DrawkitPalette.dark.style, child: …)` re-inks the
  whole kit — text, strokes, popovers, dialogs, the command palette.
  `drawkitReadableInk` is direction-aware: it darkens toward black on light
  backgrounds and lightens toward white on dark ones (default background:
  the light paper). The gallery gained an "Ink · Palette" page (both papers
  side by side with live contrast ratios), the sidebar grew a dark toggle,
  `test/dark_test.dart` locks the presets, the direction rule, and the dark
  control sample against all four accessibility guidelines, and the gallery
  audit now runs every page twice — light and dark. Breaking:
  `DrawkitPalette.pen` and friends are instance fields now —
  `DrawkitPalette.light.pen` reads the old value.

- **Accessibility** — every control now answers the accessibility guidelines:
  a shared `DrawkitTapTarget` (`drawkitMinTapTarget` = 48) wraps the drawings
  inside their gesture layers, so touch boxes reach 48×48 (iOS 44 included)
  while the sketch keeps its size; `DrawkitButton`, `DrawkitIconButton`,
  `DrawkitFab`, checkbox, radio, toggle, chip, segments, tabs, slider,
  stepper, pager, breadcrumb, nav tiles, menu rows, select rows, popover
  triggers, accordion headers, and date-picker cells (48px grid) all pass
  `androidTapTargetGuideline` and `iOSTapTargetGuideline`. Gesture detectors
  are excluded from semantics and every tappable node carries an explicit
  `onTap` plus a label (`labeledTapTargetGuideline` clean). Text follows
  WCAG contrast on the paper: solid buttons now ink their label in the paper
  color (the drawn fill stays the tone), tone/state buttons pass their label
  through `drawkitReadableInk` (darkened until 4.5:1 while the stroke keeps
  the brand tone), placeholders and hints moved from `inkFaint` to
  `inkMuted`, disabled fields announce `enabled: false`, and
  `drawkitContrast` is exported for checks. `test/a11y_test.dart` locks the
  four guidelines over a broad control sample plus a 2× text-scale pass, and
  `example/test/a11y_gallery_test.dart` audits every gallery page.
- **Focus & Keyboard** — one shared ring for every control:
  `drawkitFocusRingRect` and `drawkitFocusRingCircle` are exported helpers,
  and the existing rings (button, icon button, checkbox, radio, toggle,
  select, slider) all come from them now. `DrawkitSlider` answers Home/End
  (the ends) and PageUp/PageDown (five steps), and horizontal arrows follow
  the reading direction (RTL included, like Flutter sliders).
  `DrawkitSegmentedButton` and `DrawkitTabs` keep a roving tab stop — the
  selection is the only stop, arrows move (and activate) with wrap-around,
  plus Home/End. `DrawkitBreadcrumb`, `DrawkitNavRail` / `DrawkitBottomNav`,
  `DrawkitChip` and `DrawkitPager` activate from the keyboard, and
  `DrawkitAccordion` headers answer Up/Down/Home/End. `DrawkitMenu` and
  `DrawkitSelect` walk rows with arrows (wrapping, skipping disabled rows),
  answer Home/End, and hand focus back to the trigger or field on close; the
  command palette gained Home/End. `DrawkitDatePicker` is a single tab stop:
  arrows walk days and weeks (RTL aware), PageUp/PageDown page months keeping
  the day, Home/End jump to the month's edges, Enter picks. Dialog and sheet
  Escape, Tab trap, and focus return are pinned down by tests.
- **States** — `DrawkitInput` / `DrawkitTextarea` gained `error` and `helper`:
  an error inks the outline and cursor red, replaces the helper below the
  field, and announces itself through a live region. `DrawkitEmpty` (faint
  doodle, header title, quiet message, optional action) for the blank-margin
  case. Toasts learned actions: `DrawkitToastAction` (Undo/Retry) underlines a
  verb in the pill re-inked on hover/focus, keyboard- and tap-activatable;
  running it closes the toast, action toasts linger 5s by default, and only
  actionless toasts keep letting taps pass through. `DrawkitRefresh` pulls to
  refresh without Material: a rotating arrow doodle follows the drag, hands
  off to the spinner while the future settles, works with clamping and
  bouncing physics, and is reduced-motion aware.
- **Fixed** — text decorations (`DrawkitUnderline`, `DrawkitHighlight`,
  `DrawkitCircle`, the quote) no longer swallow a bounded height: the
  alignment box is shrink-wrapped vertically (`heightFactor: 1`), so a
  decoration inside a row or card draws around its line box instead of
  inflating to the available space (a toast action used to stretch its pill
  to the full height).
- **Content** — `DrawkitHeading` (three display sizes, optional pen rule),
  `DrawkitAvatar` + `DrawkitAvatarGroup` (drawn discs, overlapping stack with
  a `+n` overflow pocket), `DrawkitFigure` (framed child with a muted plate
  caption), `DrawkitRating` (inked stars, tap-to-set / tap-again-to-clear,
  slider semantics with increase/decrease), `DrawkitDoodle` (star, squiggle,
  spiral, burst, arrow — decorative and excluded from semantics) and
  `DrawkitMarquee` (seamless ticker flowing start→end, pause on hover,
  reduced-motion aware).
- **Structure** — `DrawkitAppBar` (leading/title/actions over a paper surface
  with the heavier shelf rule, announces itself as a header),
  `DrawkitNavRail` + `DrawkitBottomNav` (shared `DrawkitNavDestination`;
  the chosen tile wears a scribble wash and redraws on pick),
  `DrawkitBreadcrumb` (pen underlines on tappable crumbs, bold current page,
  muted separators) and `DrawkitTable` (flex-weighted columns, bold header
  rule, faint row rules). Every piece is direction-aware.
- **Menus** — `DrawkitMenu` (dropdown on a real anchor; paper panel with
  checked/hint rows and ruled dividers), `DrawkitPopover` (any trigger, any
  panel; width follows the anchor), `DrawkitAccordion` (headers on a sketch
  line, `AnimatedSize` bodies, single- or multi-open), `DrawkitCommandPalette`
  via `showDrawkitCommandPalette` (filter + arrow/enter/escape keys), and
  `DrawkitDatePicker` + `showDrawkitDatePicker` (Monday-first grid, selected
  ring, today dot, localizable month/weekday names). Panels join the anchor's
  `TapRegion` group: an outside tap folds them away, row taps stay intact.
  `DrawkitSelect` gained the same outside-tap dismissal.
- **Feedback** — `showDrawkitDialog` / `showDrawkitSheet` (paper panels over a
  soft scrim; the modal traces itself in via `DrawkitSketchIn`, the sheet
  slides in from the bottom or the direction-aware end edge, and its grab
  handle flings closed), `showDrawkitToast` (tap-through overlay pill with
  tone ink and auto-dismiss), `DrawkitProgressBar` (leading-edge fill,
  sweeping indeterminate band), `DrawkitSpinner` (dashed ring on one clock),
  and `DrawkitSkeleton` + `DrawkitSkeleton.circle` (faint strokes with a
  per-line shimmer sweep). All reduced-motion aware.
- **Actions** — `DrawkitSegmentedButton` (rough frame, scribbled wash under
  the pick), `DrawkitSlider` (tap/drag/keyboard, division snapping, fill from
  the leading edge), `DrawkitStepper` (boundary-aware − / +), `DrawkitSearchField`
  (pen magnifier in the leading gutter, × clears and reports `''`), plus
  `DrawkitIconButton` and `DrawkitFab` in `drawkit_button.dart`. All follow
  `Directionality` and reuse the existing surface conventions.
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

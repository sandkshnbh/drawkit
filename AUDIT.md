# drawkit — full widget & codebase audit

- Revision audited: `6b74cf0` (M25 gallery reorganization), working tree clean.
- Scope: 39 widgets in `lib/src/widgets/` (~9.8k LOC), 5 core files, 2 engine files, the gallery (`example/lib/main.dart`), 22 test files in `test/`, `example/test/`, docs (README/CHANGELOG/SKILL).
- Method: six read-only exploration passes (controls & inputs, overlays & routing, navigation & structure, display & feedback, engine & core, tests & gallery) plus targeted re-verification of every P0 claim by re-reading the cited source, plus web research (rough.js, wired-elements, rough_notation, Material 3 Expressive, Flutter catalog, WCAG 2.2).
- Status: findings only — no fixes applied. Every bullet cites `path:line`.
- Legend: **P0** = wrong behavior/crash/invisible content → **P1** = accessibility/keyboard/RTL/reduced-motion/API gaps → **P2** = polish and API additions. `[V]` marks claims re-verified by direct source read during this audit pass.

## Summary

| Severity | Approx. count | Themes |
| --- | --- | --- |
| P0 | 39 (31 code + 8 test) | overlay text style inheritance, double dialog frames, theme resolved in route context, stale date-picker cursor, NaN/empty-input crashes in engine, stale cached state (Stagger, surface pressed flags), RTL tap/paint mismatches, invisible FAB glyph, duplicate marquee child, 8 tests that cannot fail |
| P1 | 83 | missing semantics roles/labels, keyboard traps and roving focus gaps, RTL mirroring, reduced-motion latches, API parity vs Flutter equivalents, gallery captions contradicting code |
| P2 | 43 | API additions, test-suite organization, seed/repaint hygiene, doc inconsistencies |

Recurring root causes worth fixing structurally:

1. `late final` / `_started` one-shot caching that ignores `didUpdateWidget` and runtime accessibility changes (motion.dart, progress.dart, skeleton.dart, composites.dart).
2. Seeds resolved with `randomSeed()` inside `build` (chip, tabs, alert, quote, pager, tooltip) — any rebuild re-sketches.
3. Overlay routes that build outside `Material`, inheriting the error text style and resolving `DrawkitTheme` from the wrong context.
4. Engine entry points with no degenerate-input guards (empty lists, zero radii, zero steps, zero divisions).

---

## P0 — bugs

### Overlays, routing & theming

- `lib/src/widgets/drawkit_toast.dart:125` — toast/dialog content built via `OverlayEntry` outside any Material: unstyled `Text` inherits MaterialApp's `_errorTextStyle` (48px monospace, yellow double underline). Same exposure at `drawkit_command.dart:177`, `:274`, `drawkit_date_picker.dart:201`, `:336`, and any unstyled text in `showDrawkitDialog`/`showDrawkitSheet` content. Fix: wrap each route subtree in a `DefaultTextStyle` (14px, `decoration: none`, palette ink). [V]
- `lib/src/widgets/drawkit_command.dart:167` — `_CommandPalette` builds its own `DrawkitDialog` while `showDrawkitDialog` (`drawkit_dialog.dart:109`) already wraps the child in one: two paper frames, duplicated route-scope semantics, caller `width: 460` silently capped by the outer 420 default. Fix: one owner of the frame. [V]
- `lib/src/widgets/drawkit_date_picker.dart:430` — `showDrawkitDatePicker` nests a second `DrawkitDialog` inside the `showDrawkitDialog` wrapper; doubled frame/padding/semantics on every picker. Fix: drop the inner frame, thread `padding`/width through. [V]
- `lib/src/widgets/drawkit_menu.dart:384` — panel positioned from the `_anchorRect` captured in `_toggle` (`:338`) instead of the live `info.anchorRect`: stale on window resize, IME insets, sibling reflow (popover too, `:142`). Fix: use the live anchor rect in the position delegate.
- `lib/src/widgets/drawkit_menu.dart:428` — panel content is a plain `Column` under the fixed `maxHeight: 320` (`drawkit_panel.dart:31`) with no scroll view: 7+ rows or a tall popover child hits a RenderFlex overflow. Fix: scroll view + clamp to overlay constraints.
- `lib/src/widgets/drawkit_date_picker.dart:123` — header arrows page `_month` without moving `_cursor`, so Enter/Space on the grid (`_pickCursor`, `:157`) fires with the old off-screen day (July shown → June 30 picked). Fix: move cursor into the new month, clamped by its length. [V]
- `lib/src/widgets/drawkit_dialog.dart:101` — every `show*` route resolves `DrawkitTheme` in the new route context, so the documented `MaterialApp(home: DrawkitTheme(...))` pattern yields light dialogs/sheets/palette/picker/toast (also `drawkit_command.dart:123`, `drawkit_date_picker.dart:489`, `drawkit_sheet.dart:168`). Fix: capture the caller-context style and re-wrap the route child in `DrawkitTheme`. [V]
- `lib/src/widgets/drawkit_toast.dart:310` — with reduced motion the controller is parked at 1, yet `dismiss()` still calls `_controller.reverse()`: a 220ms exit animation plays anyway under `disableAnimations`. Fix: when motion is off, call `onDismissed()` directly. [V]

### Controls & inputs

- `lib/src/widgets/drawkit_button.dart:392-428`, `:491` — `DrawkitFab` draws an outline-only disc yet wraps the default child style with `paperColor` (`:493`; `drawkit_fab_menu.dart:136` same): the glyph/label is paper-on-paper, invisible in light theme (~1:1). Fix: ink for fab content, or fill the disc. [V]
- `lib/src/widgets/drawkit_slider.dart:73-74` — `divisions: 0` divides by zero: `_snap` produces NaN through `onChanged` and the semantics value ("NaN"); no constructor assert, and `min > max` is silently coerced to `_range = 1.0` (`:71`). Fix: assert `divisions == null || divisions > 0` and `min < max`. [V]
- `lib/src/widgets/drawkit_segmented.dart:190` — RTL focus ring translates by the raw LTR index (`seg * focused`) while the `Row` mirrors children: the ring lands on the opposite segment. Fix: mirror the index (`length - 1 - focused`). [V]
- `lib/src/core/surface.dart:204` — disabling a surface mid-press/hover removes the `Listener` without emitting `onPressedChanged(false)`/`onHoverChanged(false)`: `_pressed`/`_hovered` stay true and controls reappear pressed when re-enabled (button, fab, toggle, checkbox, radio, slider). Fix: emit false when `enabled` flips false.
- `lib/src/widgets/drawkit_input.dart:304` — a disabled field only sets `readOnly`: it stays in the Tab order, is focusable/selectable, and is announced as editable. Fix: `focusNode.canRequestFocus = false` plus an explicit semantics `enabled: false`. [V]

### Navigation & structure

- `lib/src/widgets/drawkit_floating_nav.dart:115` — the hidden bar only slides/fades (`AnimatedSlide` + `AnimatedOpacity`): tiles remain hit-testable and Tab-focusable at the invisible offscreen position. Fix: `IgnorePointer` + `ExcludeFocus` when hidden. [V]
- `lib/src/widgets/drawkit_nav.dart:184` — fixed 58px bottom bar fits ~97px of icon+label content: overflows at large text scales (2×). Fix: size the bar from content or clamp the scale. [V]
- `lib/src/widgets/drawkit_nav.dart:53` — `DrawkitNavBadge` circle radius is `width / 2`: the 99+ disc is ~22px tall in a 16px box and clips. Fix: radius from `size.shortestSide / 2`.
- `lib/src/widgets/drawkit_doodle.dart:62` — widths ≤ 6px empty the squiggle point list while `smooth()` reads `points.first` (`rough.dart:129`): StateError. Fix: guard empty input in `smooth` or require size ≥ 6. [V]
- `lib/src/widgets/drawkit_table.dart:126` — `Expanded` cells throw under unbounded width parents (Row/horizontal scroll). Fix: `LayoutBuilder` fallback widths or an `IntrinsicWidth` wrapper.
- `lib/src/widgets/drawkit_decorations.dart:38` — `DrawkitDivider` child is `SizedBox(width: double.infinity)`: throws under unbounded width. Fix: bounded width handling. [V]
- `lib/src/widgets/drawkit_avatar.dart:142` — at `size == 3` the radius hits 0 and `roughEllipse` computes `0 / 0` NaN, then `NaN.ceil()` throws (`rough.dart:169-174`). Fix: skip drawing when `r <= 0` (and see the engine guard below).
- `lib/src/widgets/drawkit_breadcrumb.dart:148` — `GestureDetector` defaults to `deferToChild`, so a crumb's 48px `DrawkitTapTarget` padding never receives taps. Fix: `behavior: HitTestBehavior.opaque`.

### Display, motion & feedback

- `lib/src/widgets/drawkit_text.dart:174` — `TextPainter` built without `textScaler`: under accessibility scaling the rendered `Text` exceeds the unscaled box, and underline/highlight/circle boxes misalign or overflow. Fix: `textScaler: MediaQuery.textScalerOf(context)`. [V]
- `lib/src/widgets/drawkit_marquee.dart:90` — `widget.child` is inserted twice verbatim (clone lacks exclusions): `GlobalKey` descendants crash with duplicate keys and screen readers announce everything twice. Fix: clone semantics exclusion + document the GlobalKey ban. [V]
- `lib/src/widgets/drawkit_composites.dart:65` — chip base seed is `widget.seed ?? randomSeed()` inside `build`: hover/focus setState re-sketches the badge and its checkbox mid-interaction. Fix: cache in `State` (like `DrawkitList`). [V]
- `lib/src/widgets/drawkit_composites.dart:254` — tabs re-resolve the base seed per build: arrow-key focus changes re-sketch every label. Fix: resolve once in `initState`.
- `lib/src/widgets/drawkit_refresh.dart:110` — `_trigger()` runs unawaited: a throwing `onRefresh` escapes as an unhandled async error instead of settling the indicator. Fix: await and report via `FlutterError`.
- `lib/src/widgets/drawkit_rating.dart:41-56`, `:115-128` — stars paint at LTR positions but the `Row` mirrors hit boxes in RTL: tapping the rightmost star fills the leftmost. Fix: force the inner layout LTR or mirror the painter. [V]

### Engine & core

- `lib/src/engine/rough.dart:169-174` — `roughEllipse`/`roughCircle` with `rx + ry == 0`: `(rx - ry) / (rx + ry)` is `0 / 0` NaN, perimeter NaN, `.ceil()` throws `UnsupportedError`. Fix: guard and return an empty `Path`. [V]
- `lib/src/engine/rough.dart:129`, `:140` — exported `smooth()` dereferences `points.first`/`points.last` unguarded: empty input throws `StateError`. Fix: return `Path()` when empty. [V]
- `lib/src/engine/rough.dart:35-39` — `sampleLine` divides by `step`: step 0/NaN gives `Infinity`/NaN `n`, then `List.generate` throws. Fix: coerce non-positive/NaN steps to the 8px default. [V]
- `lib/src/core/motion.dart:129-137` — `DrawkitStagger` caches `_total` and `_progress` as `late final` from the first build: growing `children` indexes past the list (RangeError) and shrinking leaves stale intervals. Fix: rebuild both in `didUpdateWidget`. [V]

### Test files that cannot fail

- `test/surface_test.dart:148` — tautology `expect(math.max(1, 1), 1)`; the "identical pixels between runs" test compares nothing. Fix: hash real pixels/bounds between runs.
- `test/keyboard_test.dart:195` — `changed` is never incremented; `expect(changed, 0)` cannot fail. Fix: real probe callback.
- `test/actions_test.dart:48` — `taps` belongs to a null callback and is never mutated. Fix: probe and assert zero calls.
- `test/actions_test.dart:153` — `seen` can never change because `onChanged: null`; vacuous.
- `test/actions_test.dart:223` — disabled-slider test taps with no expectation at all.
- `test/actions_test.dart:70` — disabled-FAB test taps but asserts nothing.
- `test/controls_test.dart:186` — disabled-toggle test taps but never asserts.
- `test/menus_test.dart:128` — disabled Paste row has no `onSelected`, so the assertion cannot observe firing.

---

## P1 — gaps

### Semantics & accessibility

- `lib/src/widgets/drawkit_toast.dart:221` — the action's `Semantics(button)` has no `onTap` (gesture is inside `ExcludeSemantics`): screen readers expose an unactivatable button; the message is not a `liveRegion`. Fix both.
- `lib/src/widgets/drawkit_toast.dart:236`, `:125` — the action re-inks from ambient theme instead of the passed `style`, and the message sets no palette color: a styled toast renders dark-on-dark.
- `lib/src/widgets/drawkit_date_picker.dart:350` — day cells are bare `GestureDetector` + `Text`: no `button`/`selected`/`enabled` flags and no "October 5" style labels. Fix: wrap in labeled `Semantics`.
- `lib/src/widgets/drawkit_menu.dart:179` — popover trigger is `ExcludeSemantics` under `button: true` with a null default label: an unlabeled button; no `expanded` announced.
- `lib/src/widgets/drawkit_menu.dart:304` — row focus nodes are `skipTraversal: true` with no `FocusTraversalGroup`: Tab escapes the open panel into the page. Fix: trap traversal. [V]
- `lib/src/widgets/drawkit_command.dart:204` — the highlighted row is never scrolled into view: arrows beyond the 280px viewport move an invisible selection. Fix: `ensureVisible` on move.
- `lib/src/widgets/drawkit_dialog.dart:33` — `DrawkitDialog` unconditionally emits route semantics (`scopesRoute/namesRoute/"dialog"`), duplicating `RawDialogRoute`'s scope and hardcoding a non-localizable label. Fix: gate behind a flag.
- `lib/src/widgets/drawkit_toggle.dart:202` — uses `checked`, so the switch is announced as a checkbox; Flutter's `Switch` uses `toggled`. Fix: `toggled: widget.value`.
- `lib/src/widgets/drawkit_button.dart:227` — loading only flips semantics `enabled` to false with no busy label: screen readers silently lose the control. Fix: announce loading.
- `lib/src/widgets/drawkit_fab_menu.dart:237` — dial item sets `semanticLabel` while also rendering the same text: the label is announced twice. Fix: drop one (or `ExcludeSemantics` the text).
- `lib/src/widgets/drawkit_select.dart:309` — no `value`/`expanded` semantics; `onTap` stays non-null when disabled, announcing as activatable. Fix: expose state, null the tap.
- `lib/src/widgets/drawkit_segmented.dart:31` — missing `focusNode`/`autofocus`/`semanticLabel` params that every sibling control has. Fix: add shared params.
- `lib/src/widgets/drawkit_stepper.dart:55` — hardcoded `'decrease'`/`'increase'` labels; value box is not adjustable and not a live region. Fix: label params + `onIncrease`/`onDecrease`.
- `lib/src/widgets/drawkit_radio.dart:184` — Space/Enter only: arrow keys don't move selection within the group (segmented does). Fix: roving arrows with a group callback.
- `lib/src/widgets/drawkit_slider.dart:245` — tap and drag never request focus, so click-then-arrow adjusts nothing. Fix: request focus on tap/drag start.
- `lib/src/widgets/drawkit_search.dart:216` — the clear control is an 18px gesture: below the 48dp target and unreachable by Tab/keyboard. Fix: `DrawkitTapTarget` + focusable.
- `lib/src/widgets/drawkit_search.dart:222` — `'clear'` is hardcoded English with no parameter or localization hook. Fix: label parameter.
- `lib/src/widgets/drawkit_input.dart:293` — placeholder is a sibling static `Text`; `EditableText` carries no semantic label/hint: the field reads unlabeled. Fix: `Semantics` label/hint around the field.
- `lib/src/widgets/drawkit_progress.dart:166` — determinate bars expose only "40%" with no label or progress-bar role; indeterminate ones expose nothing. Fix: role + default label.
- `lib/src/widgets/drawkit_progress.dart:282` — spinner has no loading-spinner role or live region. Fix: add both.
- `lib/src/widgets/drawkit_composites.dart:317` — tabs expose button semantics, not tab/tabBar roles. Fix: `SemanticsRole.tab`/`tabBar`.
- `lib/src/widgets/drawkit_composites.dart:403` — tooltip card has no tooltip role and no association with its target. Fix: role + label.
- `lib/src/widgets/drawkit_composites.dart:655` — pager buttons announce bare "1": no position context. Fix: "page 1 of 4" labels.
- `lib/src/widgets/drawkit_nav.dart:330` — the rail binds only Enter/Space: no roving arrow focus, unlike tabs/accordion. Fix: wire move/edge intents.
- `lib/src/widgets/drawkit_table.dart:59` — headers/cells carry no table semantics: screen readers hear flat text without column context.
- `lib/src/widgets/drawkit_list.dart:82` — marker Y uses a fixed `lineHeight: 22` while text height follows 1.4×: markers misalign under text scaling. Fix: measure the text.
- `lib/src/widgets/drawkit_figure.dart:22` — no `semanticLabel`/alt parameter; caption is a detached node with no association.
- `lib/src/widgets/drawkit_heading.dart:58` — level only changes size: no `Semantics(header: true)`, so heading structure is lost for assistive tech.
- `lib/src/widgets/drawkit_avatar.dart:82` — the group always excludes semantics; with a null `semanticLabel` it announces nothing. Fix: fallback label/count.
- `lib/src/widgets/drawkit_fab_menu.dart:128` — trigger keeps its constant label while open; no `expanded` state.

### RTL, layout & motion robustness

- `lib/src/widgets/drawkit_nav.dart:270` — badge uses physical `right: -10`: doesn't mirror in RTL (also `drawkit_floating_nav.dart:246`). Fix: `PositionedDirectional(end: -10)`.
- `lib/src/widgets/drawkit_date_picker.dart:198` — header buttons swap sides in RTL but '‹'/'›' glyphs don't mirror: the right-side (previous) button points the wrong way.
- `lib/src/widgets/drawkit_breadcrumb.dart:57` — single non-wrapping `Row`: long trails overflow horizontally with no scroll or wrap.
- `lib/src/widgets/drawkit_nav.dart:183` — `DrawkitBottomNav` ignores `viewPadding.bottom`: content sits under system gesture bars.
- `lib/src/widgets/drawkit_appbar.dart:72` — AppBar ignores `viewPadding.top`: title/actions sit under the status bar.
- `lib/src/widgets/drawkit_sheet.dart:158` — the `end` edge has no dismiss affordance, `maxHeightFactor` applies only to bottom, and IME `viewInsets` are not handled: a sheet with a field is covered by the keyboard.
- `lib/src/widgets/drawkit_marquee.dart:64` — `speed > 0` is assert-only: release-0 makes duration `Infinity` and `.round()` throws `UnsupportedError`. Fix: validate at runtime.
- `lib/src/widgets/drawkit_marquee.dart:60` — duration recalculates only when child width changes: runtime speed/gap edits leave a stale cycle clock. Fix: recompute in `didUpdateWidget`.
- `lib/src/widgets/drawkit_arrow.dart:90` — the decorative arrow surface claims opaque pointers across its expand box: swallows taps on content beneath. Fix: `IgnorePointer` internally.
- `lib/src/widgets/drawkit_rating.dart:78` — no arrow keys and no focus highlight: keyboard users can only cycle with Enter/Space. Fix: arrows + focus ring.
- `lib/src/engine/rough.dart:255` — `variants` passes `n` straight to `List.generate`: negative throws, zero silently yields no frames.
- `lib/src/engine/rough.dart:58` — `ellipsePoints(n: 0)` evaluates `(a1 - a0) * 0 / 0` producing NaN offsets: a silently undrawable path.
- `lib/src/core/motion.dart:77`, `:158` — reduce-motion is read once behind `_started`: later accessibility toggles never reach `SketchIn`/`Stagger`. Fix: re-evaluate in `didChangeDependencies`.
- `lib/src/core/motion.dart:64` — `SketchIn` has no `didUpdateWidget`: duration/curve changes after mount are silently ignored.
- `lib/src/core/motion.dart:248` — `Shake` swaps controllers in `didUpdateWidget` but never applies an updated duration.
- `lib/src/widgets/drawkit_progress.dart:52` — `_started` latch skips `_syncMotion` on MediaQuery change: toggling reduced motion at runtime leaves the band sweeping (spinner `:213` and skeleton `:63` same). [V]
- `lib/src/core/surface.dart:76` — constructor allows `child == null && size == null`: a silent zero-sized `CustomPaint` that zero-radius builders then crash on. Fix: assert one is set.
- `lib/src/core/surface.dart:159` — pointer-driven resketch ignores a pinned `widget.seed`, substituting `randomSeed()` on first hover/press: the sketch changes on interaction. Fix: pass the pinned seed through.
- `lib/src/widgets/drawkit_sheet.dart:117` — grab handle is an opaque 26px strip with only a velocity heuristic (>250): no drag-follow, no distance threshold, and taps on content under the strip are swallowed with custom padding.
- `lib/src/widgets/drawkit_sheet.dart:164`, `drawkit_dialog.dart:97` — scrims hardcode `DrawkitPalette.light.ink` and a fixed barrier label: theme-blind in dark mode; no `barrierLabel` parameter.
- `lib/src/widgets/drawkit_toast.dart:94` — no queue: every toast inserts a sibling overlay entry with its own timer: back-to-back toasts overlap and fade independently. Fix: stack/replace queue.
- `lib/src/widgets/drawkit_toast.dart:298` — the linger timer never pauses while hovered/focused: Undo can vanish mid-interaction (WCAG 2.2.1). Fix: restart on pointer/focus exit.
- `lib/src/widgets/drawkit_command.dart:113`, `:160` — `_invoke` and the Escape action pop unconditionally: a double Enter/Escape in one frame can pop the caller's page. Fix: `_invoked` guard / `maybePop`.
- `lib/src/widgets/drawkit_menu.dart:286` — row focus nodes resync only when `items.length` changes: an item flipping to/from `divider` (same length) leaves orphan nodes and arrow keys stall. Fix: resync on an identity/divider signature.
- `lib/src/widgets/drawkit_date_picker.dart:109` — no bounds enforcement: paging reaches months outside `[firstDate, lastDate]`, `_edge`/`_shift` park the cursor on disabled days, and `initialDate` isn't clamped (`:413`). Fix: clamp + stop paging at bounds.
- `lib/src/widgets/drawkit_menu.dart:488` — the chevron's `AnimatedRotation` always runs 160ms, ignoring `drawkitReduceMotion` where everything else checks it.
- `lib/src/widgets/drawkit_composites.dart:446` — Alert (also Quote/Pager/Tooltip) rerolls the seed per build: any parent rebuild re-sketches the chrome. Fix: hoist into `State`.
- `lib/src/widgets/drawkit_refresh.dart:92` — handler ignores `notification.depth`: a nested horizontal scroller at its start can arm a full refresh. Fix: require depth 0.
- `lib/src/widgets/drawkit_text.dart:81` — multiply blend is isolated by the surface's repaint boundary: it renders as plain 30% alpha, not multiply.

### API parity & behavior

- `lib/src/widgets/drawkit_toast.dart:62` — vs `SnackBar`: no `alignment`/`margin`/`width`/`onDismissed`/`showCloseIcon`/`dismissDirection`; the handle has no `isVisible`.
- `lib/src/widgets/drawkit_dialog.dart:81`, `drawkit_sheet.dart:139` — vs `showDialog`/`showModalBottomSheet`: no `requestFocus`, `useRootNavigator`, `routeSettings`, `barrierLabel`, `transitionDuration`, `anchorPoint`, `fullscreenDialog`; the sheet lacks `enableDrag`/`isScrollControlled`.
- `lib/src/widgets/drawkit_menu.dart:51`, `:230` — vs `MenuAnchor`/`PopupMenuButton`: no `onOpen`/`onClose`, `alignmentOffset`, `useRootOverlay`, `MenuController`, `initialFocus`; menus only have `minWidth`, so long labels always ellipsize at 180px.
- `lib/src/widgets/drawkit_command.dart:10`, `drawkit_date_picker.dart:49` — vs `DropdownMenu`/`showDatePicker`: no `enabled`/`leading`/`group` items, no `onSelected`/`filterCallback`/`initialSelection`; the picker lacks `selectableDayPredicate`, header/footer text, input mode, `onDisplayedMonthChanged`.
- `lib/src/widgets/drawkit_button.dart:347` — `DrawkitFab` lacks the loading/error/success state API of `DrawkitButton`: async FABs can't block duplicate presses.
- `lib/src/widgets/drawkit_input.dart:80` — `DrawkitTextarea` omits `onSubmitted` which `DrawkitInput` supports: multiline parity missing.

### Test coverage & gallery claims

- `example/lib/main.dart:1970` — caption claims "Tooltip — after 300 ms of hover or focus", but `drawkit_composites.dart:374` is a static card+arrow with no hover/focus/delay logic. [V]
- `example/lib/main.dart:2246` — caption says the tabs "underline slides to the pick"; `drawkit_composites.dart:345` swaps in a fresh `DrawkitUnderline` with no animation.
- `example/lib/main.dart:2147` — caption says "dragging the list down tucks the bar"; `drawkit_floating_nav.dart:100` hides on pixel increase (drag up), and `test/floating_test.dart:176` hides by dragging up too: gesture direction is inverted vs the caption.
- `example/lib/main.dart:2075` — caption claims the rail "mirrors in RTL", but `drawkit_nav.dart:268` hardcodes `right: -10` badge positioning and no rail RTL test exists.
- `test/a11y_test.dart:37` — the only 2× text-scale test sits inside a `SingleChildScrollView` that masks vertical overflow; `example/test/a11y_gallery_test.dart:14` never sets a text scaler.
- `example/test/a11y_gallery_test.dart:19` — hardcodes LTR, never tests reduced motion, and only renders static page builders: overlays/dialogs/toasts unchecked.
- `lib/drawkit.dart:16`, `:17`, `:25` — exported engine functions `arrowStrokes`, `doubleStrokePoints`, `smooth` have zero test references.
- `lib/drawkit.dart:49` — `DrawkitNavBadge` untested; the 99+ clamp (`drawkit_nav.dart:49`) is never exercised.
- `lib/src/widgets/drawkit_sheet.dart:116` — grab-handle dismiss untested; `test/feedback_test.dart:179` only barrier-taps.
- `example/lib/main.dart:2443` — dialog focus restoration back to the trigger untested; `test/keyboard_test.dart:616` asserts Escape dismissal only.
- `lib/src/widgets/drawkit_menu.dart:143` — popover RTL/positioning untested; the popover group `test/menus_test.dart:47` never passes a direction.
- `lib/src/widgets/drawkit_skeleton.dart:75` — reduced-motion branch untested; `test/feedback_test.dart:417` checks only the moving band.
- `lib/src/widgets/drawkit_checkbox.dart:147`, `drawkit_radio.dart:169`, `drawkit_toggle.dart:169` — reduced-motion paths untested; the `test/controls_test.dart:9` host sets no animation setting.
- `lib/src/core/motion.dart:160` — Stagger's reduced-motion branch untested (`test/motion_test.dart:128` covers SketchIn/Shake only).
- `test/surface_test.dart:22` vs `:37` — claims "paints three boil frames" but only the seed-set size is checked: no test counts frames.
- `test/button_test.dart:34` — taps a callback-less disabled button yet never asserts the tap was ignored (semantics only at `:33`).
- `test/keyboard_test.dart:611`, `:635` — hardcoded `tab(tester, 3)` hops; `test/states_test.dart:292` bakes in the 5000ms toast linger (`drawkit_toast.dart:74`).
- `example/test/widget_test.dart:5` — only boots the gallery; sidebar selection (`example/lib/main.dart:296`) and RTL/dark toggles (`:339`, `:357`) are never exercised.

---

## P2 — improvements

### Overlays

- `lib/src/widgets/drawkit_panel.dart:164` — panel rows have hover/focus but no pointer-down state (command rows too, `drawkit_command.dart:259`): presses feel dead. Fix: pressed wash from `onTapDown`.
- `lib/src/widgets/drawkit_date_picker.dart:92` — no `didUpdateWidget`: externally changed `value`/`firstDate`/`lastDate` never move `_month`/`_cursor` (broken controlled use).
- `lib/src/widgets/drawkit_menu.dart:442` — divider seeds default to `widget.seed ?? 1` and the painter ignores `boil`: every seedless menu gets identical, non-boiling rules.
- `lib/src/widgets/drawkit_dialog.dart:38` — only `maxWidth` is constrained: tall content overflows the route non-scrollably, unlike `AlertDialog`. Fix: constraints/scroll behavior.
- `lib/src/widgets/drawkit_menu.dart:361` — on close, `requestFocus()` runs post-frame and can steal focus from a dialog an item just pushed ("Save as…" pattern).
- `README.md:66` — "Every control meets the accessibility guidelines" is contradicted by the toast action semantics (`drawkit_toast.dart:221`) and unlabeled popover triggers (`drawkit_menu.dart:179`). Fix the code or narrow the claim.
- `lib/drawkit.dart:3` vs `README.md:4` — the library doc and README link two different drawably repositories; one is wrong.

### Controls, display & core

- `lib/src/widgets/drawkit_checkbox.dart:76` — `animate: false` still plays the 240ms check draw-on (radio same): only reduced motion short-circuits it. Fix: gate on `widget.animate`.
- `lib/src/widgets/drawkit_segmented.dart:263` — semantics `onTap` reports the already-selected value while `_pick` suppresses no-ops: inconsistent callbacks. Fix: route semantics through `_pick`.
- `lib/src/widgets/drawkit_select.dart:265` — placeholder detection compares label text: an option whose label equals the placeholder renders muted as if unchosen. Fix: use the value lookup.
- `lib/src/widgets/drawkit_button.dart:198` — the 0.98 press scale has no `transformAlignment`: shrinks toward top-left instead of centre. Fix: `Alignment.center`.
- `lib/src/widgets/drawkit_fab_menu.dart:223` — stagger start clamps at 0.7: menus longer than ~7 items animate in simultaneous groups. Fix: divide the span by item count.
- `lib/src/core/focus.dart:48` — ring radius is caller-supplied and drifts (10 for an 8px shape, 12 for a 9px pill). Fix: derive from each shape.
- `lib/src/core/surface.dart:182` — `_syncBoil` starts/stops the controller during build: build-phase side effect. Fix: move to lifecycle methods.
- `lib/src/core/intents.dart:17` — doc says "slides a continuous value by delta" but sliders multiply by `_step`: ambiguous unit. Fix: rename/document as a step count.
- `lib/src/widgets/drawkit_rating.dart:63` — `count: 0` computes negative star width and asserts; no constructor guard. Fix: assert `count > 0`, clamp width.
- `lib/src/widgets/drawkit_progress.dart:175` — `width: double.infinity` asserts under unbounded width (Row/horizontal scroll). Fix: intrinsic fallback.
- `lib/src/widgets/drawkit_skeleton.dart:192` — shimmer always sweeps LTR while the progress bar mirrors: kit inconsistency. Fix: read `Directionality`.
- `lib/src/widgets/drawkit_refresh.dart:190` — `'refreshing'` label is hardcoded English and not overridable.
- `lib/src/widgets/drawkit_figure.dart:84` — caption is a bare sibling `Text`: no figure/caption association. Fix: wrap both in labeled semantics.
- `lib/src/widgets/drawkit_arrow.dart:169` — the poll reschedules a post-frame callback every frame forever, even when idle or `animate: false`. Fix: stop once rects stabilize.
- `lib/src/widgets/drawkit_empty.dart:53` — an appearing empty state is a silent container: no live region, may not be announced. Fix: liveRegion + label.
- `lib/src/engine/rough.dart:21` — `RoughOptions.copyWith` can't change `roughness`/`boil` or clear `boilSeed` (null coalescing). Fix: add `clearBoilSeed` + full fields.
- `lib/src/core/style.dart:220` — `copyWith` can't clear `width` back to null although `clearSeed`/`clearInk` patterns exist.
- `lib/src/core/surface.dart:184` — painter and frame cache are recreated every build: all boil frames regenerate on each hover. Fix: hoist into `State` keyed by size/seed/style.
- `lib/src/core/surface.dart:131`, `drawkit_list.dart:48` — switching `seed` from a value back to null keeps the old sketch instead of generating a new one.
- `lib/src/core/focus.dart:30` — negative `minWidth`/`minHeight` pass into `BoxConstraints` and trip its assertion. Fix: clamp/assert non-negative.
- `lib/src/core/surface.dart:217` — disabling while hovered leaves `_hovered` true: re-enabling shows the click cursor before pointer entry.
- `lib/src/core/style.dart:127` — `drawkitContrast` ignores alpha: translucent colors report misleading luminance. Fix: composite over background.
- `lib/src/widgets/drawkit_appbar.dart:39` — title merge keeps ambient decoration (e.g. underline); other text widgets force `none`.
- `lib/src/widgets/drawkit_avatar.dart:55` — `overlap < size` is assert-only: release accepts inverted overlap with negative spacing. Fix: clamp.
- `lib/src/widgets/drawkit_heading.dart:21` — level guard is assert-only: release `_sizes[level - 1]` throws RangeError. Fix: clamp.
- `lib/src/widgets/drawkit_table.dart:40` — row-length check is assert-only: release mismatches throw RangeError while building cells. Fix: validate/pad.
- `lib/src/widgets/drawkit_nav.dart:25` — badge announcements emit "0 notifications"/"-2 notifications": counts are unvalidated. Fix: clamp ≥ 0 and handle zero.
- `lib/src/widgets/drawkit_breadcrumb.dart:89` — every non-tappable crumb is bold: the current page lacks distinct styling. Fix: bold only the last.

### Test-suite organization

- Fourteen-plus files duplicate a private `host()` harness (`test/button_test.dart:9`, `test/actions_test.dart:9`, `test/controls_test.dart:9`, `test/states_test.dart:8`, …): extract one shared fixture.
- `test/feedback_test.dart` packs dialogs (`:31`), sheets (`:149`), toasts (`:222`), progress (`:272`), spinner (`:355`), skeleton (`:399`) into one 455-line file.
- `test/js_parity_test.dart:11` loads fixtures via a CWD-relative `File('test/fixtures/js_vectors.json')`: use `File.fromUri(Platform.script)`.
- White-box builder tests hard-code internal sizes (`test/actions_test.dart:107`, `test/rtl_test.dart:242`, `test/feedback_test.dart:286`), bypassing real layout regressions.
- Ten near-identical disposal smoke tests (`test/button_test.dart:84`, `test/controls_test.dart:84`, `:157`, `:206`, `test/input_test.dart:60`, `:84`, `test/select_test.dart:137`, `test/text_test.dart:64`) add little signal.
- `DrawkitPanelRow`/`DrawkitCheckPainter` (`lib/src/widgets/drawkit_panel.dart:99`) live in a library omitted from the export list (`lib/drawkit.dart:27-63`).
- Coverage is split by theme rather than widget (`test/actions_test.dart:74` segments, `test/menus_test.dart:162` + `test/keyboard_test.dart:281` accordion): naming is inconsistent.
- `test/a11y_sample.dart` is a 197-line non-test helper duplicating palette/theme setup repeated in `example/test/a11y_gallery_test.dart:21`.

---

## Missing widgets / features (web research)

Parity gaps against the wider ecosystem the kit imitates or could join:

### rough.js (the engine drawkit mirrors)
The kit implements one fill mode (scribble). rough.js offers `hachure`, `solid`, `zigzag`, `cross-hatch`, `dots`, `sunburst`, `dashed`, `zigzag-line`, plus `fillWeight`, `hachureAngle`, `hachureGap`, `roughness`, `bowing`, `curveStepCount`, `curveFitting`, `strokeLineDash`, `disableMultiStroke`, `preserveVertices`. Suggested: `DrawkitFillStyle` enum + the fill-weight/pattern options.

### rough_notation (annotation vocabulary)
Kit has underline/highlight/circle. Missing: box, bracket, strike-through, crossed-off, plus triggers/iterators/groups (automation sequencing).

### wired-elements (counterparts)
Missing counterparts: link, icon, image, combo/autocomplete, listbox, radio-group (kit has radio rows but no group abstraction), video, tabs (kit has tabs), search-input (kit has), tooltip (static only — see P1).

### Flutter/Material catalog (missing companions)
`TimePicker` (kit only has date), `CarouselView`, `Autocomplete`/combo, `SearchAnchor`-style full search UI, paginated/data-table sorting, banners, docked toolbar. Material 3 Expressive adds: expressive time picker, morphing loading indicator, split button, button groups, floating toolbar, wavy progress, multi-aspect carousels — confirming the previously deferred M3E batch.

### Competitor sketch (hand_drawn_toolkit / sketchy libraries)
Organized chart widgets (bar/line/scatter with legend + hit-testing) and status-square badges: a "DrawkitChart" family is the largest single feature gap for the hand-drawn aesthetic.

### WCAG 2.2 reference
SC 2.5.8 Target Size (Minimum, AA): 24×24 CSS px with a spacing exception; SC 2.5.5 (Enhanced, AAA) 44×44. The kit's 48dp `DrawkitTapTarget` aspiration is above both; findings above (18px search clear, star hit boxes, breadcrumb padding) should be measured against the AA baseline at minimum.

---

## Suggested fix waves (proposal for M26+)

- **M26 — all P0 (39).** Two batches: (a) overlays/routing/theming (8), (b) widget + engine crashes and RTL/tap mismatches (23), plus rewiring the 8 could-never-fail tests to real assertions. Repro test first per bug.
- **M27 — P1 (~83).** Semantics roles/labels, focus traps/roving, RTL mirroring, reduced-motion latches, API parity parameters. Fold in gallery caption fixes (captions rewritten or behavior implemented).
- **M28 — P2 (~43).** API additions, seed/repaint hygiene, test-suite restructure (shared host fixture, file split), README/doc corrections.
- **M29+ — new widgets (scope decision after review).** Expanded fill styles, annotation additions, TimePicker, combo/autocomplete, carousel, chart family, then the M3E batch (split button, wavy progress, morphing loader, floating toolbar).
- Every wave follows the established milestone pattern: tests first for the repro, `dart format`, `dart analyze` (single root, not `flutter analyze`), `flutter test` root + example, web build, `pub --dry-run`, one commit per milestone.

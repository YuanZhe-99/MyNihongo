# Adaptive layout

This is the app-wide rule for **when a layout may split** — into two columns on the kana page and
the Learn dashboard, into multiple columns in the vocabulary and grammar lists, and into two panes on
the settings page, on a foldable's inner panel, a tablet or a desktop window — and, once it may,
**how many columns** it gets. A second, narrower rule decides **where navigation lives**. All of it
lives in [`lib/shared/utils/adaptive_layout.dart`](functions/shared/utils/adaptive_layout.md), a
module that deliberately imports nothing but `dart:core` so every decision is directly unit-testable
without a widget tree.

The conventions are the ones MyAnime!!!!! worked out across its 1.5.2 – 1.5.7 releases and wrote
up as the series' adaptive-layout guide, adopted here from the first commit so one device answers
the same way in every app of the series. The numbers are worthless without the reasoning, so the
reasoning is written down. **If a widget file contains a numeric width comparison, it is a bug** —
the number belongs in the policy module, and the page calls a named predicate.

## When to split

Split when **all three** of these hold:

| Constant | Value | What it is |
|---|---|---|
| `splitMinWidth` | `600.0` | Material's *medium* width class; Android's `sw600dp`. |
| `splitMinHeight` | `480.0` | The compact/medium height boundary. |
| `splitMinAspect` | `0.82` | Width divided by height. |

```dart
bool canSplitLayout(double width, double height) {
  if (width < splitMinWidth) return false;
  if (height < splitMinHeight) return false;
  if (height <= 0) return false;
  return width / height >= splitMinAspect;
}
```

Each condition earns its place, and none of them alone is enough.

### The aspect test is the load-bearing one

**It is why this is not a plain width breakpoint, and the Galaxy Z Fold 8 is why it has to exist.**
The Fold 8 unfolds to a 4:3 *landscape* panel (2448 × 1848 px), so held in portrait it is 3:4 —
narrower relative to its height than the near-square Fold 7 it replaced — while the Fold 8 Ultra
went the other way. One generation spans roughly 672 to 954 logical pixels unfolded, and one device
needs two different answers at one width. No width threshold can produce that; an aspect test can.

Pixel counts are authoritative; logical pixels depend on the density bucket and on Samsung's
user-adjustable **Display size** setting, so a plausible range is shown.

| Device | Inner panel, px | Portrait W:H | Portrait W, dp | Portrait | Landscape |
|---|---|---|---|---|---|
| Galaxy Z Fold 5 | 1812 × 2176 | 0.83 | 659–690 | split | split |
| Galaxy Z Fold 6 | 1856 × 2160 | 0.86 | 675–707 | split | split |
| Galaxy Z Fold 7 | 1968 × 2184 | 0.90 | 716–750 | split | split |
| **Galaxy Z Fold 8** | **2448 × 1848 (4:3 landscape)** | **0.755** | **672–704** | **single** | **split** |
| Galaxy Z Fold 8 Ultra | 2256 × 2504 | 0.90 | 820–859 | split | split |
| Pixel 9 / 10 Pro Fold | 2076 × 2152 | 0.96 | 755–791 | split | split |

`0.82` sits near the middle of the gap between the Fold 8's portrait `0.755` and the Fold 7 /
Fold 8 Ultra's portrait `0.90`, with roughly 9% margin on each side. Keep the constant as-is unless
a device falls in the gap; changing it is a whole-app behaviour change.

### The width floor

Every unfolded panel clears 600 dp by at least 59 dp even at the denser end of the range, and every
folded cover screen sits well below it: Z Fold 7 / 8 Ultra roughly 360 dp, Z Fold 8 roughly
356–416 dp, Pixel 10 Pro Fold roughly 411 dp.

### The height floor

The aspect test alone admits *wide and short* viewports. Without the floor, a folded Z Fold 8 cover
screen rotated to landscape (~657 × 416 dp) and an ordinary phone in landscape (~915 × 412 dp)
would both split into two cramped panes. Google gives the same advice independently: for a phone or
an open flippable in landscape the window width is typically medium but the height is compact, and
two-pane layouts are not practical there.

### The consequence worth knowing

The rule is about **shape, not device class**, so a 4:3 tablet in portrait (768 × 1024 → 0.75) and a
16:10 tablet in portrait (0.625) also stay single column, exactly like the Fold 8 in portrait. Both
split in landscape. "My tablet doesn't split in portrait" is the rule working.

## Where navigation lives

```dart
const navRailMinWidth = 600.0;
const navRailWidth = 81.0; // 80 dp NavigationRail + 1 dp VerticalDivider

bool useNavigationRail(double screenWidth) => screenWidth >= navRailMinWidth;
```

**Width only, on purpose. It is not routed through `canSplitLayout`.** A rail is not a split; it
trades width, which is abundant whenever the test passes, for height, which is not. The case it
helps most is precisely the one the split rule rejects: a phone in landscape at 915 × 412, where a
bottom bar spends 19% of the height on navigation while 915 dp of width sits unused.

Two consequences are carried through the whole app:

```dart
double shellContentWidth(double screenWidth) =>
    useNavigationRail(screenWidth) ? screenWidth - navRailWidth : screenWidth;

double shellListBottomInset(double screenWidth) =>
    useNavigationRail(screenWidth) ? 16.0 : 80.0;
```

The rail and the bottom bar are built from **one list of destinations** in `shell_scaffold.dart`,
with `groupAlignment: 0` on the rail so five destinations sit centred rather than pinned to the top
of a tall rail.

## How many fit

Never a hardcoded count per breakpoint. Ask how many columns of a stated minimum fit:

```dart
int columnCapacity(double contentWidth, {required double minItemWidth,
    double gap = listTileGap, int maxColumns = listMaxColumns});
```

One gap is added to the numerator so the arithmetic pays for the gaps *between* columns rather than
one after every column. Each caller brings the minimum its own content needs, and the doc comment
states where the number came from:

| Caller | Constant | Minimum | Max | Why that number |
|---|---|---|---|---|
| Kana tables | `kanaTableMinWidth` | 330 | 2 | A five-column table spends 44 on its row label, leaving ≈ 57 per cell — level with what a phone gives it in one column. Narrower and the unfolded screen would show more, smaller kana than a phone. |
| Rule cards, Learn cards | `ruleCardMinWidth` | 320 | 2 | Paragraphs; a third column falls below a comfortable reading measure, and below 320 a two-line title wraps to three. |
| Vocabulary / grammar tiles | `referenceTileMinWidth` | 320 | 4 | Headword, reading line, one meaning line and a trailing level chip; narrower and the longest seeded English gloss truncates before the chip. |

Reference pages centre their content inside `pageMaxContentWidth` (1080), so a desktop window does
not stretch a five-column table across 1600 pixels. `referenceContentWidth(screenWidth)` is the
one place that computes "content less the rail, less the page padding, capped" — the kana,
vocabulary and grammar pages all size from it, so they agree on where the second column appears.

## Measure the screen for the gate, the content box for the capacity

- **Gate** (`canSplitLayout`, `useNavigationRail`) reads `MediaQuery.sizeOf(context)` — the whole
  screen. Measuring the split against the `Scaffold` body would subtract the app bar and read a
  Fold 8 in portrait as 0.80 instead of 0.755, leaving almost no margin under the threshold.
- **Capacity and pane widths** read what the content actually gets: `referenceContentWidth`, or
  `LayoutBuilder`'s `constraints.maxWidth`.

## Which rule each page uses

Every decision is recorded here with what it costs.

| Page | Rule | Decision |
|---|---|---|
| Shell | width only | Rail from 600 dp. |
| Kana | **double gate** | Two columns when `canSplitLayout` **and** two `kanaTableMinWidth` tables fit `referenceContentWidth`. The second gate is what keeps the Z Fold 5/6 and a Fold 7 in portrait (546–637 dp of content; two tables need 672) on one column with no breakpoint of their own. The script switch and the search field share a row in two-column mode. Rule cards flow 1–2 across by `ruleCardMinWidth` against whatever width the section gets. |
| Vocabulary, Grammar | shape gate + capacity | `referenceColumnCount`: 1 column unless `canSplitLayout`, then `columnCapacity` at `referenceTileMinWidth`, capped at `listMaxColumns` (4). A Fold 8 in landscape gets two, a tablet in landscape two, a desktop three. A stored `referenceListColumns` preference is clamped to that capacity, never rejected, so a 4 chosen on a tablet renders as 2 on a folded phone and returns to 4 when the window grows. The control is hidden when capacity is 1. See [`features/reference-preferences.md`](features/reference-preferences.md). |
| Learn | shape gate + capacity | Dashboard cards 1–2 across by `ruleCardMinWidth`, gated on `canSplitLayout`. The today card spans the full width above them at every size: what to do now is the one thing a returning learner should read without scanning. |
| Quiz | shape gate | Question pane fixed at `quizQuestionPaneWidth` (0.45 of the content width, clamped 320–520, then capped so the answer pane keeps `quizAnswerPaneMinWidth` of 280), answers in the rest, when `canSplitLayout`; stacked otherwise. The question is the smaller half deliberately: it holds a word or a sentence, the answer half holds four options with Japanese on them. Below 600 dp the split would leave both halves worse than one column. |
| Settings | shape gate | Two panes when `canSplitLayout`; left pane `settingsLeftPaneWidth(shellContentWidth)` — proportional (0.44), clamped 300–440, and capped so the detail pane never drops below `settingsRightPaneMinWidth` (280). Second-level pages are pushed full-screen on a narrow window and hosted in a nested `Navigator` in the detail pane on a wide one, so one widget serves both. |
| WebDAV sync, Backup | none | One column at every size. Both are second-level pages, so the Settings row above decides whether they are pushed or hosted in the detail pane; the pages themselves measure nothing. |
| Detail sheets | none | Bottom sheets, identical in every mode. |
| Pronunciation practice | none | One column at every size, capped at `pageMaxContentWidth`. It holds a target line, a record button and a row of mora chips; there is no second thing to put beside them, and the chips wrap rather than needing columns. |
| Sentence lab | none | One column at every size, capped at `pageMaxContentWidth`. A deliberate exception to the usual split-when-it-fits rule: the four sections are a chain — the structure refers to the words, the grammar to the structure, the issues to both — and putting a reference beside its referent would make the reading order ambiguous. |

**Cost accepted knowingly:** a phone in landscape (915 × 412) keeps every single-column layout
although it has the least height of any viewport — the case that would have benefited most. The
series took that trade for consistency across its split surfaces; this app follows it.

## Folding and unfolding at runtime

`android/app/src/main/AndroidManifest.xml` declares
`screenLayout|screenSize|smallestScreenSize|density` in the activity's `configChanges`, so the
window resizes **without recreating the activity** and everything reading `MediaQuery.sizeOf`
re-evaluates on the next frame. That is all "switch automatically when the device unfolds" needs.
Without it the activity recreates and un-persisted page state — a half-typed search — is lost
mid-fold.

## Testing

1. **Pure-function tests** (`test/adaptive_layout_test.dart`): every threshold at `n − 1` and `n`,
   every clamp at both ends, each viewport named for the device it stands for.
2. **Widget tests** at the same geometries (`test/kana_layout_ui_test.dart`,
   `test/shell_nav_ui_test.dart`, `test/widget_test.dart`): relative positions (same `y`,
   different `x`), and `expect(tester.takeException(), isNull)` to catch overflow stripes.
3. `flutter_test` renders every glyph of its default font as a full em square, inflating Latin text
   to roughly 2.5× its real width. Layout tests that care about text width are driven in Simplified
   Chinese, whose glyphs really are square, so the test measures the production layout rather than
   a font artifact. When a layout test overflows, check whether an unchanged path fails the same way
   before believing the layout is broken.
4. Do not index scrollables positionally; every `TextField` contributes its own `Scrollable`.
5. Note that the default 800 × 600 test viewport passes `canSplitLayout`; pin an explicit viewport in
   any test that cares.
6. Before claiming no inline breakpoint remains, grep the whole tree:

```bash
grep -rnE "maxWidth *[<>]=? *[0-9]|size\.width *[<>]=? *[0-9]" lib/
```

### Looking at it

Tests catch overflow and column counts; they do not catch a layout that is
technically correct and visually wrong. The screenshot pass covers that, and it
needs real hardware — the development host has no emulator. The procedure is in
[`../../tool/screenshots.md`](../../tool/screenshots.md). Each shot is checked
for four things:

- [ ] No overflow stripes and no text clipped mid-glyph.
- [ ] Navigation on the expected side: rail from 600 dp, bottom bar below it.
- [ ] The column count the rules predict for that geometry.
- [ ] Nothing under the gesture bar or the hinge.

## Divergence from Google's guidance, stated on purpose

Google's adaptive-layout guidance says window size classes are not intended for device-type logic
and directs apps to decide from available width. This convention **deliberately diverges on exactly
one point: the aspect test.** Width alone cannot give the Fold 8 two different answers in its two
orientations, and that behaviour is the requirement the rule exists to satisfy. Everything else
follows Google: the width and height floors are its breakpoints, the column capacity is its feed
guidance, and the navigation rail at medium width and up is its recommendation verbatim.

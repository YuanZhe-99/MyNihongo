# lib/shared/utils/adaptive_layout.dart

The app-wide adaptive-layout policy: the `splitMinWidth`, `splitMinHeight` and `splitMinAspect`
thresholds that decide whether a layout may split at all; `navRailMinWidth` and `navRailWidth` for
the shell; `listTileGap`, `listMaxColumns` and `listColumnsAuto` for multi-column lists;
`pageMaxContentWidth`, `kanaTableMinWidth`, `ruleCardMinWidth` and `referenceTileMinWidth` — this
app's own per-content minimums, each with a doc comment saying where the number came from; and
`settingsRightPaneMinWidth`. Nine pure helpers sit on top of them.

The module deliberately depends on nothing but `dart:core` — no Flutter imports, and `canSplitLayout`
takes two doubles rather than a `Size` — so every helper is directly unit-testable
(`test/adaptive_layout_test.dart`), and the rendered result is covered separately at real device
geometries by `test/kana_layout_ui_test.dart`, `test/shell_nav_ui_test.dart` and
`test/widget_test.dart`. The derivation of the numbers lives in
[../../../adaptive-layout.md](../../../adaptive-layout.md); this page documents the declarations.

Consumers: `shell_scaffold.dart` (`useNavigationRail`); `kana_page.dart` (`referenceContentWidth`,
`canSplitLayout`, `columnCapacity` at `kanaTableMinWidth` and `ruleCardMinWidth`); `vocab_page.dart`
and `grammar_page.dart` (`referenceColumnCount`, `listRowCount`); `learn_page.dart`
(`canSplitLayout`, `columnCapacity` at `ruleCardMinWidth`); `settings_page.dart` (`canSplitLayout`,
`shellContentWidth`, `settingsLeftPaneWidth`); the sentence lab and writing practice
(`labInputPaneWidth`); every scrolling page (`shellListBottomInset`);
`adaptive_tile_grid.dart` (`listRowCount`, `listTileGap`).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`canSplitLayout`](#cansplitlayout) | top-level function | A | Report whether a layout may split into panes or columns. |
| [`useNavigationRail`](#usenavigationrail) | top-level function | A | Report whether the shell should show a navigation rail. |
| `shellContentWidth` | top-level function | B | Return the width a shell page's content actually receives: the screen less the rail when shown, never negative. |
| `shellListBottomInset` | top-level function | B | Return the bottom padding a scrolling list needs: 80 under a bottom bar, 16 beside a rail. |
| `referenceContentWidth` | top-level function | B | Return a reference page's content width: `shellContentWidth` less the page padding, capped at `pageMaxContentWidth`. |
| [`columnCapacity`](#columncapacity) | top-level function | A | Return how many columns of a given minimum width fit a content box. |
| [`referenceColumnCount`](#referencecolumncount) | top-level function | A | Return the number of columns a vocabulary or grammar list renders. |
| `listRowCount` | top-level function | B | Return how many rows a list of items needs at a column count; ragged last row included. |
| `settingsLeftPaneWidth` | top-level function | B | Return the settings page's left pane width: 0.44 of the content, clamped 300–440, capped so the right pane keeps 280. |
| `labResultPaneMinWidth` | top-level constant | B | The narrowest the sentence lab's analysis pane may be: 360. |
| `labInputPaneWidth` | top-level function | B | Return the lab's and writing practice's input pane width: 0.40 of the content, clamped 320–460, capped so the result pane keeps 360. |

## Documentation

### `bool canSplitLayout(double width, double height)` <a id="cansplitlayout"></a>

- **Kind:** top-level function
- **Purpose:** The app-wide shape gate.
- **Inputs:** The **whole screen** size in logical pixels — `MediaQuery.sizeOf(context)`, never the
  `Scaffold` body.
- **Returns:** `true` only when `width >= 600`, `height >= 480`, `height > 0`, and
  `width / height >= 0.82`.
- **Side effects:** None.
- **Algorithm:** Three independent tests, all of which must pass.
- **Usage:** Every page that can split, and `referenceColumnCount`.
- **Notes:** The aspect test is the load-bearing one: it keeps a Galaxy Z Fold 8 held in portrait
  (0.755) on one column while the same device in landscape splits, and lets the near-square Fold 7
  and Fold 8 Ultra split in both orientations. The width floor is the `sw600dp` tablet threshold;
  the height floor rejects a phone or a folded cover screen held in landscape.

### `bool useNavigationRail(double screenWidth)` <a id="usenavigationrail"></a>

- **Kind:** top-level function
- **Purpose:** Decide between the bottom bar and the rail.
- **Inputs:** The whole screen width.
- **Returns:** `screenWidth >= 600`.
- **Side effects:** None.
- **Algorithm:** One comparison.
- **Usage:** `ShellScaffold.build`; `shellContentWidth`; `shellListBottomInset`.
- **Notes:** **Width only, deliberately** — not routed through `canSplitLayout`. A rail trades
  width, which is abundant whenever this is true, for height, which is not; the case it helps most
  is a phone in landscape, which the split rule rejects on purpose.

### `int columnCapacity(double contentWidth, {required double minItemWidth, double gap = listTileGap, int maxColumns = listMaxColumns})` <a id="columncapacity"></a>

- **Kind:** top-level function
- **Purpose:** The adaptive-minimum-width count Google recommends for feeds, instead of a hardcoded
  count per breakpoint.
- **Inputs:** The width the content actually gets; the narrowest one column may be; the gap between
  columns; a ceiling.
- **Returns:** `((contentWidth + gap) / (minItemWidth + gap)).floor()` clamped to `[1, maxColumns]`;
  1 for a non-positive width; the ceiling for a non-positive minimum.
- **Side effects:** None.
- **Algorithm:** One gap is added to the numerator so the arithmetic pays for the gaps *between*
  columns rather than one after every column.
- **Usage:** The kana tables (330, max 2), the rule and dashboard cards (320, max 2),
  `referenceColumnCount` (320, max 4).
- **Notes:** Each caller brings the minimum its own content needs, and the constant's doc comment
  says where the number came from.

### `int referenceColumnCount({required double screenWidth, required double screenHeight, required double contentWidth})` <a id="referencecolumncount"></a>

- **Kind:** top-level function
- **Purpose:** The column count for the vocabulary and grammar lists.
- **Inputs:** The whole screen (the gate) and the list's own width (the capacity).
- **Returns:** 1 when `canSplitLayout` fails; else `columnCapacity(contentWidth, minItemWidth:
  referenceTileMinWidth)`.
- **Side effects:** None.
- **Algorithm:** Gate, then capacity.
- **Usage:** `_buildList` in both browser pages.
- **Notes:** The gate reads the screen while the capacity reads the list's width, deliberately.
  There is no stored preference yet; when one arrives, clamp it to the capacity rather than
  rejecting it, so a choice made on a desktop survives a folded phone.

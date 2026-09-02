# lib/features/kana/views/kana_page.dart

`KanaPage` is the second tab: a UI-only hiragana/katakana quick reference over the catalog in
`features/kana/models/kana.dart`. It renders the script switch, the search field, the three tables
(when the query is empty), the search-results grid (when it isn't), and a set of pronunciation-rule
cards, in one or two columns according to the window. The file also defines `_KanaRule`, the
display data of one rule card. See
[../../../../features/kana-reference.md](../../../../features/kana-reference.md) and
[../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `KanaPage.new` | constructor | B | Create a kana page instance. |
| `KanaPage.createState` | method | B | Create the mutable state object for this widget. |
| `_KanaPageState.dispose` | method | B | Release the search controller. |
| [`_KanaPageState.build`](#kanabuild) | method (widget build) | A | Build the page in one or two columns: script switch, search field, and either the tables or the results, plus the rule cards. |
| `_KanaPageState._buildKanaTable` | method (widget helper) | B | Render one titled kana table (header row + data rows). |
| `_KanaPageState._buildHeaderRow` | method (widget helper) | B | Render a table's column-label header row. |
| `_KanaPageState._buildKanaRow` | method (widget helper) | B | Render one consonant row of kana cells plus its label. |
| `_KanaPageState._buildKanaCell` | method (widget helper) | B | Render one kana/romaji cell, or a blank for a missing slot. |
| `_KanaPageState._buildSearchResults` | method (widget helper) | B | Render the search results, or an empty-state message. |
| `_KanaPageState._buildResultTile` | method (widget helper) | B | Render one kana entry as a search-result tile. |
| [`_KanaPageState._buildRules`](#kanabuildrules) | method (widget helper) | A | Lay out the seven pronunciation-rule cards in one or two columns. |
| `_KanaPageState._buildRuleCard` | method (widget helper) | B | Render one pronunciation-rule card (icon, title, body). |
| `_KanaPageState._sectionTitle` | method (widget helper) | B | Render a section heading (icon + label) shared by the tables and rules. |
| `_KanaRule.new` | constructor | B | Create a rule card's display data (icon, title, body, colors). |

## Documentation

### `Widget build(BuildContext context)` <a id="kanabuild"></a>

- **Kind:** method of `_KanaPageState` (widget build)
- **Source:** `lib/features/kana/views/kana_page.dart`
- **Purpose:** Build the page in one or two columns, according to the window.
- **Inputs:** `context`.
- **Returns:** The page's widget tree.
- **Side effects:** None beyond building widgets.
- **Algorithm:**
  1. `contentWidth = referenceContentWidth(screen.width)` — the content less the rail and the page
     padding, capped at `pageMaxContentWidth`.
  2. `twoColumn = canSplitLayout(screen.width, screen.height) &&
     columnCapacity(contentWidth, minItemWidth: kanaTableMinWidth, maxColumns: 2) >= 2`.
  3. Build the script picker, the search field, the three tables and the rules section as locals.
  4. Header: side by side in a `Row` when `twoColumn`, otherwise stacked.
  5. Body: the search results plus the rules when a query is active; otherwise a two-column `Row` of
     (basic, yōon) and (voiced, rules) when `twoColumn`; otherwise the stacked order.
- **Usage:**
  ```dart
  GoRoute(path: '/kana', builder: (context, state) => const KanaPage()),
  ```
  (from `appRouter` in `lib/app/router.dart`)
- **Notes:** **Gated twice, on purpose.** The first gate is the app-wide shape rule; the second asks
  whether two tables of at least 330 logical pixels actually fit. The second is what keeps the
  narrower unfolded foldables — a Z Fold 5 has 546 of content, and two tables need 672 — on one
  column without needing a breakpoint of their own. The columns are assigned rather than flowed so
  they balance: the tall basic and yōon tables on the left against the short voiced table plus the
  rules on the right.

### `Widget _buildRules(ThemeData theme, AppLocalizations l10n)` <a id="kanabuildrules"></a>

- **Kind:** method of `_KanaPageState` (widget helper)
- **Source:** `lib/features/kana/views/kana_page.dart`
- **Purpose:** Lay out the seven pronunciation-rule cards across one or two columns.
- **Inputs:** `theme`, `l10n`.
- **Returns:** A section title above a `Wrap` of fixed-width cards.
- **Side effects:** None beyond building widgets.
- **Algorithm:** Inside a `LayoutBuilder`, take
  `columnCapacity(constraints.maxWidth, minItemWidth: ruleCardMinWidth, maxColumns: 2)`, divide the
  available width by it net of the gaps, and give every card that width.
- **Usage:** `final rules = _buildRules(theme, l10n);` from `build`.
- **Notes:** Measured against whatever this section is actually given — a whole page width in one
  column and half of one in two — so the cards reflow on their own rather than needing to know which
  mode the page is in. Capped at two columns because these are paragraphs.

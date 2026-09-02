# lib/features/grammar/views/grammar_page.dart

`GrammarPage` is the fourth tab: a searchable, level-filterable browser over
`ContentCatalog.grammar`. It watches `contentCatalogProvider`, shows a spinner or an error line while
the catalog is unavailable, and otherwise renders a header (search field, level chips, count) above
an adaptive-column list of tiles; tapping a tile opens a bottom sheet with the full entry. It has the
same shape as `vocab_page.dart` and shares its chips, badges and example rendering through
`reference_widgets.dart`. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md) and
[../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GrammarPage.new` | constructor | B | Create a grammar page instance. |
| `GrammarPage.createState` | method | B | Create the mutable state object for this widget. |
| `_GrammarPageState.dispose` | method | B | Release the search controller. |
| `_GrammarPageState.build` | method (widget build) | B | Build the grammar browser around the catalog provider's three states. |
| [`_GrammarPageState._buildList`](#buildlist) | method (widget helper) | A | Build the filtered, adaptive-column list with its header as a virtualized `ListView.builder`. |
| `_GrammarPageState._buildHeader` | method (widget helper) | B | Build the search field, level chips, and result count. |
| `_GrammarPageState._buildTile` | method (widget helper) | B | Build one grammar tile: pattern, structure, one meaning line, level badge. |
| `_GrammarPageState._showDetail` | method (widget helper) | B | Show a grammar point's full entry in a modal bottom sheet. |
| `_GrammarPageState._sectionLabel` | method (widget helper) | B | Render a small section label inside the detail sheet. |

## Documentation

### `Widget _buildList(BuildContext context, AppLocalizations l10n, ContentCatalog catalog)` <a id="buildlist"></a>

- **Kind:** method of `_GrammarPageState`
- **Source:** `lib/features/grammar/views/grammar_page.dart`
- **Purpose:** Turn the catalog plus the current filter into a scrolling, adaptive-column list.
- **Inputs:** `context`, `l10n`, `catalog`.
- **Returns:** A `ListView.builder`.
- **Side effects:** None.
- **Algorithm:**
  1. Filter `catalog.grammar` by the selected level and the trimmed, lowercased query
     (`GrammarPoint.matches`).
  2. `columns = referenceColumnCount(screen, referenceContentWidth(screen.width))`;
     `rowCount = listRowCount(filtered.length, columns)`.
  3. Item 0 is the header; when the filter matches nothing, item 1 is the empty-state line;
     otherwise items 1…rowCount are `adaptiveTileRow`s, each centred inside `pageMaxContentWidth`.
- **Usage:** Called from `build` in the provider's `data` branch.
- **Notes:** Rows rather than tiles are the list items so `ListView.builder` still virtualizes at
  two or more columns. The screen gates the split; the content width sets the capacity.

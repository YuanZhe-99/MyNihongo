# lib/features/vocab/views/vocab_page.dart

`VocabPage` is the third tab: a searchable, level-filterable browser over `ContentCatalog.vocab`.
It watches `contentCatalogProvider`, shows a spinner or an error line while the catalog is
unavailable, and otherwise renders a header (search field, level chips, count) above an
adaptive-column list of tiles; tapping a tile opens a bottom sheet with the full entry. It shares its
chips, badges and example rendering with the grammar page through `reference_widgets.dart`. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md) and
[../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `VocabPage.new` | constructor | B | Create a vocabulary page instance. |
| `VocabPage.createState` | method | B | Create the mutable state object for this widget. |
| `_VocabPageState.dispose` | method | B | Release the search controller. |
| `_VocabPageState.build` | method (widget build) | B | Build the vocabulary browser around the catalog provider's three states. |
| [`_VocabPageState._buildList`](#buildlist) | method (widget helper) | A | Build the filtered, adaptive-column list with its header as a virtualized `ListView.builder`. |
| `_VocabPageState._buildHeader` | method (widget helper) | B | Build the search field, level chips, and result count. |
| `_VocabPageState._buildTile` | method (widget helper) | B | Build one vocabulary tile: headword, reading/romaji line, one meaning line, level badge. |
| `_VocabPageState._showDetail` | method (widget helper) | B | Show a word's full entry in a modal bottom sheet. |

## Documentation

### `Widget _buildList(BuildContext context, AppLocalizations l10n, ContentCatalog catalog)` <a id="buildlist"></a>

- **Kind:** method of `_VocabPageState`
- **Source:** `lib/features/vocab/views/vocab_page.dart`
- **Purpose:** Turn the catalog plus the current filter into a scrolling, adaptive-column list.
- **Inputs:** `context`, `l10n`, `catalog`.
- **Returns:** A `ListView.builder`.
- **Side effects:** None.
- **Algorithm:**
  1. Filter `catalog.vocab` by the selected level and the trimmed, lowercased query
     (`VocabEntry.matches`).
  2. `columns = referenceColumnCount(screen, referenceContentWidth(screen.width))`;
     `rowCount = listRowCount(filtered.length, columns)`.
  3. Item 0 is the header; when the filter matches nothing, item 1 is the empty-state line;
     otherwise items 1…rowCount are `adaptiveTileRow`s, each centred inside `pageMaxContentWidth`.
- **Usage:** Called from `build` in the provider's `data` branch.
- **Notes:** Rows rather than tiles are the list items so `ListView.builder` still virtualizes at
  two or more columns. The screen gates the split; the content width sets the capacity. The
  reading line is dropped for kana-only words so a tile does not repeat itself.

# lib/features/drills/views/weakness_report_page.dart

Shows the learner what their recent papers say they are worst at.

Three tables, coarsest first: section, then 大問, then the individual words and grammar points. That
is the order a learner can act on — "listening is the weak one" changes what they practise tonight,
and "this word keeps catching me" changes nothing until they know which section to open.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Show what recent papers say the learner is worst at. |
| `WeaknessReportPage` | class | B | What to work on next. |
| `WeaknessReportPage` constructor | constructor | B | Create the page. |
| [`build`](#build) | method | A | Build the three tables, or say there is nothing yet. |
| `_heading` | method | B | Render one table heading. |
| `_nothingWeak` | method | B | Say that nothing in this table qualifies yet. |
| `_row` | method | B | Render one tallied row with its accuracy bar. |
| [`_itemRow`](#itemrow) | method | A | Render one weak catalog item, named from the catalog. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the three tables, or say there is nothing yet.
- **Inputs:** `context`, `ref`.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state.
- **Algorithm:** Watch `weaknessReportProvider` and the catalog. An empty report is a centered
  sentence; otherwise a `ListView` of the basis line and the three tables, each row a title, its
  score and a determinate accuracy bar.
- **Usage:** The `/weakness` route, reached from the Learn card.
- **Notes:** An empty report **says what would fill it** rather than only that it is empty: a screen
  reached from a button, showing nothing and explaining nothing, reads as broken. The same applies
  within a table — a heading over blank space is worse than a heading over one sentence saying the
  report names something only once it has been asked enough times and got wrong.

  The report is recomputed on every build from the last few attempts, so a weakness the learner has
  fixed disappears by itself rather than needing to be cleared.

  The accuracy bar is a **determinate** `LinearProgressIndicator`. It has a known value, so it
  settles; the indeterminate one never does, and that cost this project a hung test once already.

### `Widget _itemRow(BuildContext context, AppLocalizations l10n, ThemeData theme, ContentCatalog? catalog, MapEntry<String, WeaknessTally> entry)` <a id="itemrow"></a>

- **Kind:** method
- **Purpose:** Render one weak catalog item, named from the catalog.
- **Inputs:** `context`, `l10n`, `theme`, the `catalog`, and the tallied `entry`.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** `resolveStudyItemLabel` on the id, then `_row` with its title and subtitle.
- **Usage:** The third table.
- **Notes:** Internal helper used within this file only. Resolved through the same function the sync
  conflict dialog and the study calendar use, so a word retired in favour of a JMdict-keyed id still
  names its entry here. An id the catalog no longer has falls back to itself rather than vanishing —
  the learner did get it wrong, and a row that disappears because of a content edit is a worse
  answer than an ugly one.

The 大問 are named in Japanese, from `DrillTypeName.jaName`, with the localized section name beneath.
These are the official headings from jlpt.jp, so a learner comparing this screen with a real paper is
comparing the same words.

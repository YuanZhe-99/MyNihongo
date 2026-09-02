# lib/shared/widgets/reference_widgets.dart

Small widgets the vocabulary and grammar pages share so the two look the same: the JLPT level badge,
the level filter chips, the example-sentence block, and the empty-results line. See
[../../../features/content-catalog.md](../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `levelChip` | top-level function | B | Render a small JLPT level badge. |
| `levelFilterRow` | top-level function | B | Render the `Wrap` of choice chips: all levels, then N5 to N1; exactly one selected. |
| `exampleList` | top-level function | B | Render a titled block of example sentences with readings and translations for the locale. |
| `emptyResults` | top-level function | B | Render the empty-state line shown when a filter matches nothing. |

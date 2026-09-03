# lib/shared/widgets/adaptive_tile_grid.dart

Two helpers that lay a flat list of tiles out in `columns` columns as `Row`s of `Expanded` children
— deliberately not a `GridView`, so a caller feeding them from `ListView.builder` over
`listRowCount` rows keeps virtualization and left-to-right, top-to-bottom order. Short final rows
are padded with empty cells so the remaining tiles keep their width. Used by the vocabulary and
grammar pages. See [../../../adaptive-layout.md](../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `adaptiveTileRow` | top-level function | B | Build one row of a multi-column list, filled left to right, padded at the end. |
| `adaptiveTileRows` | top-level function | B | Build a list's children as rows; at one column returns the tiles untouched. |

`listColumnsButton` builds the popup menu that picks a list's column count. It is hidden rather
than disabled when the window can only carry one column, so a phone never shows a control that
could not do anything. The menu always offers every count up to `listMaxColumns`, so a preference
can be set while folded and take effect on unfolding; the check mark tracks the stored preference,
while what renders is that preference clamped to what fits.

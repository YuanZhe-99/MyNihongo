# lib/features/content/models/jlpt_level.dart

`JlptLevel` enumerates the five JLPT levels, easiest first (`n5` … `n1`), with the user-facing
label (`N5` … `N1`, never localized) and a case-insensitive parser used by the content models. See
[../../../../data-formats.md](../../../../data-formats.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `JlptLevel.label` | getter | B | Return the label users know the level by, `N5` through `N1`. |
| `JlptLevel.parse` | static method | B | Parse a level from content JSON in any case; null for anything unrecognized. |

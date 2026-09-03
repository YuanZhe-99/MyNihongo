# lib/features/kana/models/kana_note.dart

The extra teaching notes a kana needs beyond its romaji: stroke count, the point to make about it,
and the kana it is confused with. Prose rather than table data, so it is an asset
(`assets/content/kana_notes.json`) and gets translated. Only kana that need a note have one.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Carry the extra teaching notes a kana needs beyond its romaji. |
| `KanaNote` | constructor | B | Create a kana note instance. |
| `KanaNote.fromJson` | static method | B | Parse one note from content JSON. |
| `KanaNote.mapFromJson` | static method | B | Parse the whole notes file into a map keyed by kana progress id. |

Every field is optional: a note with only a confusable list is still useful, and one with only a
hint is the common case. A malformed note is skipped rather than failing the file, and
`content_catalog_test.dart` catches a bad entry before release.

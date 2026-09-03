# lib/features/content/models/vocab_entry.dart

`VocabEntry` is one vocabulary item from the bundled content: id, JLPT level, headword (kanji when
present, else the reading), reading, optional romaji, part-of-speech tags, language-keyed meanings,
and examples. `fromJson` returns null when the id, level or reading is missing. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `VocabEntry.new` | constructor | B | Create a vocab entry instance. |
| `VocabEntry.hasKanji` | getter | B | Report whether the headword differs from the reading, which decides whether a tile shows a reading line. |
| `VocabEntry.fromJson` | static method | B | Parse from content JSON; null when the id, level, or reading is missing; `kanji` may be absent. |
| `VocabEntry.matches` | method | B | Test whether a lowercased query is a substring of the headword, reading, romaji, or any gloss in any language. |

Two fields arrived with the JMdict import (`PLAN.md` M1.2): `aliases`, the ids the entry used to
ship under, which `ContentCatalog.vocabById` resolves to the same entry so no user's progress is
orphaned; and `common`, true when JMdict marks the chosen written form as common, used to order
suggestions and never to hide an entry.

# lib/features/content/models/vocab_entry.dart

`VocabEntry` is one vocabulary item from the bundled content: id, JLPT level, headword (kanji when
present, else the reading), reading, optional romaji, part-of-speech tags, language-keyed meanings,
the readings of any Japanese definitions, and examples. `fromJson` returns null when the id, level or reading is missing. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `VocabEntry.new` | constructor | B | Create a vocab entry instance. |
| `VocabEntry.hasKanji` | getter | B | Report whether the headword differs from the reading, which decides whether a tile shows a reading line. |
| `VocabEntry.fromJson` | static method | B | Parse from content JSON; null when the id, level, or reading is missing; `kanji` may be absent; a `jaReading` list travels beside `meanings.ja`, one reading per sense. |
| `VocabEntry.matches` | method | B | Test whether a lowercased query is a substring of the headword, reading, romaji, or any gloss in any language. |

Two fields arrived with the JMdict import (M1.2): `aliases`, the ids the entry used to
ship under, which `ContentCatalog.vocabById` resolves to the same entry so no user's progress is
orphaned; and `common`, true when JMdict marks the chosen written form as common, used to order
suggestions and never to hide an entry.

`jaReadings`, from the JSON key `jaReading`, holds the hiragana readings of the Japanese
definitions, one per sense, parallel to `meanings['ja']` — which `LocalizedStrings` cannot carry
readings for. It is empty when there is no Japanese definition, and a sense with no reading here
is drawn without furigana. `import_vocab.dart` writes both from `assets/content/vocab_ja.json`
(see `applyJapaneseOverlay`); the vocabulary tile and detail sheet draw them with `FuriganaText`.

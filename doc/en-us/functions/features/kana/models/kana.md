# lib/features/kana/models/kana.dart

The kana catalog: `KanaScript`, `KanaEntry`, `KanaRow`, the column-header constants, the three
`const` tables (`kanaBasicRows`, `kanaVoicedRows`, `kanaYoonRows`), and two helpers over them.
Pulled out of the page so quizzes, pronunciation practice and the progress catalog share one
source. A kana's progress id is `kana:<hiragana>`. See
[../../../../features/kana-reference.md](../../../../features/kana-reference.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | The kana catalog — every hiragana/katakana pair the app teaches, in the three tables the page draws. |
| `KanaEntry.new` | constructor | B | Create a kana entry (hiragana, katakana, romaji). |
| `KanaEntry.progressId` | getter | B | Return the stable id progress records use: `kana:` plus the hiragana form. |
| `KanaEntry.kana` | method | B | Return this entry in the requested script. |
| `KanaEntry.matches` | method | B | Test whether a lowercased query is a substring of the hiragana, katakana, or lowercased romaji. |
| `KanaRow.new` | constructor | B | Create a labeled row; `null` slots mark combinations that do not exist. |
| `allKanaEntries` | top-level function | B | List every kana entry across the three tables, once each, in table order. |
| `matchingKanaEntries` | top-level function | B | Trim and lowercase a query and return every matching entry; empty for a blank query. |
| `kanaEntryById` | top-level function | B | Resolve a `kana:` progress id back to its table entry, through a lazily built map. |

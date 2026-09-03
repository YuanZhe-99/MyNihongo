# lib/features/sentence/services/lexicon.dart

A surface-to-entry index over the bundled catalog. `ContentCatalog` looks entries up by id, which is
what the reference pages need; reading Japanese text needs the opposite direction — given a run of
characters, which entries could it be.

Today it serves pronunciation scoring, where a recognizer that answered in kanji has to be rewritten
to kana before a comparison means anything. The sentence analyser in `PLAN.md` M2.3 extends this
same class rather than building a second index, which is why it already lives under
`features/sentence/`.

Consumers: `pronunciation_practice_sheet.dart` (builds one once the catalog is loaded),
`pronunciation_scorer.dart` (uses it).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `Lexicon` | class | B | A surface-to-entry index over the catalog. |
| `build` | static method | B | Build the index from the bundled catalog. |
| `entryCount` | getter | B | How many entries the index covers, for diagnostics and tests. |
| `byHeadword` | method | B | Find the entries written exactly this way. |
| `byReading` | method | B | Find the entries read this way, in either script. |
| [`toKana`](#tokana) | method | A | Rewrite text into kana, resolving kanji through the catalog. |

## Documentation

### `String toKana(String text)` <a id="tokana"></a>

- **Kind:** method
- **Purpose:** Turn a recognizer's answer into something comparable with a kana reading.
- **Inputs:** `text` — typically what a speech recognizer returned.
- **Returns:** The same text with every recognized headword replaced by its reading. Still needs
  normalizing; see the notes.
- **Side effects:** None.
- **Algorithm:** Greedy longest match from the left, capped at the longest headword in the catalog.
- **Usage:** `PronunciationScorer._resolve`.
- **Notes:** A recognizer answers a word in kanji where the item is written in kanji, and comparing
  that with a kana reading character by character would score a perfect reading at zero. A span the
  catalog does not know is copied through **unchanged**, so an unresolved kanji still costs edits
  rather than disappearing — the score stays honest about what could not be read. Normalization is
  left to the caller and applied to the whole result at once, because the long-vowel mark takes its
  vowel from the mora before it and normalizing inside the loop would drop it.

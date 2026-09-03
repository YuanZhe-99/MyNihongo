# lib/features/kana/models/romaji.dart

Romanizes a kana string in Hepburn, the spelling the app teaches. Written for Phase 2's
pronunciation scoring, which compares what the recognizer heard against what the item says, and
used today to romanize content that ships without a `romaji` field.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Romanize a kana string in Hepburn. |
| `_buildTable` | top-level function | B | Build the lookup the first time it is needed. |
| `romajiFromKana` | top-level function | A | Romanize a kana string. |

### `romajiFromKana`

- **Purpose:** Romanize a kana string.
- **Inputs:** `kana` — hiragana, katakana, or a mix.
- **Returns:** `String` — lowercase Hepburn romaji.
- **Side effects:** Builds the lookup table on the first call.
- **Algorithm:** Greedy longest-match against a table built from `allKanaEntries()`, so きょ becomes
  `kyo` rather than `kiyo`. Three rules are not in the tables and are handled here: っ doubles the
  next consonant (がっこう to `gakkou`, with ち's `ch` doubling as `t`), ー repeats the previous
  vowel (コーヒー to `koohii`), and a character with no kana reading is copied through unchanged.
- **Usage:** Content without a `romaji` field, and Phase 2's scoring.
- **Notes:** Long vowels are written out rather than macronned, matching the `romaji` fields the
  content ships and what a learner would type. This is a kana romanizer, not a general
  transliterator: kanji passes through untouched, so a mixed string degrades rather than throwing.
  Both scripts map to the same romaji, so katakana needs no second table.

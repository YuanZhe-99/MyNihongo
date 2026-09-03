# lib/features/content/services/content_links.dart

The links between kana, vocabulary and grammar that let a learner move sideways through the catalog
instead of only up and down it. Pure string matching, tested on the real catalog by
`test/content_links_test.dart`. See
[../../../../features/content-catalog.md](../../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Find the links between kana, vocabulary and grammar. |
| `grammarMatchCore` | top-level function | B | Strip a pattern down to the text a sentence would contain. |
| `effectiveMatchForms` | top-level function | B | Decide which literal strings mark a point in a sentence. |
| `_isUsableForm` | top-level function | B | Report whether a derived form is specific enough. |
| [`grammarPointsInExample`](#grammarpointsinexample) | top-level function | A | Find the grammar points an example sentence demonstrates. |
| [`vocabInExamples`](#vocabinexamples) | top-level function | A | Find the vocabulary a grammar point's examples use. |
| [`vocabStartingWithKana`](#vocabstartingwithkana) | top-level function | A | Find example words that begin with one kana. |

Japanese has no word boundaries, so these are substring matches, not parsing. That is deliberate
for Phase 1: a real tokenizer is Phase 3's sentence analyser, and until it exists a wrong link is
cheaper than no links. Every function caps its result, because a page shows a handful of chips and
a scan over 7,700 entries has to stay off the critical path.

### `grammarPointsInExample` <a id="grammarpointsinexample"></a>

- **Purpose:** Find the grammar points an example sentence demonstrates.
- **Inputs:** `catalog`, `example`, `limit` (3).
- **Returns:** `List<GrammarPoint>`, longest match first.
- **Side effects:** None.
- **Algorithm:** For each point, take the longest of its match forms that the sentence contains;
  sort by that length, then by id for a stable order.
- **Usage:** The chips under a word's examples.
- **Notes:** Longest first because a sentence containing 〜てもいいです also contains です, and the
  longer point is the one worth linking. Matching runs against the sentence and its kana reading,
  so a point written in kana is still found in a sentence written with kanji.

### `vocabInExamples` <a id="vocabinexamples"></a>

- **Purpose:** Find the vocabulary a grammar point's examples use.
- **Inputs:** `catalog`, `point`, `limit` (12).
- **Returns:** `List<VocabEntry>` in catalog order.
- **Side effects:** None.
- **Algorithm:** Scan the catalog once; a kanji headword matches the sentences, a reading of at
  least two kana matches the readings.
- **Usage:** The chips under a grammar point's examples.
- **Notes:** Only words at or below the point's own level, because a sentence teaching N5 grammar
  should not send the reader to an N1 word. The two-kana floor keeps あ and を from matching
  everything.

### `vocabStartingWithKana` <a id="vocabstartingwithkana"></a>

- **Purpose:** Find example words that begin with one kana.
- **Inputs:** `catalog`, `kana`, `limit` (8).
- **Returns:** `List<VocabEntry>`, easiest and most common first.
- **Side effects:** None.
- **Algorithm:** Match on the reading, then sort by level, then by whether JMdict calls the word
  common, then by reading.
- **Usage:** The kana detail sheet.
- **Notes:** Matched on the reading, not the written form, because the point is to show the kana
  being read. The ordering is what makes the sheet useful: without it a beginner tapping あ would
  be offered the first N1 entry in file order.

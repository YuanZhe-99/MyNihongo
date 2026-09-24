# lib/features/sentence/services/lexicon.dart

A surface-to-entry index over the bundled catalog and the function words.

`ContentCatalog` looks entries up by id, which is what the reference pages need. Reading Japanese
text needs the opposite direction — given a run of characters, which entries could it be — and that
is what this provides, in constant time, built once per app run.

It serves three callers: pronunciation scoring, which uses `toKana` to rewrite a recognizer's kanji
answer into a comparable reading; the typed-sentence quiz mode, which uses it the same way on what
the learner typed; and the sentence analyser, which uses the rest.

Consumers: `pronunciation_scorer.dart`, `tokenizer.dart`, `deinflector.dart`,
`sentence_analyzer.dart`, `pronunciation_practice_sheet.dart`, `question_generator.dart`,
`quiz_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ConjClass` | enum | B | How a word conjugates: the nine godan rows, ichidan, the two irregular verbs, and adjectives. |
| `LexEntry` | class | B | One catalog entry prepared for de-inflection: lemma, reading, class, stem, category, tags. |
| `LexEntry.viaReading` | field | B | Whether this candidate was found through its kana reading rather than its written form. |
| `LexEntry.asReadingMatch` | method | B | Copy this entry, marked as found through its reading. |
| `Lexicon` | class | B | The index itself. |
| [`build`](#build) | static method | A | Build the index from the catalog and the word table. |
| `entryCount` | getter | B | How many entries the index covers, for diagnostics and tests. |
| `byHeadword`, `byReading` | methods | B | Find catalog entries by written form or by reading. |
| `entriesAt` | method | B | Find the prepared entries at one surface — the tokenizer's dictionary lookup. |
| `conjugablesForStem` | method | B | Find conjugable entries whose stem is exactly this. |
| `functionWordsAt` | method | B | Find the function words written exactly this way. |
| [`toKana`](#tokana) | method | A | Rewrite text into kana, resolving kanji through the catalog. |
| [`_classOf`](#classof) | static method | A | Work out how a catalog entry conjugates. |
| [`_categoryOf`](#categoryof) | static method | A | Work out which lemma category a catalog entry produces. |

## Documentation

### `static Lexicon build(ContentCatalog catalog, {FunctionWordTable functionWords})` <a id="build"></a>

- **Kind:** static method
- **Purpose:** Prepare every lookup the analyser and the scorer need.
- **Inputs:** The catalog, and optionally the function word table.
- **Returns:** `Lexicon`.
- **Side effects:** None.
- **Algorithm:** One pass over the vocabulary building five maps: by written form, by reading, by
  prepared entry, conjugables by stem, and the function words.
- **Usage:** `lexiconProvider`, and direct calls in tests.
- **Notes:** Tens of milliseconds over 7,700 entries, built once per run — which is why it is a
  provider rather than something a page does in `initState`.

  A surface reached **through its reading** is indexed as a separate object marked `viaReading`, so
  a caller can never forget which index it came from. The tokenizer prices that case higher: あう
  written in kana could be 会う or 合う, and a match that had to go through the reading is a weaker
  claim than one that matched the written form.

### `String toKana(String text)` <a id="tokana"></a>

- **Kind:** method
- **Purpose:** Turn a recognizer's answer into something comparable with a kana reading.
- **Inputs:** `text` — typically what a speech recognizer returned.
- **Returns:** The same text with every recognized headword replaced by its reading. Still needs
  normalizing; see the notes.
- **Side effects:** None.
- **Algorithm:** Greedy longest match from the left, capped at the longest headword in the catalog.
  Where one spelling has several entries, the first the catalog marks common gives the reading (私
  is わたくし in an uncommon entry listed before the common わたし); otherwise the first.
- **Usage:** `PronunciationScorer._resolve`; the typed-sentence quiz mode, through
  `AnswerChecker.toKana` and `QuestionGenerator._typedSentence`.
- **Notes:** A recognizer answers a word in kanji where the item is written in kanji, and comparing
  that with a kana reading character by character would score a perfect reading at zero. A span the
  catalog does not know is copied through **unchanged**, so an unresolved kanji still costs edits
  rather than disappearing — the score stays honest about what could not be read. Normalization is
  left to the caller and applied to the whole result at once, because the long-vowel mark takes its
  vowel from the mora before it and normalizing inside the loop would drop it.

### `static ConjClass _classOf(VocabEntry entry)` <a id="classof"></a>

- **Kind:** static method
- **Purpose:** Work out how a word conjugates.
- **Inputs:** One catalog entry.
- **Returns:** `ConjClass`.
- **Side effects:** None.
- **Algorithm:** The part-of-speech tags decide the family; a godan verb's row comes from the last
  kana of the **reading**.
- **Usage:** `build`.
- **Notes:** The reading rather than the written form, because a verb written with kanji ends in
  okurigana that the reading already spells out, and a kana-only entry has no other source.

  A noun tagged `suru-verb` is deliberately **not** given a verb conjugation class: what the catalog
  holds is the noun, not the compound verb, and inventing the compound would put words in the
  dictionary that the catalog cannot open.

### `static TokenCategory _categoryOf(VocabEntry entry)` <a id="categoryof"></a>

- **Kind:** static method
- **Purpose:** Work out which kind of word a catalog entry is.
- **Inputs:** One catalog entry.
- **Returns:** `TokenCategory`.
- **Side effects:** None.
- **Algorithm:** Tag tests in a fixed order.
- **Usage:** `build`.
- **Notes:** That order carries two decisions. Noun comes **before** counter, numeral, prefix and
  suffix, because a word tagged both noun and counter is overwhelmingly a noun, and a counter
  reading needs a number in front of it — which the chunker can see and this cannot.

  The catalog's `auxiliary` tag is not read at all: it is given to a dozen ordinary verbs that are
  auxiliary only after a て-form, and reading it here would stop them being verbs everywhere else.

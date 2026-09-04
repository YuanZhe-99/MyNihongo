# lib/features/content/services/furigana_aligner.dart

Recovers which kana belong to which characters, so a reading can be printed over the kanji it
describes. The catalog stores one reading per word and one per sentence and no per-character
mapping, so this file derives it from the two strings, and returns null rather than guessing
whenever it cannot: a wrong alignment prints kana over the wrong character and teaches a reading
that does not exist.

The algorithm, its cases and its cost are in
[`../../../../algorithms/furigana-alignment.md`](../../../../algorithms/furigana-alignment.md).

Consumers: `shared/widgets/furigana_text.dart`, `shared/widgets/reference_widgets.dart`,
`features/vocab/views/vocab_page.dart`, `features/sentence/widgets/token_chips.dart`,
`features/quiz/services/question_generator.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `FuriganaSegment` | class | B | One run of the surface with the reading that belongs to it. |
| `FuriganaSegment.isRuby` | getter | B | Whether this run needs ruby printed over it. |
| `_readsItself` | function | B | Decide whether a character reads itself. |
| `_fold` | function | B | Reduce one character to the form the reading spells it in. |
| `_runs` | function | B | Split a surface into runs that need a reading and runs that do not. |
| [`alignFurigana`](#align) | function | A | Attach a reading to every run of a surface. |
| [`_match`](#match) | function | A | Place one run and everything after it. |
| [`readingRangeFor`](#range) | function | A | Find the kana that belong to one span of the surface. |
| [`surfaceReadingOfToken`](#token) | function | A | Read a token as it stands, not as its lemma. |
| `_kuruStem` | function | B | Read the kanji of 来る for the form the token is in. |

## Documentation

### `List<FuriganaSegment>? alignFurigana(String surface, String? reading)` <a id="align"></a>

- **Kind:** function
- **Purpose:** Attach a reading to every run of a surface.
- **Inputs:** `surface` as written; `reading` in kana.
- **Returns:** `List<FuriganaSegment>?` — null when no alignment fits.
- **Side effects:** None.
- **Algorithm:** The surface is split into runs of characters that read themselves — kana,
  punctuation, spaces, the quiz blank — and runs that do not: kanji, digits, Latin, the repeat
  marks. The first kind are anchors, each of which must appear in the reading, in order, at exactly
  the position reached. The second kind take at least one kana per character and at most what the
  runs after them still need, tried shortest first, backtracking until the whole reading is used.
- **Usage:** Every caller that draws Japanese with a reading beside it.
- **Notes:** Consuming the reading completely is what separates 母は/ははは, where 母 is はは, from
  花は/はなは, where 花 is はな. No local rule can. A surface with no kanji aligns trivially into
  one segment with no ruby, which is what lets a caller pass any word without testing it first.

### `bool _match(...)` <a id="match"></a>

- **Kind:** function
- **Purpose:** Place run `index` and everything after it.
- **Inputs:** The two strings, the runs, the run index, the position reached in the reading, the
  output list, and the states already shown to fail.
- **Returns:** `bool`.
- **Side effects:** Fills the output list.
- **Algorithm:** Depth-first over run lengths, memoized on the run and the position.
- **Usage:** `alignFurigana` only.
- **Notes:** Internal helper used within this file only. Without the memo the search is exponential
  in the number of kanji runs, and a sentence with a dozen of them hangs the frame that draws it.
  The state that decides the rest of the search is only which run and how far into the reading, so
  a pair that failed once can never succeed later.

### `({int start, int end})? readingRangeFor(...)` <a id="range"></a>

- **Kind:** function
- **Purpose:** Find the kana that belong to one span of the surface.
- **Inputs:** Aligned `segments`, and a code-unit span of the surface they came from.
- **Returns:** The matching span of the reading, or null.
- **Side effects:** None.
- **Algorithm:** Run boundaries map directly; a kana run maps one code unit to one, so a span may
  also start or end inside one.
- **Usage:** `question_generator.dart`, to blank the same word out of a sentence's reading as was
  blanked out of the sentence.
- **Notes:** A span that ends inside a kanji run has no answer, because half of とうきょう is not
  the reading of 東, and the question is then drawn without ruby rather than with a guess.

### `String? surfaceReadingOfToken(Token token)` <a id="token"></a>

- **Kind:** function
- **Purpose:** Read an analysed token as it stands rather than as its lemma.
- **Inputs:** `token`.
- **Returns:** `String?` — the reading of `token.surface`, or null.
- **Side effects:** None.
- **Algorithm:** The kanji reading comes from aligning the lemma with the token's reading; the kana
  tail comes from the surface as written. 来る is decided by the recovered forms.
- **Usage:** `token_chips.dart`.
- **Notes:** The token's reading is the dictionary form's, so 食べ carries たべる, because that is
  what de-inflection matches against. Printing it would show a る the sentence does not contain. A
  form chain that does not decide 来る leaves the chip unread, which is honest; く where the
  learner is about to say き is not.

# lib/features/kana/models/kana_text.dart

Reduces Japanese text to comparable hiragana, and splits it into morae. Written for pronunciation
scoring, where the two sides of the comparison legitimately arrive in different scripts: a
recognizer answers in katakana or kanji depending on the platform, and the catalog stores hiragana
readings.

The module depends on nothing but `dart:core`, so every rule is directly unit-testable
(`test/kana_text_test.dart`). The rules themselves are derived in
[../../../../algorithms/pronunciation-scoring.md](../../../../algorithms/pronunciation-scoring.md).

Consumers: `pronunciation_scorer.dart`, `lexicon.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`toHiragana`](#tohiragana) | top-level function | A | Reduce a Japanese string to bare hiragana. |
| [`splitMorae`](#splitmorae) | top-level function | A | Split hiragana into morae. |
| `_isDroppable` | top-level function | B | Decide whether a character carries no pronunciation. |
| `_Characters.characters` | extension getter | B | Iterate a string one code point at a time. |

## Documentation

### `String toHiragana(String text)` <a id="tohiragana"></a>

- **Kind:** top-level function
- **Purpose:** Put both sides of a comparison into the same shape.
- **Inputs:** Any mix of hiragana, katakana, kanji, ASCII and marks.
- **Returns:** Hiragana, with kanji left as they are.
- **Side effects:** None.
- **Algorithm:** Full-width ASCII to ASCII; the long-vowel mark to the vowel of the mora before it;
  katakana to hiragana by code-point shift; whitespace and punctuation dropped.
- **Usage:** `PronunciationScorer.score`, `Lexicon.build` and `Lexicon.byReading`.
- **Notes:** **Kanji are deliberately untouched.** This function cannot read them; a caller that
  needs kana for a kanji surface resolves it through `Lexicon.toKana` first, and an unresolved kanji
  survives into the mora list where it costs an edit rather than disappearing.

### `List<String> splitMorae(String hiragana)` <a id="splitmorae"></a>

- **Kind:** top-level function
- **Purpose:** Produce the unit pronunciation is actually scored in.
- **Inputs:** The output of [`toHiragana`](#tohiragana).
- **Returns:** One entry per mora.
- **Side effects:** None.
- **Algorithm:** A small kana joins the mora before it; everything else opens a new one.
- **Usage:** `PronunciationScorer.score`.
- **Notes:** The sokuon and the moraic nasal are **not** in the small-kana set, on purpose: both are
  full morae, and a learner who drops either has made exactly the mistake the score exists to show,
  so it has to cost something.

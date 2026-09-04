# lib/features/quiz/services/distractors.dart

Chooses the wrong options a multiple-choice question offers.

A distractor has to be **wrong but plausible**. Too easy and the question tests
nothing; accidentally also correct and the question is unanswerable. Each rule
narrows first and widens only if it must, and every one of them can return short
— the caller drops the question rather than padding it with something arbitrary.

The reasoning per catalog is in
[`../../../../features/quizzes.md`](../../../../features/quizzes.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Choose the wrong options a question offers. |
| `distractorCount` | top-level constant | B | How many wrong options a choice question offers. |
| `Distractors` | class | B | Pick wrong answers that are wrong for the right reasons. |
| `forMeaning` | method | B | Find words whose meanings could be confused with this one's. |
| `forWriting` | method | B | Find words whose written form could be confused with this one's. |
| [`forKana`](#forkana) | method | A | Find kana that could be confused with this one. |
| `_confusable` | method | B | Read the confusable kana a note names. |
| `_sameRow` | method | B | Find the kana sharing a row with this one. |
| [`_widen`](#widen) | method | A | Take candidates from progressively looser filters. |

## Documentation

### `List<KanaEntry> forKana(KanaEntry entry, {int count})` <a id="forkana"></a>

- **Kind:** method
- **Purpose:** Find kana that could be confused with this one.
- **Inputs:** The kana being asked about, and how many wrong options to find.
- **Returns:** `List<KanaEntry>`, possibly short.
- **Side effects:** None.
- **Algorithm:** The catalog's own `confusableWith` list first, then the same row, then anything —
  deduplicating **by romaji** throughout.
- **Usage:** All three kana modes.
- **Notes:** The confusable list is the point: シ and ツ, ソ and ン, ぬ and め are the mistakes a
  learner is actually at risk of, so they are the wrong answers worth offering. Deduplicating by
  romaji rather than by kana is what stops じ and ぢ appearing together — both are "ji", and a romaji
  question offering both has two correct answers.

### `List<VocabEntry> _widen(List<bool Function(VocabEntry)> filters, int count)` <a id="widen"></a>

- **Kind:** method
- **Purpose:** Take candidates from progressively looser filters.
- **Inputs:** The filters, best first, and how many to take.
- **Returns:** `List<VocabEntry>`, possibly short.
- **Side effects:** None.
- **Algorithm:** Walk the filters in order; shuffle each one's matches and take from them until the
  count is reached.
- **Usage:** `forMeaning` and `forWriting`.
- **Notes:** Widening rather than failing on the first filter is a deliberate trade. A same-level,
  same-part-of-speech distractor is the best kind, but a question with two options is worse than one
  with a slightly easy third — so the filters loosen rather than the question being dropped. Each
  filter's matches are shuffled so the same word does not always draw the same three wrong answers.

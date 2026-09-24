# lib/features/quiz/services/answer_checker.dart

Decides whether an answer is right.

Kept apart from the widgets because marking is not a rendering concern, and
because a typed answer is more forgiving than string equality: a learner on a
Japanese keyboard produces kana, one without an IME produces romaji, and neither
is wrong. What is **not** forgiven is a different reading — が and か are
different words, and normalizing them together would teach that they are not.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Decide whether an answer is right. |
| `QuizAnswer` | sealed class | B | What the learner did about one question. |
| `ChoiceAnswer`, `TypedAnswer`, `OrderAnswer` | classes | B | The three answer shapes. |
| `AnswerChecker` | class | B | Mark answers; `const AnswerChecker({toKana})`. |
| `toKana` | field | B | Optional; reads the words of a typed sentence into kana through the catalog (`Lexicon.toKana`). A function rather than a lexicon, so this file imports nothing from the sentence analyser. |
| `check` | method | B | Mark one answer. |
| `_checkTyped` | method | B | Mark a typed answer against both accepted spellings; a `grammarTypeSentence` question goes to `_checkSentence`. |
| `_checkSentence` | method | B | Mark a typed sentence: `toHiragana` of the answer against the accepted set, then, with `toKana`, the answer read into kana. Accepts a homophone in the wrong kanji; never romaji. |
| `_checkOrder` | method | B | Mark an ordering by whether its positions ascend. |

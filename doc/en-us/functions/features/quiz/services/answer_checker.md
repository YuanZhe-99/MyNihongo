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
| `AnswerChecker` | class | B | Mark answers. |
| `check` | method | B | Mark one answer. |
| `_checkTyped` | method | B | Mark a typed answer against both accepted spellings. |
| `_checkOrder` | method | B | Mark an ordering by whether its positions ascend. |

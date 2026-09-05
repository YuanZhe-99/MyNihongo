# lib/features/quiz/widgets/answer_panes.dart

The controls a question is answered with: four options, a text field, or
fragments to tap into order.

One widget rather than three at the call site — the three answer shapes are the
only thing that varies, and which of them applies is a property of the question.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`AnswerPane`](#answerpane) | class | A | Build whichever controls a question needs. |
| `_ChoicePane` | class | B | One option per row, the whole row tappable. |
| `_option` | method | B | Build one option button, marked once the answer is in. |
| `_TypedPane` | class | B | A text field for a typed reading. |
| `_OrderPane` | class | B | Fragments to tap into order. |
| `_add`, `_remove` | methods | B | Move a fragment into or out of the sentence. |

## Documentation

### `class AnswerPane` <a id="answerpane"></a>

- **Kind:** class
- **Purpose:** Build the controls a question is answered with.
- **Inputs:** The question, whether it is locked, and callbacks for composing and submitting.
- **Returns:** A widget.
- **Side effects:** None.
- **Algorithm:** Switch on the question's `AnswerKind`, keyed by the question's identity —
  `questionId` where it has one, else `itemId`, plus the mode.
- **Usage:** `QuizRunner`.
- **Notes:** The key matters: composing state — a typed string, a partial ordering — is discarded
  when the question changes rather than carried into the next one, which is what the key buys. It
  includes `questionId` because a paper asks several different questions about one word: keyed on the
  item alone, the second of them would inherit the first's half-typed answer.
  Composing and submitting are separate callbacks so a mis-tap is correctable: choosing an option
  selects it, and a second action commits it. Ordering is done by tapping rather than dragging,
  because a drag target the width of a fragment is a hard gesture on a phone and a tap is reversible
  by tapping again.

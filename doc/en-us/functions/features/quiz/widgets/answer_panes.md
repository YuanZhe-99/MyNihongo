# lib/features/quiz/widgets/answer_panes.dart

The controls a question is answered with: four options, a text field, or
fragments to tap into order.

One widget rather than three at the call site — the three answer shapes are the
only thing that varies, and which of them applies is a property of the question.

The composed choice and ordering are not kept here. They arrive as `pending` from
[`QuizRunner`](quiz_runner.md), and every tap reports through `onChanged`, so a tap
and a keyboard shortcut change the same state through the same path.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`remainingFragments`](#remainingfragments) | top-level function | A | List the ordering fragments not placed yet, in the order the chips show them. |
| [`AnswerPane`](#answerpane) | class | A | Build whichever controls a question needs. |
| `_ChoicePane` | class | B | One option per row, the whole row tappable; the selection is read from `pending`. |
| `_ChoicePane._option` | method | B | Build one option button, numbered for a keyboard when asked, and marked once the answer is in. |
| `_KeyNumber` | class | B | The digit that selects an option, drawn quietly and excluded from semantics. |
| `_TypedPane` | class | B | A text field for a typed reading or, for Type the sentence (`sentence`), a whole sentence, holding its own focus node. |
| `_TypedPaneState.initState` | method | B | Request keyboard focus for the field after the first frame. |
| `_OrderPane` | class | B | Fragments to tap into order; the ordering is read from `pending`. |
| `_OrderPane._remove` | method | B | Take a fragment back out of the sentence. |

## Documentation

### `List<int> remainingFragments(QuizQuestion question, QuizAnswer? pending)` <a id="remainingfragments"></a>

- **Kind:** top-level function
- **Purpose:** List the fragments of an ordering question that are not placed yet.
- **Inputs:** The `question` and the learner's `pending` answer.
- **Returns:** Option indices, left to right as the remaining chips are drawn.
- **Side effects:** None.
- **Algorithm:** Every option index not in `pending`'s order, in index order.
- **Usage:** `_OrderPane`, to draw the chips and number them, and `QuizRunner`'s digit shortcuts.
- **Notes:** One function for both on purpose: key `3` must mean the third chip on screen, and the
  numbers change as fragments are placed.

### `class AnswerPane` <a id="answerpane"></a>

- **Kind:** class
- **Purpose:** Build the controls a question is answered with.
- **Inputs:** The question, the `pending` answer composed so far, whether it is locked, callbacks
  for composing and submitting, and `showKeyHints` to number options and fragments for a keyboard.
- **Returns:** A widget.
- **Side effects:** None.
- **Algorithm:** Switch on the question's `AnswerKind`, keyed by the question's identity —
  `questionId` where it has one, else `itemId`, plus the mode.
- **Usage:** `QuizRunner`.
- **Notes:** The key matters for the typed field: its half-typed string is discarded when the
  question changes rather than carried into the next one. It includes `questionId` because a paper
  asks several different questions about one word. The choice and the ordering need no such reset
  here, because the runner clears `pending` when it moves on.
  Composing and submitting are separate callbacks so a mis-tap is correctable: choosing an option
  selects it, and a second action commits it. Ordering is done by tapping rather than dragging,
  because a drag target the width of a fragment is a hard gesture on a phone and a tap is reversible
  by tapping again. **The typed field requests focus itself** after its first frame rather than
  using `autofocus`: `autofocus` is ignored once anything in the route holds focus, and after a
  choice question the runner's shortcut node does. With key hints on, the first nine options and
  remaining fragments carry the digit that selects them; the number is excluded from semantics,
  because a screen reader already announces the option.

# lib/features/quiz/widgets/quiz_runner.dart

Runs one session on screen: the question, the answer controls, and the feedback
between them. Splits into two panes when the window is the right shape and stacks
otherwise; the gate is `canSplitLayout`, the same one every other split uses.

The question pane can carry a header above the question and a leading widget for whatever the
question is about, and the marking on screen can be switched off — the three things a timed JLPT
block needs that a practice quiz does not.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`QuizRunner`](#runner) | class | A | Run one session on screen. |
| `passageTextOf` | field | B | The text of whatever the question is about, for the AI actions under a wrong answer. |
| `_submit` | method | B | Submit the composed answer through the session's own `checker`, asking the model for a second opinion on a typed one; the model is shown the catalog's answer (`answerText`), not a normalized key. |
| `_advanceIfUnmarked` | method | B | Move straight on where the answer is not being marked on screen. |
| `_continue` | method | B | Move past the feedback to the next question. |
| `_syncFocus` | method | B | Give the shortcut node keyboard focus unless an unanswered typed question needs it. |
| [`_bindings`](#bindings) | method | A | Build the keyboard shortcuts that apply right now. |
| `_compose` | method | B | Record the answer being composed; the one path a tap and a key both take. |
| `_placeFragment` | method | B | Place the n-th remaining fragment of an ordering question. |
| `_digitKeys`, `_numpadKeys` | top-level constants | B | The keys `1` to `9` on the number row and on the keypad. |
| `build` | method | B | Build the question and its answer controls, split or stacked, with the desktop key hint, inside the shortcuts. |
| [`_feedback`](#feedback) | method | A | Say whether the answer was right, and what it was. |
| `_QuestionPane` | class | B | The half of the screen that asks the question: header, progress, leading, prompt. |
| `didUpdateWidget` | method | B | Re-speak when the question changes, compared on `questionId` as well as item and mode. |
| [`_instruction`](#instruction) | method | A | Say in words what the learner is being asked to do. |
| `_modeInstruction` | method | B | Say what this mode asks, for a question that did not say. |
| `QuizModeLabel` | extension | B | Name a quiz mode in the learner's language. |

## Documentation

### `class QuizRunner` <a id="runner"></a>

- **Kind:** class
- **Purpose:** Run one session on screen.
- **Inputs:** The `session` to run and `onFinished`; optionally a `header` above the question, a
  `leadingBuilder` for whatever the question is about, whether to `showFeedback`, and the
  `questionPaneWidth` to use when the layout splits.
- **Returns:** A widget.
- **Side effects:** None of its own; marking an answer is the session's side effect.
- **Algorithm:** Build the question pane and the answer column, then either stack them in a `ListView`
  or lay them side by side with the question pane at `questionPaneWidth(content)`.
- **Usage:** `quiz_page.dart`, and the exam page.
- **Notes:** The session is owned by the page above, which disposes it. The four optional parameters
  exist for the exam page and default to what every existing caller already got, so a practice quiz
  is unchanged.

  `leadingBuilder` is a builder rather than a widget because it changes with the question, and the
  runner is the only thing that knows which question is on screen. `showFeedback` is false in a mock,
  where the paper is marked at the end: being told after every question is how practice teaches and
  is also the thing a real exam most conspicuously does not do, so the same runner has to be able to
  do neither. `questionPaneWidth` defaults to `quizQuestionPaneWidth`; the exam page passes
  `drillPassagePaneWidth`, because a reading question needs more room than a word does.

### `Widget _feedback(BuildContext context, AppLocalizations l10n, QuizOutcome outcome, QuizQuestion question)` <a id="feedback"></a>

- **Kind:** method
- **Purpose:** Say whether the answer was right, and what the right answer was.
- **Inputs:** The marked outcome and the question it was about.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** An icon and a word in the primary or error colour, plus the expected answer when the
  learner was wrong, the model's comment where there was one, and `WhyWrong` about the option they
  picked, then a `GrammarPointChip` for any question filed under a `grammar:` id.
- **Usage:** Between the answer controls and the Continue button, and only when `showFeedback` is on.
- **Notes:** The right answer is always shown after a wrong one. An item is re-queued within the
  session, and one re-queued without being told the answer is guessed at again rather than learnt.
  Where `showFeedback` is off there is nothing to read between questions, so `_advanceIfUnmarked`
  moves straight on rather than spending the learner's clock on a Continue button.

  The chip is the quiz's first link back to the catalog it draws from. It is shown right or wrong,
  because a question answered correctly is the other moment a learner wants to read the rule, and by
  then the point is on screen anyway.

### `Map<ShortcutActivator, VoidCallback> _bindings(QuizQuestion question, bool answered)` <a id="bindings"></a>

- **Kind:** method
- **Purpose:** Build the keyboard shortcuts that apply to the question on screen right now.
- **Inputs:** The current `question` and whether it is `answered`.
- **Returns:** A map for the `CallbackShortcuts` that wraps both layouts.
- **Side effects:** None.
- **Algorithm:** Nothing while the model is grading. Once answered, Enter continues. On an
  unanswered typed question, nothing. Otherwise: digits `1`–`9` (number row and keypad) choose an
  option or place the n-th remaining fragment; Backspace takes the last fragment back when there is
  one; Enter checks once something is composed; `R` replays the question's audio when it has some
  and a Japanese voice exists; `S` skips a generated question.
- **Usage:** `build`, once, around both the stacked and the split layout, so every page hosting a
  runner gets the same keys.
- **Notes:** **A binding exists only when its action is possible.** A `CallbackShortcuts` consumes a
  key whenever the activator matches, so returning early inside a callback would still swallow it.
  That is why an unanswered typed question binds nothing: a digit must reach the field as text, and
  Enter must reach the field's `onSubmitted`. Key events travel from the focused node towards the
  root, so the shortcuts sit *outside* the `Focus` they listen through; the other way round they
  would never hear anything. `_syncFocus` gives that node focus after every session change, except
  on an unanswered typed question, whose field takes focus itself.

### `String _instruction(AppLocalizations l10n)` <a id="instruction"></a>

- **Kind:** method
- **Purpose:** Say what the learner is being asked to do.
- **Inputs:** `l10n`.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** Return the question's own `instruction` where it has a non-empty one; then the
  empty string when the question is `authored`, so nothing is drawn above it; otherwise delegate to
  `_modeInstruction`, which switches on the mode and gives a generated question the blank-filling
  line rather than `grammarPattern`'s own.
- **Usage:** The grey line above the prompt in `_QuestionPane`.
- **Notes:** Every mode says it in words rather than relying on the shape of the question, because a
  conjugation blank and a particle blank look identical. A question that brought its own instruction
  keeps it: a paper writes the instruction per 大問, and two 大問 that look identical on screen ask
  for different things — 「＿の言葉の読み方」 and 「＿の言葉の書き方」 are the same sentence with the
  same span marked. Splitting the mode switch out into `_modeInstruction` is what keeps the two rules
  from being tangled: one answers "what did this question ask for", the other "what does this mode
  ask for", and only the second has a default.

  A unit's own question and a generated one are both filed under `QuizMode.grammarPattern`, so the
  mode introduced neither correctly: 「这句用了哪个语法点？」 sat above a blank the model had written.
  The first now shows no line at all and the second shows a blank-filling one, with the point it was
  written to test named above it by `GrammarPointLine`.

`passageTextOf` is the same idea as `leadingBuilder` at one remove: the page that drew the paper has
the passages, and the runner does not, so it hands over a callback rather than a map. What comes back
is the plain Japanese of whatever the question was about and whether it was spoken, and it goes
straight into `WhyWrong` — which is what puts "where does the passage say otherwise?" under a 読解
question and "which line had the answer?" under a 聴解 one. A runner given none simply shows the
explanation it always showed.

# lib/features/quiz/widgets/why_wrong.dart

The explanation shown under a wrong answer.

Two layers, in this order. The catalog's own explanation of the grammar point, or a hand-written
question's own note, is shown first and always — it is the app's answer and it is right. Only if
on-device AI is switched on do buttons appear offering more words about **this** wrong choice, which
is the thing the catalog cannot say because it does not know what was picked.

With the switch off there is no button and no hint: the quiz is exactly what it was before the AI
existed, which is the rule the sentence lab already follows.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `WhyWrong` | class | B | The explanation shown under a wrong answer. |
| `WhyWrong` constructor | constructor | B | Explain one wrong answer. |
| `question`, `chose`, `passage`, `spoken` | fields | B | The question, what was picked, the text it was about, and whether that text was spoken. |
| `createState` | method | B | Create the widget's state. |
| `_WhyWrongState` | class | B | Holds the two requests that can be in flight. |
| [`build`](#build) | method | A | Build the deterministic note and, when possible, the buttons. |
| `_note` | method | B | Find what the app itself can say about this question. |
| `_ask` | method | B | Ask the model why this choice was wrong. |
| [`_askPassage`](#askpassage) | method | A | Ask what in the passage — or in the spoken lines — settles this question. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the deterministic note and, when possible, the buttons.
- **Inputs:** `context`.
- **Returns:** `Widget`.
- **Side effects:** None until a button is tapped.
- **Algorithm:** The catalog's note, then the why-wrong button and its card, then — only where a
  `passage` was given — the passage button and its card.
- **Usage:** `QuizRunner` under a wrong answer, and `ExamResultsView` for every question the paper
  got wrong.
- **Notes:** The two generated answers are kept **apart**, in two cards with two dismiss buttons,
  because they answer different questions: one is about the choice, the other is about the text. A
  learner may want both on screen at once.

  The deterministic note is not conditional on anything. A device with no model shows exactly what
  the app has always shown, and every button here is additional.

### `Future<void> _askPassage()` <a id="askpassage"></a>

- **Kind:** method
- **Purpose:** Ask what in the passage — or in the spoken lines — settles this question.
- **Inputs:** None; reads the widget's question, choice and passage.
- **Returns:** None.
- **Side effects:** Runs a model on the device; rebuilds.
- **Algorithm:** Guard on having a passage, a choice inside the options and a correct answer, then
  build either `forListeningReview` or `forContradiction` and run it.
- **Usage:** The passage button.
- **Notes:** Internal helper used within this file only. Two tasks share this method because they
  share every input and differ only in what is being asked about the same text: a reading question is
  answered from the passage, and a listening question is answered from the line that carried it. The
  task's rules do the rest — the reading task forbids bringing in anything outside the passage, and
  the listening task asks what is easy to miss when hearing rather than reading.

  The text handed over is **the text the learner has on screen**, which for listening means the
  transcript is only ever sent after the question has been answered. Before that, showing it would
  replace the exercise.

  `chose` must be a real option, so the results screen passes what the learner actually picked rather
  than null. An ordering answer has no single index and yields none, and the choice-specific buttons
  stay hidden rather than pointing at the wrong fragment.

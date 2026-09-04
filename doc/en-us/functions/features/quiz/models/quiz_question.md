# lib/features/quiz/models/quiz_question.dart

One question, in a shape every mode and every answer widget can share.

One class rather than a subclass per mode. The modes differ in what they show and
where the options come from, not in how they are answered — there are only three
answer shapes — so a sealed hierarchy would have put thirteen classes behind
three widgets.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | One question, in a shape every mode shares. |
| [`QuizMode`](#quizmode) | enum | A | Every way the app can ask about something. |
| `AnswerKind` | enum | B | How a question is answered: choice, typed or order. |
| `vocabQuizModes`, `kanaQuizModes`, `grammarQuizModes` | constants | B | The modes each catalog supports. |
| `listeningQuizModes` | constant | B | The modes that speak rather than show. |
| `QuizQuestion` | class | B | One question. |
| `answerText` | getter | B | The correct option's text, for showing after a wrong answer. |

## Documentation

### `enum QuizMode` <a id="quizmode"></a>

- **Kind:** enum
- **Purpose:** Name every way the app can ask about something.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None.
- **Usage:** The generator, the mode switches in Settings, and the `quizModes` preference.
- **Notes:** **The name of each value is a compatibility contract.** It is what the `quizModes`
  preference stores, so renaming a value silently turns a mode the learner switched off back on. A
  value added later is switched on by default for everybody, which is what an absent preference key
  means and what somebody who never opted out would expect.

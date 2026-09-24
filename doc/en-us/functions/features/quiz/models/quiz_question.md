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
| `parsedQuizModes` | constant | B | The modes that need the sentence analyser and are dropped without it. |
| `lexiconAidedQuizModes` | constant | B | The modes that use the sentence analyser when it is loaded but still work without it: Type the sentence, which marks more fairly with the lexicon. |
| `listeningQuizModes` | constant | B | The modes that speak rather than show. |
| [`translationQuizModes`](#translation) | constant | A | The modes whose material is a translation of a Japanese sentence, and so are dropped for a Japanese reader. |
| `quizModeWorksIn` | function | B | Say whether a mode can be asked in this UI language; false only for `translationQuizModes` under a Japanese UI. |
| [`selectableQuizModes`](#selectable) | constant | A | The modes the learner may switch off, which is what "every mode" means in the preference. |
| [`QuizQuestion`](#question) | class | A | One question. |
| `answerText` | getter | B | The correct option's text, for showing after a wrong answer. |

## Documentation

### `enum QuizMode` <a id="quizmode"></a>

- **Kind:** enum
- **Purpose:** Name every way the app can ask about something.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None.
- **Usage:** The generator, the mode switches in Settings, the `quizModes` preference, and
  `DrillQuestion.toQuizQuestion`.
- **Notes:** **The name of each value is a compatibility contract.** It is what the `quizModes`
  preference stores, so renaming a value silently turns a mode the learner switched off back on. A
  value added later is switched on by default for everybody, which is what an absent preference key
  means and what somebody who never opted out would expect.

  `QuizMode.drill` is the exception and is **not selectable**. The other seventeen are ways this app
  can invent a question about a catalog entry, and the learner turns them on and off. `drill` means
  the question was written for a paper and says for itself what it wants, so switching it off would
  only mean refusing to sit the paper — which is what not opening it already does.

  `grammarTypeSentence` (0.5.3) is the one free-response mode: a meaning is shown and the learner
  types the Japanese sentence. See `AnswerChecker` for how it is marked.

### `const selectableQuizModes` <a id="selectable"></a>

- **Kind:** top-level constant
- **Purpose:** Name the modes the learner may switch off.
- **Inputs:** None; the union of `vocabQuizModes`, `kanaQuizModes` and `grammarQuizModes`.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None.
- **Usage:** The mode switches in Settings, and everywhere "all modes are on" has to be spelled out.
- **Notes:** `QuizMode.drill` is deliberately absent. This set — **not** `QuizMode.values` — is what
  "every mode is on" means in the preference, so a learner who has switched nothing off keeps the
  empty-set default and still gets any mode a later build adds.

### `const translationQuizModes` <a id="translation"></a>

- **Kind:** top-level constant
- **Purpose:** Name the modes whose material is a translation of a Japanese sentence.
- **Inputs:** None; `grammarOrder`, `grammarSentenceToMeaning`, `grammarMeaningToSentence` and
  `grammarTypeSentence`.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None; `quizModeWorksIn(mode, locale)` is false exactly for these modes under a
  locale whose language is `ja`.
- **Usage:** Through `quizModeWorksIn`: `QuizPage._enabledModes` drops them for a Japanese reader,
  and `QuizModesPage` shows them switched off with the reason (`quizModeNeedsTranslation`).
- **Notes:** A catalog example carries an English and a Chinese translation and no Japanese one,
  because the sentence is already Japanese. Matching a sentence to its English meaning, ordering
  fragments against an English gloss, or typing the sentence an English meaning describes, is not
  an exercise a Japanese UI can offer without showing the language the learner chose not to read.
  They are shown as unavailable rather than silently missing
  — the same rule the listening modes follow on a device without a Japanese voice. The stored
  `quizModes` preference is not changed: switching the UI back out of Japanese brings them back as
  they were.

### `class QuizQuestion` <a id="question"></a>

- **Kind:** class
- **Purpose:** Hold one question in the shape every mode and every answer widget shares.
- **Inputs:** All fields; `itemId`, `mode`, `kind` and `prompt` are required and the rest default to
  absent or empty.
- **Returns:** An immutable value.
- **Side effects:** None.
- **Algorithm:** None; `answerText` is the only derived value.
- **Usage:** `QuestionGenerator`, `QuestionBank`, `AiQuestionGenerator`, `DrillQuestion.toQuizQuestion`;
  read by `QuizSession`, `QuizRunner` and `AnswerPane`.
- **Notes:** The fields that carry a rule of their own:

`itemId` is the catalog id the answer is recorded against, which is not always what the question
shows — a particle question shows a sentence but is about a grammar point.

`questionId` is the drill question's own id, and is null for a generated question: two questions
built from one catalog entry are the same question asked twice. A drill question needs one because a
paper asks several different questions about the same word, and the session scores each of them
separately — see `QuizSession.scoreKey`.

`instruction` is what this particular question asks, when the mode label does not say it. A drill
file writes its own because a paper does: 「＿＿の　ことばは　どう　よみますか」 is not the same
request as 「（　）に　なにを　いれますか」, and both look like `QuizMode.grammarParticle` to the
runner.

`passageId` is only an id: the passage itself belongs to the file, and several questions share one,
so the page joins it back.

`generated` says a model wrote this question rather than the catalog. A generated question is shown
with the same label every other generated thing carries, and **its answer never reaches the
scheduler**: the spacing of a word's reviews must not depend on a question that might be wrong about
the word.

`authored` says the question's own `prompt` is already the whole question. A unit file writes its
questions the way a person asks them — 「部屋に猫が＿。」, 「哪一句是礼貌的说法？」 — so the mode's
own line above it would introduce a different question. Every authored unit question is filed under
`QuizMode.grammarPattern` whatever it asks, which is why the mode cannot be trusted to introduce it
and this flag suppresses the line instead.

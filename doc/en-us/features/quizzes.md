# Quizzes

Seventeen ways of asking about the same catalog, one session runner, and the
spaced-repetition schedule underneath them. The quiz is where an answer actually
reaches [`learning-progress.md`](learning-progress.md); before M3.2 the scheduler
existed and nothing called it.

## The modes

| Catalog | Mode | Shows | Answered by |
|---|---|---|---|
| Vocabulary | Japanese to meaning | the word | picking one of four |
| | Meaning to Japanese | the meaning | picking one of four |
| | Reading to written form | the reading | picking one of four |
| | Written form to reading | the word | picking one of four |
| | Listening | nothing — it is spoken | picking one of four |
| | Type the reading | the word | typing |
| | Fill in the word | an example sentence with the word blanked | picking one of four |
| Kana | Kana to romaji | the kana | picking one of four |
| | Romaji to kana | the romaji | picking one of four |
| | Listening | nothing — it is spoken | picking one of four |
| Grammar | Fill in the particle | the sentence with a blank | picking one of four |
| | Choose the form | the sentence with a blank | picking one of four |
| | Order the pieces | the translation | tapping fragments into order |
| | Pick the grammar point | the sentence | picking one of four |
| | Sentence to meaning | a whole sentence | picking one of four meanings |
| | Meaning to sentence | a meaning | picking one of four sentences |
| | Type the sentence | a meaning | typing the Japanese sentence |

Each is a switch in **Settings › Learning › Quiz modes**. The last one on cannot
be switched off: a quiz with no modes opens empty and looks broken rather than
configured.

## A question is generated or it is not

`QuestionGenerator` returns null far more often than it returns a question, and
that is the design rather than a failure. Most words have no kanji, so the two
written-form modes do not apply to them. Most have no example sentence. A word at
a thin level may have no three plausible distractors. Rather than choosing a mode
up front and hoping, the generator is asked for each enabled mode in a shuffled
order and the first that produces something wins.

Four things are dropped rather than approximated:

- **Listening modes on a device with no Japanese voice.** A question nobody can
  hear has no answer, so `QuizPage` removes them before generating anything.
- **The parsing modes without the sentence analyser.** Fill in the particle,
  Choose the form, Order the pieces and Fill in the word need a parsed sentence
  (`parsedQuizModes`). The analyser is only awaited when one of them, or Type the
  sentence (`lexiconAidedQuizModes`, which marks more fairly with it but works
  without it), is enabled, because building the lexicon over 7,700 entries costs
  tens of milliseconds and a kana quiz has no use for it.
- **The translation-based grammar modes under a Japanese UI.** Ordering fragments against a
  meaning, matching a sentence to its meaning either way, and typing the sentence a meaning
  describes, use the English or Chinese
  translation of a catalog example as their material, and a Japanese reader is shown no
  translation of Japanese. `translationQuizModes` lists them; the quiz page drops them, and the
  quiz-mode page shows their switches off with the reason.
- **Any question whose options are not four distinct strings.** The last check
  before a choice question is assembled: two identical options mean two correct
  answers, and no distractor rule can rule that out for every mode on its own.

## Distractors

A wrong option has two ways to fail. The obvious one is being accidentally
correct — a synonym, or じ and ぢ both offered as "ji". The quiet one is being
too easy: a noun among verbs, or a three-kanji compound among two-kana words, is
eliminated on shape alone and the question tests nothing.

- **Meanings.** Same level and same part of speech, common words first; widened
  to the level, then to the catalog, only if that cannot fill four. A word
  sharing any meaning with the answer is excluded outright.
- **Written forms.** Same level, preferring words that share a character or have
  a reading of the same length. Homophones are excluded, or the reading question
  would have two answers.
- **Kana.** The catalog's own `confusableWith` list first — シ and ツ, ソ and ン,
  ぬ and め — because those are the mistakes a learner is actually at risk of.
  Then the same row, then anything. Deduplicated **by romaji**, which is what
  keeps じ and ぢ from appearing together.
- **Particles.** From a fixed list of the fifteen an N5 learner meets, not from
  the whole function-word table: a rare particle as a wrong option is not a
  mistake anybody would make, so it gives the answer away.
- **Inflected forms.** Other real forms of the same word, written by
  `Conjugator`. Every option is Japanese and only one fits the sentence.
- **Grammar points.** Same-level points **whose own forms do not appear in the
  sentence**. Without that check a sentence ending in です would offer 〜です as a
  wrong answer to a question about something else in it.

## Conjugation, forwards

The analyser only ever ran de-inflection backwards, because that is what parsing
needs. A quiz needs the other direction, so `Conjugator` writes the polite,
negative, past and te forms from a dictionary form and a conjugation class. Both
directions share the row tables in `godan_rows.dart`, so a quiz can never grade
against a table the parser disagrees with.

It is deliberately not a general engine: four forms, and null for anything else.
A distractor that is not a real form of the word teaches the wrong thing, and a
question with no correct answer is worse still.

**An inflected form is several tokens.** The analyser splits 食べます into 食べ,
carrying the recovered masu stem, and ます as its own auxiliary — that split is
what makes parsing tractable. So a conjugation question spans the verb token plus
every auxiliary attached behind it, and is skipped when the conjugator cannot
reproduce exactly what the sentence says.

## Marking

- **Choices** are marked by index.
- **Typed readings** accept the kana or the romaji: a learner on a Japanese
  keyboard produces one, a learner without an IME produces the other, and neither
  is wrong. `toHiragana` folds katakana, long vowels and full-width characters
  first. What is *not* folded is a different reading — が and か are different
  words.
- **Orderings** are right when the chosen positions ascend, and the expected
  answer shown afterwards is the fragments joined, which is the sentence.
- **Typed sentences** (Type the sentence) accept the catalog's sentence as written or its
  reading, both through `toHiragana`, which also drops punctuation and spaces — a missing 「。」 or a
  word in katakana is not a mistake. When the sentence analyser is loaded, the quiz page gives the
  session a checker holding its lexicon, and the answer is also read into kana word by word
  (`Lexicon.toKana`) and compared again: 私 marks the same as the わたし the catalog wrote. That
  also accepts a homophone in the wrong kanji; the mode asks for a sentence, not for spelling.
  Romaji is not accepted, and a sentence longer than 30 characters is never asked
  (`maxTypedSentenceLength`). With on-device AI on, a different wording that means the same is the
  model's second opinion to accept — see [`ai-assist.md`](ai-assist.md#marking-a-typed-answer).
  Nothing is spoken: the sentence is the answer.

## A session

`QuizSession` owns the queue and the score and nothing else. Writing progress is
a callback rather than a dependency, so the file imports no storage and a test
can watch exactly what it would have written.

- **Only the first answer to an item is recorded.** SM-2 grades how well
  something was recalled; an item answered right on the third attempt within one
  minute was not recalled.
- **A wrong item comes back within the session**, at the back of the queue, at
  most twice. That repetition is where the learning happens, and the cap is what
  stops one stubborn item keeping a session open forever.
- **The right answer is always shown after a wrong one.** An item re-queued
  without being told the answer is guessed at again rather than learnt.
- **The score is first-try accuracy**, and the summary names the items that were
  wrong through the catalog rather than by id.

The answer is recorded as it happens rather than at the end, so an app killed
mid-session keeps what was already answered. The sync scheduler debounces, so the
extra saves do not become extra uploads.

### Questions that arrive mid-session

`QuizSession.append` adds a question to a running session and grows the total, so
the progress line stays honest. Two things use it, and both are optional extras:
a unit session asks the on-device model for up to three questions once it is
already on screen (see [`ai-assist.md`](ai-assist.md)), and any such question is
`generated`.

**A generated question never calls `onFirstAnswer`.** It may be wrong, and a
wrong question must not be allowed to move a real review interval — see
[`learning-progress.md`](learning-progress.md). It is also labelled above the
prompt, before it is read.

### What introduces a question

The runner writes one line above the prompt, and it comes from three places in
order: the question's own `instruction` when it has one, which is how a drill
question carries its 大問's wording; nothing at all when the question is
`authored`, because a unit file writes its questions as a person would ask them
and a line above 「哪一句是礼貌的说法？」 would introduce a different question;
and otherwise the quiz mode's own line.

Every authored unit question and every generated one is filed under
`QuizMode.grammarPattern` whatever it actually asks, so the mode cannot be
trusted to introduce either. A generated question is a blank to fill, so it gets
that line and, above it, the grammar point it was written to test with its
meaning — the premise of the question rather than its answer. On an authored
pattern question the point **is** the answer, so it is never named beforehand.
After any grammar question is answered, a chip opens the point's own page.

### A question with an id of its own

Everything above scores by **item**, which is right when the app invented the
question: two generated questions about one grammar point are the same question
asked twice.

A JLPT drill question is different. A paper asks several genuinely different
questions about one word, so a drill question carries a `questionId` and is
scored under that; scored by item, the second and third question about 会う
would never have counted. The schedule still hears about each item once, on the
first question that asked about it.

A session can also be told **not to re-queue** (`requeue: false`), which is what
a timed paper does — a paper whose length depended on how well it was going
could not be scored against a fixed composition — and can be made to **forfeit**,
recording whatever is left as `answered: false` rather than as wrong. See
[`jlpt-practice.md`](jlpt-practice.md).

Two latent bugs came out of that change, both of which had been sitting in the
generated-question path unnoticed because no session had ever asked two
questions about one item in a row: the answer pane was keyed by item and mode,
so the first question's selection carried into the second, and the re-speak
check compared the same pair, so the second question was silent. Both now
compare the question.

## Where a quiz starts

| From | Asks about |
|---|---|
| Learn › Today › Start reviews | everything due, most overdue first |
| Learn › Today › Learn new items | today's new-item allowance |
| Kana chart › quiz action | every row, in the script currently shown |
| Vocabulary › quiz action | the level the list is filtered to |
| Grammar › quiz action | the level the list is filtered to |

`/quiz` is a route outside the tab shell, entered with `context.push` and a
`QuizConfig` as its `extra` — the same shape as the sentence lab, and for the
same reason: it is something entered with a purpose and left when it is finished,
not a place to browse. Leaving mid-session asks first, but only once something
has been answered.

## Readings in a question

A prompt carries furigana wherever the reading is not the thing being asked. Japanese to meaning
prints the reading over the word; picking the grammar point prints the sentence's own reading; a
fill-in-the-blank question blanks the reading at the same span it blanked the sentence, or the kana
above the sentence would answer the question.

**Written form to reading and typing the reading never do**, and neither does a listening question
before it is answered. Printing the answer above the prompt is not a display choice.

Where the reading cannot be aligned — see
[`../algorithms/furigana-alignment.md`](../algorithms/furigana-alignment.md) — the prompt falls
back to the subtitle line the quiz used before, so the reading is shown exactly once either way.

## Layout

Question pane fixed on the left, answers on the right, when `canSplitLayout`
says the window is the right shape; stacked otherwise. See
[`../adaptive-layout.md`](../adaptive-layout.md) for the rule and what it costs.

## From a keyboard

A learner at a keyboard answers a whole session without the mouse. The keys belong to
`QuizRunner`, so the practice quiz, a unit session, a checkpoint and a mock paper all get them.

| Key | Does | Only when |
|---|---|---|
| `1`–`9` | Choice: select option *n*. Ordering: place the *n*-th remaining fragment | Not on a typed question, where a digit is text |
| `Backspace` | Take the last placed fragment back | Ordering, with something placed |
| `Enter` | Check, then Continue — the one filled button | Something is composed, or the answer is in. On an unanswered typed question Enter belongs to the field, which submits |
| `R` | Replay the question's audio | The question has audio and a Japanese voice exists |
| `S` | Skip a generated question | Generated, and not answered yet |
| `Esc` | Leave, through the same confirmation as the back button | Unchanged |

On a desktop the options and remaining fragments carry their digit, and one line under the Check
button names the keys. A phone shows neither; a tablet with a keyboard still gets the keys, it is
just not told about them. The numbers change as fragments are placed, and the key follows the
number on screen.

**The keys exist only when their action does.** A key a shortcut matches is always consumed, so a
digit bound on a typed question would never reach the field. The runner therefore builds its
bindings per question and per state, rather than binding everything and ignoring some of it. Focus
follows the same rule: after every change of question the quiz's own key handler takes focus,
except on an unanswered typed question, where the field takes it so typing works at once.

Around a session, the button a keyboard user reaches for next already has the focus: Start on a
mock paper's start card, Done on the summary and on a paper's results, and **Cancel** in both leave
dialogs, so that Enter pressed by habit never walks out of a timed paper.

Scenario branch choices, writing practice and the tabs have no shortcuts yet.

# Quizzes

Thirteen ways of asking about the same catalog, one session runner, and the
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
| Kana | Kana to romaji | the kana | picking one of four |
| | Romaji to kana | the romaji | picking one of four |
| | Listening | nothing — it is spoken | picking one of four |
| Grammar | Fill in the particle | the sentence with a blank | picking one of four |
| | Choose the form | the sentence with a blank | picking one of four |
| | Order the pieces | the translation | tapping fragments into order |
| | Pick the grammar point | the sentence | picking one of four |

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

Three things are dropped rather than approximated:

- **Listening modes on a device with no Japanese voice.** A question nobody can
  hear has no answer, so `QuizPage` removes them before generating anything.
- **Grammar modes without the sentence analyser.** Three of the four need a
  parsed example. The analyser is only awaited when such a mode is enabled,
  because building the lexicon over 7,700 entries costs tens of milliseconds and
  a kana quiz has no use for it.
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

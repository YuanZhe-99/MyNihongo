# JLPT practice

Questions written in the shape of the real paper, one section at a time. The
Learn tab's JLPT card is the way in: it names the learner's target level, lists
the four sections, and says for each one how many questions it holds or why it
cannot be practised yet.

This is not a reproduction of a JLPT paper. The past papers are © The Japan
Foundation and JEES, and nothing here is copied from one. What is copied is the
**shape**: the 大問, their proportions, the block timings and the scoring
groups, all of which JEES publishes.

## What the paper is made of

`assets/content/drills/structure.json` holds one entry per level: the timed
blocks and their minutes, the scoring groups, and how many questions each 大問
has. It carries its own `source` field naming the pages it came from, because
these are somebody else's published numbers and a screen that shows them should
be able to say whose.

The numbers are **approximate on purpose**. JEES says the composition varies
from session to session, so the file is a composition target rather than a
promise about any one paper.

| Level | Blocks | Groups | Questions on a full paper |
|---|---|---|---|
| N5 | 20 / 40 / 30 min | 言語知識・読解, 聴解 | 67 |
| N4 | 25 / 55 / 35 min | 言語知識・読解, 聴解 | 85 |
| N3 | 30 / 70 / 40 min | 言語知識, 読解, 聴解 | 102 |
| N2 | 105 / 50 min | 言語知識, 読解, 聴解 | 107 |
| N1 | 110 / 55 min | 言語知識, 読解, 聴解 | 108 |

## The 大問

Twenty-one of them, each belonging to one of the four sections. The **key** is
what a content file writes and is a compatibility contract; the **section** is
what it is scored under.

| Section | 大問 |
|---|---|
| 文字・語彙 | `kanji-reading` `orthography` `word-formation` `context` `paraphrase` `usage` |
| 文法 | `form-selection` `sentence-composition` `text-grammar` |
| 読解 | `short` `mid` `long` `integrated` `thematic` `info` |
| 聴解 | `task` `point` `outline` `expression` `quick-response` `integrated-listening` |

Three deliberate deviations from the paper, each because the app's own
machinery assumes something the paper does not:

- **即時応答 gets four options; the paper gives three.** The answer pane, the
  distractor rules and the gate all assume four everywhere.
- **発話表現 describes the scene in text.** The paper shows a picture, and
  there are no pictures in this app's content.
- **A mock plays each listening item once.** Practice plays it as often as the
  learner likes. That is the paper's rule, and practising against a gentler one
  teaches a habit the exam punishes.

## How a question is shown

A vocabulary or grammar question shows its Japanese; a reading or listening
question shows its *question*, and the Japanese is the passage beside it.

The part of the sentence a question turns on is written once, as `blank`, and
rendered according to the 大問:

- a **gap** — `（　　）` — for 文脈規定, 語形成, 文の文法1, 文章の文法: the
  options fill it;
- a **marked span** — `【…】` — for 漢字読み, 表記, 言い換え類義: the options
  are about something already there.

Rendering one as the other changes the question, which is why it is a property
of the 大問 and not a field somebody sets per question.

**Furigana is withheld for 漢字読み and 表記**, because in those two the
reading *is* the answer. Everywhere else the reading is printed over the kanji
as it is everywhere else in the app.

Each question also carries its own instruction line, in every language, because
a paper writes one per 大問 and two 大問 that look identical on screen ask for
different things: 「＿の言葉の読み方」 and 「＿の言葉の書き方」 are the same
sentence with the same span marked.

## Scoring, and what a question is scored as

A paper asks several different questions about one word. So a drill question is
scored under **its own id**, not its item's — scored by item, the second and
third question about 会う would never have counted.

The spaced-repetition schedule works the other way round. It hears about each
**item** once per session, on the first question that asked about it: SM-2
grades one recall, and the second question about a word was primed by the
first, so it says nothing about how well the word was known.

A paper **does not ask a question again because it was got wrong**. Re-queueing
is how practice teaches and is exactly what an exam must not do: a paper whose
length depended on how well it was going could not be scored against a fixed
composition.

## Choosing which questions to ask

`DrillSampler` draws in three tiers: **never asked first, then least recently
asked, then whatever is left**, shuffled within each tier. A learner who has
seen forty of a level's sixty questions is shown the twenty they have not, and
once the pool is exhausted the oldest is the one they are most likely to have
forgotten. Shuffling *within* a tier rather than across the whole pool is the
whole point — a plain shuffle would offer yesterday's question as readily as an
unseen one.

Reading and listening are drawn **by passage, not by question**. A 中文 carries
three questions; drawing questions independently would put one question from
each of three passages on a short paper, which is three texts to read for three
marks — three times the work of the paper it is imitating.

A 大問 with fewer questions than the composition asks for yields what it has.
The results say how many were asked, so a short section is visible rather than
quietly padded out of another 大問.

## Sections that cannot be practised

Both are shown **disabled with the reason beside them**, never hidden. A
learner who cannot find 読解 practice has no way to tell whether it does not
exist or they have not found it.

- A level whose section has no shipped file yet says so. Levels are written one
  release at a time.
- Listening on a device with no Japanese voice says so. A question nobody can
  hear has no answer, which is the same rule the app's own listening quiz modes
  follow.

## The mock exam

The same questions, on a clock, marked at the end. Three things separate it from
practice, and each is the paper's own rule rather than a design choice:

- **A block starts when the learner says so.** A paper opens on a start card
  naming the part, its sections, its minutes and its question count. Starting a
  clock somebody has not looked at is not a test of Japanese, and the real thing
  has a break between parts.
- **Nothing is marked until the paper is in.** No verdict, no explanation, no
  Continue button — answering advances. Being told after each question is how
  practice teaches and is the thing a real exam most conspicuously does not do.
- **A listening item plays once.** Practice plays it as often as the learner
  likes; a mock does not, because the exam does not.

A block that runs out of time is handed in with whatever is left recorded as
**unanswered** — not wrong. A block whose questions all get answered is handed
in early, and the recorded time is then the time actually spent.

### The clock measures attention, not hours

Time is counted only while the block is on screen and the app is in the
foreground. A learner who takes a phone call has not spent that time on the
paper; one who leaves it overnight has not lost the paper. Leaving the page or
backgrounding the app stops the clock and writes the paper down; coming back
picks it up with the same time left — and re-checks the deadline first, because
a phone that slept past it has to find out on waking rather than resume a block
that ended hours ago.

**Started and running are different states.** The clock stops every time a
dialog opens, and a block that fell back to its start card each time would look
to the learner as though the paper had been thrown away. That is a bug this
feature had, found on the device and not by the suite.

### One saved paper, and it stays on this device

`exam_in_progress.json` in the app directory — **not synced, not backed up, not
exported**. An unfinished exam on another device is meaningless: the clock
belongs to the sitting, and half a paper is not a result. The backup and ZIP
engines only see registry modules, so staying out of the registry is the whole
of what keeps it local.

The save holds the question **ids** and what was chosen, never the questions
themselves. Resuming re-marks the answers against the files as they are now, so
a content update that corrected an answer key corrects the resumed paper too;
question ids the shipped files no longer have are dropped, and the paper is
that many questions shorter rather than refusing to open. A save written by a
newer build is refused outright rather than half-read.

The Learn card offers **Continue** — naming the level, the part and the time
left — before it offers a new one. Starting a second mock asks first, because
there is one saved paper per device and it is the only thing here that cannot
be recovered. Discarding says what survives: every answer already given went
through the review schedule as it happened, so discarding loses the paper, not
the study.

## The results history

Every finished practice section is recorded as an attempt: which level, which
section, how many questions, how many right, and what the first answer to each
question was. **Only that.** The question text, its options and its explanation
are read back from the shipped files when the results are shown, so a content
update that corrects an answer key corrects the history with it. A question the
files no longer have says so in one line rather than quietly disappearing from
the attempt.

The history rides in the progress file, so an attempt on one device is in the
history on another, and deleting one deletes it everywhere on the next sync.
Forty mock attempts and eighty practice attempts are kept; the caps are separate
so a learner who practises daily and mocks monthly does not lose every mock.

**A score there is not a JLPT score**, and the page says so at the top rather
than leaving it to be inferred: it is over the questions this app asked.

The attempt history is also what stops the sampler repeating itself. `asked` and
`lastAsked` are derived from the **synced** attempts, so two devices avoid each
other's questions rather than each grinding through the same first twenty. The
cap on how many attempts are kept is therefore also the point at which a
question becomes askable again, which is a reasonable definition of forgetting
it.

## Content

One file per level per section: `assets/content/drills/<level>-<section>.json`,
flat, plus `structure.json`. Written by the `drills` stream of the content
pipeline — see `content-authoring.md`. Every question names the catalog ids it
is about, and `content_gate_test.dart` refuses a batch whose ids do not exist,
sit at a harder level, or repeat one already taken.

Everything shipped is model-authored and unreviewed, and every file says so in
its own `source` field.

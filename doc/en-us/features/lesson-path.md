# The lesson path

The Learn tab's answer to "what do I do next". A level is divided into units,
a unit is a topic, and each unit holds the grammar and words it teaches, some
sentences written for it, and some questions written for it.

The reference lists and the quizzes work at every level regardless. This is the
guided route through them, and a level whose units are not written yet says so
in one line rather than showing an empty box.

## A unit

```
unit:n5-1  Introducing yourself
  grammar   9 points
  vocab     22 words
  sentences 8, each naming what it teaches
  questions 8, hand-written, each with an explanation
```

The ids are a compatibility contract, like every other content id: the pass
record is keyed by the unit's, and a question's own id is what a bug report
names.

**Every grammar point of the level belongs to exactly one unit.** A test asserts
it against the shipped file. A point in no unit is not a gap in a table, it is
a thing the path never teaches; a point in two is taught twice and finished
neither time.

## Practice, and the bank behind it

The level-wide quiz shuffles the level's items and takes twenty. That makes a
mode as likely as its items happen to be common, which is fine for a review
session and wrong for a topic.

A unit is small enough to do it properly. `QuestionBank` builds **every**
question the unit can ask —

- each of its items, in every enabled mode that works for it;
- its own sentences, run through the grammar modes exactly as a catalog example
  would be;
- the questions somebody wrote for it, which are the only ones carrying an
  explanation —

and then draws twelve. Duplicates are dropped by prompt, because the same
sentence reaching the pool from two directions would be asked twice.

The draw is weighted by one thing: what the learner has not got right yet. An
item with no record weighs three, one that has only ever been wrong weighs two,
everything else one, and a hand-written question weighs double because somebody
chose it. **At most one question per item** — twelve questions should be twelve
different things, not one word asked six ways.

## The checkpoint

Twenty questions instead of twelve, and it decides something: seven in ten on
first-try accuracy opens the next unit. That is the same number the summary
shows, so the learner can see why they passed or did not.

A checkpoint is a gate rather than an item, so it does not go through the
scheduler. Its record is a plain counter — how many times passed, how many not
— and `correct > 0` is what the path reads. The items inside the session were
already recorded one answer at a time, by the ordinary path, while they were
being answered.

**A locked unit's checkpoint is still open.** Practice is closed until the unit
before it is passed, but somebody who already knows this material can take the
checkpoint and skip ahead. Hiding it behind the units it would let them skip is
circular, and the only thing passing can do is unlock what they have just
demonstrated.

## What a unit's progress bar measures

The fraction of the unit's items answered right at least once. Coarser than the
scheduler's view, and deliberately so: a bar that went backwards because an
interval lapsed would punish the learner for the passage of time.

Derived from the records, never stored — the same rule the daily counts follow.

## Files

`assets/content/lessons/<level>.json`, one per level, loaded on demand by
`lessonPathProvider`. Separate from `ContentRepository`, which parses the whole
catalog on an isolate: a path is one small file that only the Learn tab and a
session read, and a level with no file is an ordinary state rather than a
failure.

How the files are written is in
[`content-authoring.md`](content-authoring.md).

## What is not built

Scenario lessons — a short dialogue with a speaker per line, and a branch the
learner picks — are designed and not written. They are what units 1 to 4 would
gain first. The AI dialogue partner in
[`ai-assist.md`](ai-assist.md) is written against them.

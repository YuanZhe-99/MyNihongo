# Spaced repetition

How the app decides when to show an item again. Derived here rather than described, because two of
its choices depart from textbook SM-2 and both are judgement calls a later change could undo without
noticing.

The code is `lib/features/progress/services/sm2_scheduler.dart` (what one answer does to one item)
and `lib/features/progress/services/review_queue.dart` (what to study now). Both are pure, so all of
this is tested without a device.

## The problem SM-2 solves

An item reviewed just before it would have been forgotten is remembered for longer than one reviewed
too early or too late. SM-2 approximates that with three numbers per item: how many times it has been
answered right in a row, how many days until the next review, and an *ease factor* saying how quickly
that interval should grow for this particular item.

## What one answer does

```
correct:   streak += 1
           ease   += 0.10 if streak >= 3, else unchanged
           interval = 1 day        (first correct answer)
                    = 6 days       (second)
                    = round(previous interval x ease)   (third onward)

wrong:     streak   = 0
           ease    -= 0.20, floor 1.3
           interval = 1 day
```

`dueAt` becomes `now + interval`, `lastReviewedAt` becomes `now`, and the lifetime `correct` and
`wrong` counts move. Both timestamps are UTC. The lifetime counts are never rolled back: they are a
record of what happened, not part of the schedule.

A worked example, starting from the default ease of 2.5 and answering correctly every time:

| Answer | Streak | Ease | Interval | Cumulative |
|---|---|---|---|---|
| 1 | 1 | 2.5 | 1 day | day 1 |
| 2 | 2 | 2.5 | 6 days | day 7 |
| 3 | 3 | 2.6 | 16 days | day 23 |
| 4 | 4 | 2.7 | 43 days | day 66 |
| 5 | 5 | 2.8 | 120 days | day 186 |

An item passes the `masteredIntervalDays` threshold of 21 days at the third correct answer, which is
where the Learn tab starts calling it mastered. That threshold is a display convention and changes no
scheduling.

## The first departure: quality is derived, not asked

SM-2 takes a self-assessment from 0 to 5 after each review. A quiz has two outcomes, so the app
derives one: a correct answer is a 4, a correct answer on a run of three or more is a 5, and a wrong
answer is a 1.

Asking the learner to grade themselves 0–5 would be more faithful and worse: it is a second decision
per card, it is answered inconsistently, and it makes every session slower. The run-based bonus
recovers most of what the extra granularity was for — an item answered right repeatedly is one the
learner genuinely knows, and its interval should grow faster than one answered right once.

## The second departure: a wrong answer costs 0.20 of ease, not 0.54

This is the one worth stating loudly, because the textbook number is right there and looks like a bug
to anyone who checks.

SM-2's ease adjustment for its lowest quality is about −0.54. That number assumes the learner
distinguishes "I had no idea" from "I was close", so the worst penalty is reserved for the worst
answers. With binary grading **every** mistake would take the worst penalty. Starting from 2.5, three
mistakes reach the 1.3 floor:

```
2.5 -> 1.96 -> 1.42 -> 1.3
```

An item at the floor comes back every day or two forever, however well the learner then does, because
1.3 barely grows an interval. That is the classic SM-2 failure mode, and with two-way grading it
arrives after three bad days rather than after a genuine pattern of not knowing something.

At −0.20 the same three mistakes reach 1.9, the item is still scheduled sensibly, and it climbs back
as soon as the learner starts getting it right. `test/sm2_scheduler_test.dart` asserts both halves of
that: ease never falls below the floor, and an item that has hit the floor recovers past a six-day
interval with five correct answers.

## What to study now

`ReviewQueue.build` answers two questions from the progress file, the catalog and the learner
profile.

**What is due.** Records whose `dueAt` has arrived, most overdue first. The stored `dueAt` is a plain
UTC instant so it compares identically on every device, but **the queue judges it by local calendar
day**: an item due at 23:00 is due from midnight, not only in the evening. A learner expects anything
due today to be available all day, and their "today" is their own. Ordering by how long an item has
been overdue puts the longest-forgotten first, so a learner who stops halfway spent the time on the
items decaying fastest.

**What is new.** Catalog ids with no record yet, introduced kana first, then vocabulary at the
learner's target level with common words before rare ones, then grammar. Kana lead and ignore the
level: they are the alphabet, and a word whose reading cannot be read is a memorized picture. From
M3.3 the lesson path supplies this order instead.

Both are capped by the daily limits in the learner profile.

## Today's counts are derived, never stored

A review answered today is a record whose `lastReviewedAt` falls on today's local date. A new item
started today is a record whose `createdAt` is today — a record is created by its first answer, which
is what makes this countable at all.

The alternative, a per-day counter in the profile, would need resetting at midnight, would add a
field two devices can disagree about, and would miss work done on another device and synced in. The
derived count has none of those problems: it costs one pass over a few thousand records, and a
synced daily goal means the same goal everywhere, which is what a learner would assume.

## Where the numbers live

Per item, in the existing `StudyRecord` fields — `streak`, `intervalDays`, `ease`, `dueAt`,
`lastReviewedAt`. They shipped in Phase 1 and were never written until now, so no data format
changed when scheduling arrived and no golden transcript had to be re-recorded.

The learner's own settings — target level, daily limits, streak — are a `profile:me` record in the
same file. See [`../data-formats.md`](../data-formats.md) for why that rather than a second module or
a top-level object.

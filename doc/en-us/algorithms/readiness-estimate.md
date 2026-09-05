# Readiness estimate

How the app decides whether to say a learner looks ready for their level. Derived here rather than
described, because almost every choice in it is a refusal to say something, and a later change could
quietly turn the estimate into the thing it was built not to be.

The code is `lib/features/drills/services/weakness_report.dart` (what the recent papers say) and
`lib/features/drills/services/readiness_rules.dart` (what the app is willing to claim from it). Both
are pure, so all of this is tested without a device.

## What cannot be computed

The JLPT is not scored on raw marks. JEES scales each scoring group with an equating procedure it
does not publish, and the same raw score can scale differently between sessions. **No application
can compute a JLPT score**, and one that prints a number beside the letters JLPT is inviting the
learner to plan around a figure nobody can stand behind.

What *is* computable is accuracy on questions this app wrote. The honest way to report that is a
band, with the caveat next to it, and no number anywhere:

```
unknown      not enough has been answered to say anything
notYet       measured, and not there yet
close        measured, and within reach
ready        measured, and consistently over the line
unmeasured   cannot be measured on this device at all
```

The screen carries "This is an estimate from your practice in this app. It is not an official JLPT
score." in the same paragraph as the band, not behind a tooltip.

## The window

The report is built from the **last five attempts at the learner's own level**, and recomputed every
time it is read. Nothing is stored.

That is the difference between a report a learner can move and a verdict they cannot shake off. Over
every attempt ever sat, forty old papers drown five recent good ones and the estimate stops
responding to work — which makes it useless exactly when it starts mattering.

## What counts, and what does not

Each answered question adds one result to three tallies: its section, its 大問, and every catalog
item it is attributed to.

| Case | Treatment | Why |
|---|---|---|
| Answered right or wrong | Counted | The data point the estimate is made of. |
| Unanswered (`-1`, the clock ran out) | **Not counted at all** | The clock took the question away. Reading a time-out as a gap in the learner's Japanese would send them to study the wrong thing. |
| A question the shipped files no longer have | Skipped | One fewer data point is the honest cost; counting it would put a weakness against a 大問 the app can no longer name. |
| An attempt at another level | Outside the window | The estimate is about one level. |

Only the **input** is stored in an attempt — which questions were asked and what was answered — so
the section, the 大問 and the catalog items are joined from the shipped files at read time, and a
content correction reaches the report as well as the history.

## From tallies to bands

Per scoring group, the sections in that group are summed and one band comes out:

```
asked < 20                            -> unknown
accuracy >= 0.70                      -> ready
accuracy >= 0.55                      -> close
otherwise                             -> notYet
```

Twenty is the point below which one lucky paper would move the band, and an estimate that swings is
worse than none. `0.70` is the same number as `checkpointPassAccuracy`: the app already decided that
seven in ten means "this has been learnt" when it opens the next lesson unit, and two thresholds for
one claim would be the app disagreeing with itself.

## The overall band is the worst group

```
overall = the worst band among the measured groups
```

Not the average. This mirrors the exam's own rule — **fail one scoring group and you fail the level**,
however well the others went — and it is the one part of real JLPT scoring the app can honestly
reproduce, because it is a rule rather than a number.

Two consequences follow, and both are deliberate:

- **One unknown group makes the whole estimate unknown.** A band computed from two groups out of
  three would be a claim about a paper nobody has sat.
- **A strong learner with one weak group is not called ready.** That is not the estimate being harsh;
  it is what the real result would be.

## Listening with no voice is `unmeasured`, not bad

On a device with no Japanese text-to-speech voice, the listening group cannot be asked at all. It is
marked `unmeasured` and is **excluded from the overall band** rather than counted as a failure: the
learner has not done badly at listening, the device could not ask. The card says listening is missing
from the estimate.

It is not `unknown` either — `unknown` means "sit more papers", which would be advice this learner
cannot take.

## Coverage can hold the band back, never push it up

```
if overall == ready and (met items at this level / all items at this level) < 0.5:
    overall = close, cappedByCoverage = true
```

Answering well says something about the questions asked; it says much less about a level whose
vocabulary the learner has mostly never seen. "Met" means there is a progress record — the item has
been answered at least once — not that it has been mastered, because this is a check against
declaring somebody ready for a level they have barely met, not a second score.

`cappedByCoverage` is carried out to the screen so it can say *why*. "Close" with no explanation,
shown to a learner scoring nine in ten, reads as a bug rather than as a caveat.

While the catalog has not loaded, coverage is 1: a slow start shows the band the papers earned rather
than an unexplained cap.

## What the report is used for besides the band

The weakest items — asked at least three times, wrong at least once, worst accuracy first, ties broken
on the id, at most ten — are handed to the review queue as `prioritized`. The queue puts them before
everything else that is due, and orders by how overdue things are within each group.

It only **reorders**. Nothing is added to the queue and nothing is removed from it, so a report that
is empty, or still loading its files, costs the learner the old ordering and nothing else.

## Where the numbers live

| Constant | Value | File |
|---|---|---|
| `weaknessRecentAttempts` | 5 | `weakness_report.dart` |
| `weaknessMinAsked` | 3 | `weakness_report.dart` |
| `weaknessMaxPoints` | 10 | `weakness_report.dart` |
| `readinessReady` | 0.70 | `readiness_rules.dart` |
| `readinessClose` | 0.55 | `readiness_rules.dart` |
| `readinessMinAsked` | 20 | `readiness_rules.dart` |
| `readinessMinCoverage` | 0.5 | `readiness_rules.dart` |

The scoring groups themselves are content, not code: they come from `assets/content/drills/structure.json`,
which cites jlpt.jp as its source.

# lib/features/drills/services/readiness_rules.dart

Turns recent papers into a band — not yet, close, ready — per scoring group and for the level.

**This is not a JLPT score and cannot be.** JEES does not publish the raw-to-scaled equating, so no
app can compute one. What is computable is accuracy on questions this app wrote, and the honest way
to report that is a band with the caveat attached — which is why every band name here is qualitative
and no number reaches the screen.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Turn recent papers into a band per scoring group. |
| `readinessReady` | constant | B | The accuracy a group needs before it is called ready. |
| `readinessClose` | constant | B | The accuracy below which a group is not close yet. |
| `readinessMinAsked` | constant | B | How many questions a group needs before a band is claimed. |
| `readinessMinCoverage` | constant | B | How much of the catalog must be met before "ready". |
| `ReadinessBand` | enum | B | How ready a learner looks. |
| `ReadinessEstimate` | class | B | What the app is willing to say about a learner's readiness. |
| [`build`](#build) | static method | A | Work out the bands. |

## Documentation

### `static ReadinessEstimate build({required WeaknessReport report, required LevelStructure structure, double coverage = 1, bool hasJapaneseVoice = true})` <a id="build"></a>

- **Kind:** static method
- **Purpose:** Work out the bands.
- **Inputs:** The `report`; the level's `structure`; `coverage` — the share of the level's catalog the
  learner has a progress record for; whether the device has a Japanese voice.
- **Returns:** `ReadinessEstimate`; `unknown` from an empty report.
- **Side effects:** None.
- **Algorithm:** Per scoring group, sum its sections' tallies. A listening-only group with no voice
  is `unmeasured`; a group below `readinessMinAsked` is `unknown`; otherwise the accuracy picks
  `ready`, `close` or `notYet`. The overall band is the worst measured group, held back to `close`
  when it is `ready` and coverage is under `readinessMinCoverage`.
- **Usage:** `readinessProvider`, and through it the Learn card.
- **Notes:** Four decisions, each of them about what the estimate refuses to say.

  **The overall band is the worst group, not the average.** That mirrors the exam's own rule — fail
  one scoring group and you fail the level, however well the others went — and it is the one part of
  the real scoring the app can honestly reproduce, because it is a rule rather than a number.

  **One unknown group makes the whole estimate unknown.** An overall band computed from two groups
  out of three would be a claim about a paper nobody has sat.

  **Listening with no Japanese voice is `unmeasured`, and does not drag the overall band down.** The
  learner has not done badly at it; the device cannot ask. It is not `unknown` either — that means
  "sit more papers", which would be advice the learner cannot take.

  **Coverage can hold the estimate back but never push it up.** Answering well says something about
  the questions asked; it says much less about a level whose vocabulary the learner has mostly not
  met. `cappedByCoverage` is carried out so the screen can say *why* it will not say ready — "close"
  with no explanation, from a learner scoring nine in ten, reads as a bug rather than as a caveat.

`readinessReady` is the same number as `checkpointPassAccuracy`, and deliberately: the app already
decided that seven in ten means "this has been learnt" when it opens the next lesson unit, and two
different thresholds for the same claim would be the app disagreeing with itself.

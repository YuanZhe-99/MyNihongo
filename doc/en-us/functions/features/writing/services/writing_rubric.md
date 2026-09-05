# lib/features/writing/services/writing_rubric.dart

What the app itself can measure about a piece of writing.

**This runs on every device, with or without a model**, and it is what the AI note is written on top
of rather than a fallback for when the model is missing. A learner is entitled to the same
measurements on every phone; what the model adds is a sentence about what to try next, and that is
the part it is allowed to add.

Nothing here is a mark. There is no total, no percentage and no pass line, because 作文 is not on the
JLPT and inventing a score for it would be the app asserting something no examiner would.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Measure a piece of writing without a model. |
| `writingRubricWordTarget` | constant | B | How many of the unit's words a piece of writing aims to use. |
| `WritingRubric` | class | B | What the app measured about one piece of writing. |
| `sentences`, `wordsUsed`, `wordsWanted`, `grammarUsed`, `tokensAtLevel`, `tokensPlaced`, `unreadable` | fields | B | The measurements. |
| `isEmpty` | getter | B | Whether there is anything to report. |
| [`levelShare`](#levelshare) | getter | A | The share of placed tokens at the target level or easier. |
| `metWordTarget` | getter | B | Whether the unit's word target was met. |
| [`build`](#build) | static method | A | Measure one piece of writing. |
| [`promptLines`](#promptlines) | method | A | Say what was measured, in lines a prompt can carry. |

## Documentation

### `double get levelShare` <a id="levelshare"></a>

- **Kind:** getter
- **Purpose:** The share of placed tokens at the target level or easier, 0 to 1.
- **Inputs:** None beyond the receiver.
- **Returns:** `double`; 1 when nothing could be placed.
- **Side effects:** None.
- **Algorithm:** `tokensAtLevel / tokensPlaced`, or 1 for an empty denominator.
- **Usage:** The writing page's checklist line, and `promptLines`.
- **Notes:** **One when nothing could be placed**, not zero. A rubric that scolds a learner for words
  it could not look up is measuring the catalog, not the writing — and the same reasoning runs
  through `build`, where a token the catalog cannot place is counted as unreadable rather than as too
  hard. Not knowing what a word is and knowing it is above the level are different findings, and only
  the second is about the learner.

  The measurement is "within your means", not "as hard as your level": a whole sentence of N5 words
  written by somebody aiming at N1 scores 1, because every word in it is N1 or easier. A rubric that
  rewarded difficulty would be pushing learners to write above themselves, which is the opposite of
  what the exercise is for.

### `static WritingRubric build({required List<SentenceAnalysis> analyses, LessonUnit? unit, ContentCatalog? catalog, required JlptLevel level})` <a id="build"></a>

- **Kind:** static method
- **Purpose:** Measure one piece of writing.
- **Inputs:** The `analyses`, one per sentence; the `unit` where there is one; the `catalog`; and the
  `level` the learner is aiming at.
- **Returns:** `WritingRubric`; empty from empty analyses.
- **Side effects:** None.
- **Algorithm:** Walk every analysis, collecting the grammar matches, counting unreadable tokens, and
  for each placed token noting whether the unit wanted it and whether its level is at or below the
  target.
- **Usage:** The writing page, on every check.
- **Notes:** The words used are counted from the **parse**, not by searching the text, so an
  inflected form counts: somebody who wrote 食べました used 食べる. The same is true of the grammar,
  which comes from the analyser's own matches rather than from string matching — the app already has
  a better answer than a search would give.

### `List<String> promptLines(String level)` <a id="promptlines"></a>

- **Kind:** method
- **Purpose:** Say what was measured, in lines a prompt can carry.
- **Inputs:** `level` — named so the model knows what "at level" meant.
- **Returns:** `List<String>`; empty for an empty rubric.
- **Side effects:** None.
- **Algorithm:** One line per measurement that has something to say.
- **Usage:** `PracticePromptBuilder.forRubric`.
- **Notes:** **English, and deliberately: these lines go into a prompt, never onto the screen.** The
  screen renders the same numbers through the ARB catalogs in the learner's own language; this is the
  model's copy, and keeping the two apart is what stops a translation change from silently rewording
  a prompt.

  Because these findings are in the prompt, the model is never asked whether the writing is good — it
  is shown what the app measured and asked what to do about it. The task's rules forbid re-scoring,
  which is the same rule every other generated thing in this app lives under.

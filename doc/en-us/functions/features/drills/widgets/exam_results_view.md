# lib/features/drills/widgets/exam_results_view.dart

What a finished mock scored, section by section, and what went wrong in it.

The one screen in the app that shows a whole paper's result, and the one most at risk of being read
as a JLPT score. It says it is not, in words, at the top — not in a footnote under the number.

The section map is passed in rather than looked up, because the page that drew the paper already has
it and re-deriving it here would mean reading four content files to answer a question already
answered. Everything else comes off the finished [`ExamSession`](../services/exam_session.md): the
outcomes for the tallies, `allQuestions` for the text of the ones that went wrong, and each block's
`usedBefore` and `limit` for the times.

Consumers: `exam_page.dart`, once every block is in.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ExamResultsView` | class | B | What a finished mock scored, section by section, and what went wrong in it. |
| `ExamResultsView` constructor | constructor | B | Show the finished paper. |
| `exam`, `sectionOf`, `onDone` | fields | B | The finished paper, which section each question belongs to, and what to do when the learner is done reading. |
| [`build`](#build) | method | A | Build the per-section scores and the list of what went wrong. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the per-section scores and the list of what went wrong.
- **Inputs:** `context`; the `exam`, `sectionOf` and `onDone` fields.
- **Returns:** The widget tree for the current state.
- **Side effects:** Creates UI widgets from the current state; calls `onDone` from the last button.
- **Algorithm:** Walk every block's outcomes into a per-section `(asked, right, missed)` tally,
  collecting each non-correct outcome's key with whether it was answered. Sum the tally for the
  paper-wide score. Then a `ListView`: the title, the score, the standing note, one row per section
  in `DrillSection` order that has a tally, one line per block giving its minutes against its limit,
  and — unless nothing was missed — every question in every block's `allQuestions` whose `scoreKey` is
  in the wrong list, each with its wrong-or-unanswered label, its prompt, the right answer and a
  `WhyWrong`. A Done button closes it.
- **Usage:** `exam_page.dart`, once `exam.isFinished`.
- **Notes:** Keep this method cheap because Flutter may call it often.

  **Unanswered is shown apart from wrong.** They are different things — one is a question the learner
  got wrong, the other is a question the clock took away — and a results screen that merged them would
  teach the learner to review material they never saw. The per-section row only adds the unanswered
  count when there is one, so a fully answered section reads as a plain score.

  The standing note under the score is not decoration: a screen that shows "48 of 67" beside the
  letters JLPT will be read as a JLPT score unless it says otherwise.

  `WhyWrong` is given `chose: null` — a mock is marked at the end, so the explanation is about the
  question rather than about the option the learner picked.

  A question whose section the map does not know is skipped rather than tallied under a blank name,
  the same rule the history page follows.

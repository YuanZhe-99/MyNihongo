# lib/shared/providers/exam_provider.dart

The JLPT attempt history, derived from the progress file so the pages read it synchronously instead
of loading a file in a build method.

Plain `Provider`s rather than notifiers, the same shape as `labHistoryProvider`: the progress file is
the state and these are functions of it, so an attempt written here, restored from a backup, or
synced in from another device all reach the list the same way, with no second source of truth to keep
in step.

`savedExamProvider` is the exception, and deliberately so: a paper in progress is device-local, so it
is read from its own file rather than derived from the synced progress record.

Consumers: `exam_history_page.dart`, `jlpt_practice_card.dart`, `exam_page.dart`, and the drill
sampler's no-repeat rule through `askedQuestionsProvider`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Two derived views of the progress file's exam records, plus the device-local paper in progress. |
| [`examAttemptsProvider`](#examattemptsprovider) | provider | A | Every JLPT attempt, newest first. |
| [`savedExamProvider`](#savedexamprovider) | provider | A | The paper this device has half-sat, if there is one. |
| [`askedQuestionsProvider`](#askedquestionsprovider) | provider | A | Which drill questions have already been asked, and when. |

## Documentation

### `examAttemptsProvider` <a id="examattemptsprovider"></a>

- **Kind:** `Provider<List<ExamAttempt>>`
- **Purpose:** Give the history page its attempts.
- **Inputs:** `progressDataProvider`.
- **Returns:** Every `exam:` attempt, newest first; empty while the file is loading or unreadable.
- **Side effects:** None of its own; it only reads another provider.
- **Algorithm:** Read the progress data through `asData`, then `examAttempts(progress.records)`.
- **Usage:** `ExamHistoryPage`, and `askedQuestionsProvider` below it.
- **Notes:** Read through **`asData`, not `value`** — in riverpod 1.x `value` *rethrows* when the
  progress file could not be loaded, which would take down every page that shows the history instead
  of showing an empty one. Empty while the file is still loading is also what a learner who has never
  sat a paper sees, so nothing on screen has to tell "not loaded" apart from "nothing yet".

### `savedExamProvider` <a id="savedexamprovider"></a>

- **Kind:** `FutureProvider<SavedExam?>`
- **Purpose:** Report the paper this device has half-sat, if there is one.
- **Inputs:** None; it reads the save file directly.
- **Returns:** The `SavedExam` parsed from `NihongoStorage.loadExamInProgress()`, or null when there
  is no save or this build cannot resume it.
- **Side effects:** Reads a file in the app directory.
- **Algorithm:** `SavedExam.fromJson(await NihongoStorage.loadExamInProgress())`.
- **Usage:** `JlptPracticeCard` — to offer to continue, to ask before replacing, and to discard — and
  `exam_page.dart`, which refreshes it after every save.
- **Notes:** Read straight from the save file rather than from the progress file, unlike everything
  else on this page: a paper in progress is **device-local**, and an unfinished exam on another device
  is meaningless — the clock belongs to the sitting. It is therefore outside the sync and backup
  registries entirely; see
  [`../../features/progress/services/nihongo_storage.md`](../../features/progress/services/nihongo_storage.md).

  A `FutureProvider` so the Learn card can render before the file has been read, and **`invalidate`d
  rather than watched**: the file is written by the exam page and deleted by the card, both of which
  know exactly when they did it. That refresh is not optional — without it the card holds the future
  it resolved before the paper existed and shows nothing where it should be offering to continue.

  `SavedExam` is read without touching the content files, which is what lets the card say "N5 mock,
  block 2, 18 minutes left" without parsing four drill files to do it.

### `askedQuestionsProvider` <a id="askedquestionsprovider"></a>

- **Kind:** `Provider<({Set<String> asked, Map<String, int> lastAsked})>`
- **Purpose:** Report every drill question the learner has already been asked, and when.
- **Inputs:** `examAttemptsProvider`.
- **Returns:** A record of `asked` — the set of question ids — and `lastAsked`, each id mapped to the
  most recent attempt that used it, in milliseconds since the epoch.
- **Side effects:** None of its own.
- **Algorithm:** Walk the attempts newest first, adding every answered question id to the set and
  `putIfAbsent`-ing its attempt's `startedAt`. Because the list is newest first, the first time a
  question is seen is its most recent sitting and later ones need not overwrite it.
- **Usage:** The sampler's whole no-repeat rule reads this; the quiz page passes both fields into
  `_drillQuestions`.
- **Notes:** Derived from the **synced** attempts, which is what makes two devices avoid each other's
  questions rather than each grinding through the same first twenty. The cap on how many attempts are
  kept is therefore also the point at which a question becomes askable again, which is a reasonable
  definition of forgetting it.

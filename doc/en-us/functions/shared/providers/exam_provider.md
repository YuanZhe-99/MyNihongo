# lib/shared/providers/exam_provider.dart

The JLPT attempt history, derived from the progress file so the pages read it synchronously instead
of loading a file in a build method.

Plain `Provider`s rather than notifiers, the same shape as `labHistoryProvider`: the progress file is
the state and these are functions of it, so an attempt written here, restored from a backup, or
synced in from another device all reach the list the same way, with no second source of truth to keep
in step.

Consumers: `exam_history_page.dart`, and the drill sampler's no-repeat rule through
`askedQuestionsProvider`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Two derived views of the progress file's exam records. |
| [`examAttemptsProvider`](#examattemptsprovider) | provider | A | Every JLPT attempt, newest first. |
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

# lib/shared/providers/learner_profile_provider.dart

Two derived providers: the learner's profile, and what to study now.

Both are plain `Provider`s rather than notifiers, because neither owns state. The progress file is
the state; these are functions of it, so an answer, a sync or a restore recomputes them and every
watching page rebuilds with no second source of truth to keep in step.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Derive the learner profile and the review queue. |
| `learnerProfileProvider` | provider | B | The learner's target level, daily goals and streak. |
| [`reviewQueueProvider`](#reviewqueueprovider) | provider | A | What to study now, or null until the data has loaded. |

## Documentation

### `reviewQueueProvider` <a id="reviewqueueprovider"></a>

- **Kind:** provider
- **Purpose:** Say what there is to study right now.
- **Inputs:** `progressDataProvider`, `contentCatalogProvider`, `learnerProfileProvider`.
- **Returns:** `ReviewQueue?` — null until both the progress file and the catalog have loaded.
- **Side effects:** None; reads `DateTime.now()` when it recomputes.
- **Algorithm:** Watch all three, return null if either async source is still empty, otherwise call
  `ReviewQueue.build`.
- **Usage:** `TodayCard`.
- **Notes:** Null rather than an empty queue while loading, and that distinction is the point: an
  empty queue means "nothing due, well done", and showing that before the data arrives is a lie the
  learner acts on. The today card renders a progress bar for null instead.

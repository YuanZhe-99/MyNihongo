# lib/features/quiz/views/quiz_page.dart

A quiz session, as a full-screen route outside the tab shell — the same shape as
the sentence lab, and for the same reason: it is something entered with a purpose
and left when it is finished, not a place to browse.

Entered with `context.push('/quiz', extra: config)`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `QuizPage` | class | B | A quiz session as a route. |
| [`_build`](#build) | method | A | Assemble the session's questions. |
| `_enabledModes` | method | B | Decide which modes may be used, dropping listening without a voice. |
| `_itemIds` | method | B | List the catalog ids this session asks about. |
| `_kanaIds` | method | B | List the kana ids of the selected rows. |
| `_confirmLeave` | method | B | Confirm before discarding a session in progress. |
| `build` | method | B | Build the quiz, its summary, or the reason there is neither. |
| `_empty` | method | B | Explain that no question could be built. |
| `_summary` | method | B | Show the session's result. |

## Documentation

### `Future<void> _build()` <a id="build"></a>

- **Kind:** method
- **Purpose:** Assemble the session's questions.
- **Inputs:** None; reads the config, the catalog and the review queue.
- **Returns:** None.
- **Side effects:** Builds a `QuizSession` and rebuilds the page.
- **Algorithm:** Await the catalog; await the analyser only if a grammar mode is enabled; walk the
  source's ids, asking the generator for a question in any enabled mode, until the session is full.
- **Usage:** Once, from a post-frame callback in `initState`.
- **Notes:** The analyser is awaited conditionally because building the lexicon over 7,700 entries
  costs tens of milliseconds and a kana quiz has no use for it. Running after the first frame rather
  than in `initState` means a slow catalog load shows the page with a spinner rather than blocking
  the route transition. Questions are recorded through `progressDataProvider` per answer, not at the
  end, so an app killed mid-session keeps what was answered.

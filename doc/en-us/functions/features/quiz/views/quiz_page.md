# lib/features/quiz/views/quiz_page.dart

A quiz session, as a full-screen route outside the tab shell — the same shape as
the sentence lab, and for the same reason: it is something entered with a purpose
and left when it is finished, not a place to browse.

Entered with `context.push('/quiz', extra: config)`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `QuizPage` | class | B | A quiz session as a route. |
| `_passages` | field | B | The passages the drawn paper referred to, by id, so the runner can be handed the right one. |
| [`_build`](#build) | method | A | Assemble the session's questions. |
| [`_drillQuestions`](#drill) | method | A | Draw one paper's questions from the shipped drill files. |
| [`_passageFor`](#passagefor) | method | A | Show whatever the question on screen is about. |
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
  end, so an app killed mid-session keeps what was answered. A `DrillSource` takes a different route
  entirely: its questions come from `_drillQuestions` rather than from the generator, because they
  were written for a paper rather than derived from a catalog entry.

### `Future<List<QuizQuestion>> _drillQuestions(DrillSource source, Locale locale)` <a id="drill"></a>

- **Kind:** method
- **Purpose:** Draw one paper's questions from the shipped drill files.
- **Inputs:** The `source` and the `locale` to render the written text in.
- **Returns:** `Future<List<QuizQuestion>>` in paper order.
- **Side effects:** Reads assets; fills `_passages`.
- **Algorithm:** Await the structure and the level's four files; take the composition for the source's
  scale; narrow the wanted sections; then per section in `DrillSection` order, hand the filtered
  counts to `DrillSampler.drawByPassage`, adapt each drawn question with `toQuizQuestion`, and keep
  the passage it referred to.
- **Usage:** `_build`, for a `DrillSource`.
- **Notes:** Internal helper used within this file only. The composition comes from `structure.json`
  and is filtered per section, so a session over 文法 alone asks the grammar 大問 in the numbers the
  paper asks them and nothing else. A level with no structure entry draws nothing rather than guessing
  a composition — the Learn card already refuses to offer a section with no content, so reaching here
  empty means something is wrong and inventing a paper would hide it. Listening is dropped without a
  Japanese voice, the same rule `_enabledModes` applies to the app's own listening modes: a question
  nobody can hear has no answer.

### `Widget? _passageFor(BuildContext context, QuizQuestion question)` <a id="passagefor"></a>

- **Kind:** method
- **Purpose:** Show whatever the question on screen is about.
- **Inputs:** `context` and the `question`.
- **Returns:** `Widget?` — null when the question stands on its own.
- **Side effects:** None.
- **Algorithm:** Look the question's `passageId` up in `_passages`; render a `ListeningScriptPlayer`
  for a listening passage and a `DrillPassageView` for any other, keyed by the passage id and revealed
  only once the session has an outcome.
- **Usage:** Passed to `QuizRunner` as its `leadingBuilder`.
- **Notes:** Internal helper used within this file only. A reading passage is shown and a listening
  script is played, decided by the **passage's** own type rather than by the question's, because
  文章の文法 is a grammar question about a text that is read. The transcript and the translation are
  both revealed only once the question has been answered — before that they are the answer.

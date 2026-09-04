# lib/features/quiz/models/quiz_config.dart

What a quiz session is about and how long it runs. Passed to the `/quiz` route as
its `extra`.

The source is a sealed hierarchy because the five ways in are genuinely different
questions — what is due, what is new, these kana rows, this level, these ids — and
a single nullable-everything class would let two of them be set at once.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Say what a quiz session is about. |
| `QuizSource` | sealed class | B | Where a session's items come from. |
| `DueReviews`, `NewItems` | classes | B | The review queue's two halves. |
| [`KanaRows`](#kanarows) | class | B | Selected rows of the kana chart. |
| `LevelSource` | class | B | Everything at one JLPT level, from one catalog. |
| `IdsSource` | class | B | An explicit list of catalog ids. |
| `QuizConfig` | class | B | One session's settings. |

## Documentation

### `class KanaRows` <a id="kanarows"></a>

Rows are selected **by index**, not by label. `kanaBasicRows` has two rows
labelled `n` — the な row and ん — so a label is not a key, and addressing by
label would silently quiz the wrong row.

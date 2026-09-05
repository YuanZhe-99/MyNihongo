# lib/features/quiz/models/quiz_config.dart

What a quiz session is about and how long it runs. Passed to the `/quiz` route as
its `extra`.

The source is a sealed hierarchy because the ways in are genuinely different
questions — what is due, what is new, these kana rows, this level, these ids, this unit, this
paper — and a single nullable-everything class would let two of them be set at once.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Say what a quiz session is about. |
| `QuizSource` | sealed class | B | Where a session's items come from. |
| `DueReviews`, `NewItems` | classes | B | The review queue's two halves. |
| [`KanaRows`](#kanarows) | class | B | Selected rows of the kana chart. |
| `LevelSource` | class | B | Everything at one JLPT level, from one catalog. |
| `IdsSource` | class | B | An explicit list of catalog ids. |
| `UnitSource` | class | B | One unit of a level's path, and whether this is its checkpoint. |
| [`DrillSource`](#drillsource) | class | A | A JLPT paper, or one section of one. |
| `QuizConfig` | class | B | One session's settings. |

## Documentation

### `class KanaRows` <a id="kanarows"></a>

Rows are selected **by index**, not by label. `kanaBasicRows` has two rows
labelled `n` — the な row and ん — so a label is not a key, and addressing by
label would silently quiz the wrong row.

### `class DrillSource` <a id="drillsource"></a>

- **Kind:** class
- **Purpose:** Ask a paper's questions rather than the app's own.
- **Inputs:** The `level`; the `sections` to draw from, empty for all four; the `scale` of the paper.
- **Returns:** An immutable value.
- **Side effects:** None.
- **Algorithm:** None; `quiz_page.dart`'s `_drillQuestions` reads it, takes the level's composition
  from `structure.json` and filters it to the wanted sections.
- **Usage:** `jlpt_practice_card.dart` pushes one per section; the exam page pushes one for a whole
  paper.
- **Notes:** The only source whose questions were written for a paper rather than derived from a
  catalog entry, which is why it carries a composition instead of a list of ids: what makes a paper a
  paper is how many of each 大問 it has, and that is a fact about the level, not about the learner.
  `maxQuestions` on the config does **not** apply — the composition decides the length, and
  truncating it would drop the last 大問 rather than shortening the paper evenly.

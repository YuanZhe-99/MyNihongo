# lib/features/lessons/models/lesson_path.dart

The units a level is taught in, parsed from `assets/content/lessons/*.json`. A unit is a topic: a
name, the grammar and words it teaches, sentences written for it, and questions written for it.

Tolerant like the rest of the catalog — a malformed row costs the row, not the file — with one
exception: a unit or a question with no id is dropped, because an id is what progress is recorded
against.

Consumers: `lesson_repository.dart`, `lesson_rules.dart`, `lesson_path_view.dart`,
`question_bank.dart`, `reminder_planner.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LessonPath` | class | B | One level's units. |
| [`LessonPath.fromJson`](#pathjson) | factory | A | Parse one lessons file. |
| `LessonPath.unitById` | method | B | Find a unit by its id. |
| `LessonUnit` | class | B | One unit: a topic and what it teaches. |
| `LessonUnit.items` | getter | B | Every catalog id the unit teaches. |
| `LessonUnit.fromJson` | method | B | Parse one unit; null without an id. |
| `UnitSentence` | class | B | One sentence written for a unit. |
| `UnitSentence.fromJson` | method | B | Parse one sentence; null without Japanese. |
| `UnitSentence.toExample` | method | B | Present it as a catalog example. |
| `AuthoredQuestion` | class | B | One hand-written question. |
| [`AuthoredQuestion.fromJson`](#qjson) | method | A | Parse one question, or refuse it. |
| `_list` | function | B | Read a JSON value as a list, whatever it is. |

## Documentation

### `factory LessonPath.fromJson(Object? json)` <a id="pathjson"></a>

- **Kind:** factory
- **Purpose:** Parse one lessons file.
- **Inputs:** The decoded file.
- **Returns:** `LessonPath` — empty when the file cannot be read.
- **Side effects:** None.
- **Algorithm:** Reads the level label and each unit, skipping units that do not parse.
- **Usage:** `LessonRepository.load`.
- **Notes:** An unreadable file is an empty path rather than an exception, and the Learn tab then
  says the level's units are not written yet. That is the honest thing for a build whose content
  did not load, and it is also the ordinary state for a level nobody has written.

### `static AuthoredQuestion? fromJson(Object? json)` <a id="qjson"></a>

- **Kind:** method
- **Purpose:** Parse one hand-written question, or refuse it.
- **Inputs:** The decoded object.
- **Returns:** `AuthoredQuestion?`.
- **Side effects:** None.
- **Algorithm:** Requires an id, an item id, at least two options, and an answer index inside them.
- **Usage:** `LessonUnit.fromJson`.
- **Notes:** The authoring gate rejects a malformed question before it ships, so this is the second
  line of defence for a file edited by hand. A question whose answer index points outside its
  options cannot be answered at all, and showing it would waste the learner's turn.

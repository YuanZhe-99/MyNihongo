# lib/features/lessons/models/scenario.dart

The scripted conversations a unit can end with, parsed from the `scenario` block of a unit in
`assets/content/lessons/*.json`. A scenario is a script, a set of choice points, and nothing else:
no state, no scoring rule, no storage. The page decides what to do with it.

Everything here is tolerant of a malformed row, like the rest of the catalog. A line with no
Japanese is dropped and the conversation survives; a branch with one choice is dropped whole,
because one choice is not a choice; a scenario with no lines is null, so the unit shows no button
rather than opening an empty page.

Consumers: `lesson_path.dart`, `scenario_page.dart`, `lesson_path_view.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `_list` | function | B | Read a list that may be absent or the wrong shape. |
| `Scenario` | class | B | One scripted conversation. |
| `Scenario.new` | constructor | B | Hold a title, its lines and its branches. |
| [`Scenario.branchAfter`](#branch) | method | A | Find the branch that follows a point in the script. |
| `Scenario.fromJson` | static method | B | Parse one scenario; null when there is nothing to play. |
| `DialogueLine` | class | B | One line of a conversation. |
| `DialogueLine.new` | constructor | B | Hold a speaker, the Japanese, its reading and translations. |
| `DialogueLine.fromJson` | static method | B | Parse one line; null without Japanese. |
| `ScenarioBranch` | class | B | A point where the learner chooses what to say. |
| `ScenarioBranch.new` | constructor | B | Hold how many lines run first, and the choices. |
| `ScenarioBranch.fromJson` | static method | B | Parse one branch; null below two choices. |
| `ScenarioChoice` | class | B | One thing the learner may say. |
| `ScenarioChoice.new` | constructor | B | Hold a reply and whether it is the expected one. |
| `ScenarioChoice.fromJson` | static method | B | Parse one choice; null without Japanese. |

## Documentation

### `ScenarioBranch? branchAfter(int index)` <a id="branch"></a>

- **Kind:** method
- **Purpose:** Find the branch that follows a given point in the script.
- **Inputs:** `index` — how many lines have been shown.
- **Returns:** `ScenarioBranch?`; null when the script simply continues.
- **Side effects:** None.
- **Algorithm:** A linear scan of `branches` for a matching `after`. A scenario has one or two
  branches, so an index would cost more than it saves and would have to be kept in step with a
  list that never changes after parsing.
- **Usage:** `scenario_page.dart`, both in `initState` (so a branch at line 1 is asked before the
  learner is offered a Next button) and in `_advance`.
- **Notes:** `after` is a **count of lines shown**, not a zero-based index. `after: 2` means the
  question comes once two lines have been read, which is how an author counts a conversation on
  paper. The content gate checks that it lands inside the script.

# lib/features/lessons/views/scenario_page.dart

Plays one scripted conversation, a line at a time, with the choice points the author marked. A
full-window route (`/scenario`) rather than a tab: it is entered from a unit and left when the
conversation is over, like a quiz.

The page holds three pieces of state and no more — how many lines have been shown, which branch is
waiting for an answer, and what the learner has said. Nothing is written to storage.

Consumers: `router.dart` (`/scenario`), `lesson_path_view.dart` (the button that pushes it).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ScenarioArgs` | class | B | What the route carries: a scenario and its unit. |
| `ScenarioArgs.new` | constructor | B | Hold both. |
| `ScenarioPage` | widget | B | Show one conversation. |
| `ScenarioPage.new` | constructor | B | Hold the args. |
| `_ScenarioPageState._advance` | method | B | Show the next line, or the branch before it. |
| [`_ScenarioPageState._choose`](#choose) | method | A | Record the reply and carry on. |
| `_ScenarioPageState._saidLine` | method | B | Render the line the learner chose. |
| `_ScenarioPageState.build` | method | B | Build the page. |
| `_ScenarioPageState._line` | method | B | Render one spoken line. |

## Documentation

### `void _choose(ScenarioChoice choice)` <a id="choose"></a>

- **Kind:** method
- **Purpose:** Record the reply the learner picked and let the conversation continue.
- **Inputs:** The `choice`.
- **Returns:** None.
- **Side effects:** Rebuilds.
- **Algorithm:** Store the choice in `_said` under the branch's `after`, and clear `_asking`. The
  key is what puts the reply back into the transcript in the place it was said — a transcript that
  drops it reads as if the other speaker simply carried on alone. The tally reads `_said.values`
  at the end.
- **Usage:** The choice buttons in `build`.
- **Notes:** **A wrong choice does not end the conversation, and does not branch it either.** The
  script is linear; what the learner said changes the tally at the end and nothing else. A
  conversation that stops when you say the wrong thing teaches nothing about what to say instead,
  and a script that forks per choice would need every fork written and gated — which is a content
  cost paid on every unit, for a lesson whose point is reading a real exchange.

  Nothing here reaches the scheduler. Choosing a reply from three is not recall, and the unit's own
  practice session is where recall is measured — see
  [`learning-progress.md`](../../../../features/learning-progress.md).

# lib/features/lessons/views/scenario_page.dart

Plays one scripted conversation, a line at a time, with the choice points the author marked. A
full-window route (`/scenario`) rather than a tab: it is entered from a unit and left when the
conversation is over, like a quiz.

The page holds three pieces of state and no more — how many lines have been shown, which branch is
waiting for an answer, and what the learner has said. Nothing is written to storage.

The translation under a spoken line or a reply choice is picked with
`LocalizedStrings.resolveTranslation`: a Japanese reader sees no English line under the Japanese, and
no empty line in its place either.

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
| `_ScenarioPageState._saidLine` | method | B | Render the line the learner chose, with its translation under it when `resolveTranslation` gives one for this reader. |
| `_ScenarioPageState.build` | method | B | Build the page. |
| `_ScenarioPageState._line` | method | B | Render one spoken line, with its translation under it when `resolveTranslation` gives one for this reader. |
| `_ScenarioPageState._onAiChanged` | method | B | Rebuild when the on-device AI's state changes. |
| `_ScenarioPageState._canChat` | getter | B | Whether the model can carry the conversation on. |
| `_ScenarioPageState._partner` | method | B | Who the learner is talking to, named as the script names them. |
| [`_ScenarioPageState._send`](#send) | method | A | Say what the learner typed, and get an answer in character. |
| `_ScenarioPageState._scrollToEnd` | method | B | Keep the newest line in view. |
| `_ScenarioPageState._composerVisible` | getter | B | Whether the learner can type a turn right now. |
| `_ScenarioPageState._chatSection` | method | B | Build the free conversation under the tally. |
| `_ScenarioPageState._learnerTurn` | method | B | Render a line the learner typed. |
| `_ScenarioPageState._replyTurn` | method | B | Render what the other speaker said back. |
| `_ScenarioPageState._composer` | method | B | Build the field the learner types their turn into. |

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

### `Future<void> _send()` <a id="send"></a>

- **Kind:** method
- **Purpose:** Say what the learner typed, and get an answer in character.
- **Inputs:** None; reads the composer.
- **Returns:** `Future<void>`.
- **Side effects:** Runs the proofreader and then the model on the device, and appends two turns.
- **Algorithm:** Clear the field and mark the page sending. Then, **only when the device has a
  proofreader**, load the analyser and proofread the learner's line — loading a lexicon to do nothing
  with would put the whole reply behind it. Append the learner's turn, so their own line is on screen
  while the model is still writing. Build `forScenarioReply` from the scenario, the turns so far and
  the unit's words and grammar, run it through `AiPracticeService.run`, parse it, and append the
  reply or set the failure.
- **Usage:** The send button and the field's own submit action.
- **Notes:** **The proofreader runs first and is awaited, never alongside the reply.** AICore serves
  one inference to an app at a time, so a proofread fired beside the reply comes back `busy` — and a
  proofread that fails is swallowed, because the conversation is the feature and a missing correction
  is not worth interrupting it for.

  Every `await` is followed by a `mounted` check before any `setState`, which is not boilerplate here:
  the learner can leave the page while a reply is being written, and a widget test caught exactly that
  as `setState() called after dispose()`.

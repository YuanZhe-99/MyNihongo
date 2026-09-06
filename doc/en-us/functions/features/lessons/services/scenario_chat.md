# lib/features/lessons/services/scenario_chat.dart

The free conversation that follows a scenario's script, and the one turn of it.

Deliberately a plain object with no storage and no notifier: the scenario page has written nothing to
disk since it was built, and a chat line out of its situation is not a piece of writing anybody would
re-open. When the page closes, this goes with it.

Consumers: `scenario_page.dart`.

The cap exists because a model answering in character has no reason to stop. Eight turns is long
enough to be a conversation and short enough to end while the learner still means to be having one —
and `end` is available before that at every moment, because the learner deciding when they are done
is the difference between a conversation and an exercise.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `ScenarioTurn` | class | B | One turn: the learner's line or the other speaker's reply. |
| `ScenarioTurn.new` | constructor | B | Hold whose turn it is, what was said, and any meaning or proofreading. |
| `learner`, `ja`, `meaning`, `proofread` | fields | B | Whose it is, what was said, what it means, what the proofreader would have written. |
| `ScenarioChat` | class | B | The free conversation after the script. |
| `maxLearnerTurns` | constant | B | How many turns the learner may take before it closes (8). |
| `turns` | getter | B | Everything said so far, oldest first. |
| `learnerTurns` | getter | B | How many turns the learner has taken. |
| `capReached` | getter | B | Whether the learner has used every turn. |
| `ended` | getter | B | Whether the learner closed the conversation themselves. |
| `isEmpty` | getter | B | Whether anything has been said yet. |
| `addLearner` | method | B | Record what the learner said, with any proofreading. |
| `addReply` | method | B | Record what the other speaker said back. |
| `end` | method | B | Close the conversation and drop what was said. |

## Documentation

`addLearner` is called **before** the reply is asked for, so the learner sees their own line in the
transcript while the model is still writing. `end` clears the turns as well as marking it ended:
nothing here was ever going to be kept, and leaving the transcript on screen after the learner has
said they are done would suggest that it was.

Nothing in this file imports storage, a provider, or the progress module. That is the same rule the
scripted half follows — see `scenario.md` — and it is what keeps a scenario a lesson rather than a
thing that scores you.

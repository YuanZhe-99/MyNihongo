# lib/features/ai/services/ai_practice_service.dart

Turn-taking for the one model the device has.

`AiAssistService` allows one generation at a time, so two features that both want it have to queue.
The rule here is that **the learner's request wins**.

Deliberately imports no storage and no progress provider: nothing generated writes a record, and a
test asserts that by reading this file's own imports.

Consumers: `why_wrong.dart`, `generated_examples.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AiPracticeService` | class | B | Runs the practice tasks in turn. |
| `AiPracticeService.instance` | field | B | The app-wide instance. |
| `AiPracticeService.setInstanceForTest` | method | B | Replace it in a test. |
| `retryDelay`, `maxRetries` | constants | B | How a background job waits and gives up. |
| `AiPracticeService.canRun` | getter | B | Whether the model can be asked at all. |
| [`AiPracticeService.run`](#run) | method | A | Run one prompt the learner is waiting for. |
| [`AiPracticeService.runInBackground`](#bg) | method | A | Run one nobody is waiting for. |

## Documentation

### `Future<String> run(String prompt)` <a id="run"></a>

- **Kind:** method
- **Purpose:** Run one prompt the learner is waiting for.
- **Inputs:** The prompt.
- **Returns:** The model's reply; throws `GenAiException` on failure.
- **Side effects:** Runs a model on the device.
- **Algorithm:** Chains onto the previous interactive future, so requests run in the order they
  were made.
- **Usage:** Every button that generates something.
- **Notes:** Interactive requests queue behind each other rather than failing with "busy". Somebody
  who taps two buttons quickly should get two answers, not an error, and the wait is a second
  rather than a failure they have to understand.

### `Future<String?> runInBackground(String prompt)` <a id="bg"></a>

- **Kind:** method
- **Purpose:** Run one prompt nobody is waiting for.
- **Inputs:** The prompt.
- **Returns:** The reply, or null when it never got a turn.
- **Side effects:** Runs a model on the device, possibly after a wait.
- **Algorithm:** Waits for any interactive work, then retries a few times while the model is busy.
- **Usage:** Anything generated while the learner is doing something else.
- **Notes:** **It gives up silently.** Returning null rather than throwing is the point: nothing is
  waiting for this, so there is nobody to tell, and an error surfaced from a background job would
  interrupt whatever the learner is actually doing.

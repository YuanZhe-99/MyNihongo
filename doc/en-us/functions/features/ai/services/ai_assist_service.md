# lib/features/ai/services/ai_assist_service.dart

Owns the on-device AI policy: whether it may run at all, what each feature can do right now, and the
one-at-a-time rule.

A singleton with an injectable backend, like `TtsService` and `SpeechRecognitionService`, so a widget
test drives every branch without a device.

Consumers: `aicore_sentence_enhancer.dart`, `ai_settings_tiles.dart`, `sentence_lab_page.dart`,
`app_settings.dart`, `sentence_analyzer.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GenAiDownload` | class | B | How far a model download has got. |
| `GenAiDownload.fraction` | getter | B | The fraction done, or null when the total is unknown. |
| `AiAssistService` | class | B | The policy holder. |
| `AiAssistService.instance` | field | B | The app-wide instance. |
| `setInstanceForTest` | static method | B | Replace the singleton for a test. |
| `AiAssistService.timeout` | constant | B | How long one generation may take. |
| `AiAssistService.defaultMaxOutputTokens` | constant | B | How long an answer may be when the caller names no budget. |
| `statusOf` | method | B | What a feature can do, as last asked. |
| `canExplain`, `canProofread` | getters | B | Whether each action can be offered right now. |
| [`needsDownload`](#needsdownload) | getter | A | Whether the hint pointing at Settings applies. |
| [`setEnabled`](#setenabled) | method | A | Turn the feature on or off. |
| `refreshStatus` | method | B | Ask the device what each feature can do. |
| `download` | method | B | Ask the system to fetch a feature's model. |
| [`explain`](#explain) | method | A | Generate one explanation. |
| `proofread` | method | B | Ask for corrected versions of one sentence. |
| `cancel` | method | B | Stop whatever is running. |
| `_requireEnabled` | method | B | Refuse every generating call while the feature is off. |
| [`aiAssistServiceProvider`](#provider) | provider | A | The service, read by Settings and the lab. |

## Documentation

### `Future<void> setEnabled(bool value)` <a id="setenabled"></a>

- **Kind:** method
- **Purpose:** Turn on-device AI on or off.
- **Inputs:** `value`.
- **Returns:** None.
- **Side effects:** Refreshes the statuses when switched on; cancels anything running and forgets
  every status when switched off.
- **Algorithm:** Ignores a no-op change, then branches.
- **Usage:** `AppSettingsNotifier.setAiAssistEnabled`, and the initial load.
- **Notes:** Switching off is immediate and total — nothing further is asked of the device, and the
  lab stops offering the actions on its next build. Persisting the choice is `AppSettingsNotifier`'s
  job, as it is for every other preference; this class never writes to disk.

### `Future<String> explain(String prompt)` <a id="explain"></a>

- **Kind:** method
- **Purpose:** Generate one explanation.
- **Inputs:** The assembled `prompt`.
- **Returns:** `Future<String>`; throws `GenAiException` rather than returning a failure.
- **Side effects:** Runs a model on the device.
- **Algorithm:** Refuse if disabled, refuse if busy, re-ask the status, refuse if not available, then
  call the backend under a timeout.
- **Usage:** `AiCoreSentenceEnhancer.explain`.
- **Notes:** **The gate order is the point.** Disabled is refused before the status is even asked, so
  a device with a model present still does nothing while the switch is off — the backend is not
  called and ignored, it is not called at all, and `test/ai_assist_service_test.dart` asserts exactly
  that. The status is re-asked every time because the system can remove a model between two requests,
  and a remembered "available" would turn that into a failure the learner cannot interpret. Nothing
  generated is stored anywhere.

### `bool get needsDownload` <a id="needsdownload"></a>

- **Kind:** getter
- **Purpose:** Decide whether the lab shows its "the model is not downloaded yet" line.
- **Inputs:** None.
- **Returns:** `bool`.
- **Side effects:** None.
- **Algorithm:** True when the feature is on, explaining is not possible, and some feature is
  downloadable or downloading.
- **Usage:** `SentenceLabPage._buildAiActions`.
- **Notes:** The last clause is what keeps the line off a device that simply cannot run a model.
  Telling that owner to go and download something would be a false promise — there is nothing there
  to fix, and the honest answer is to say nothing at all.

### `final aiAssistServiceProvider` <a id="provider"></a>

- **Kind:** provider
- **Purpose:** Hand the singleton to the widgets that need it.
- **Inputs:** None.
- **Returns:** `Provider<AiAssistService>`.
- **Side effects:** None.
- **Algorithm:** Returns `AiAssistService.instance`.
- **Usage:** `sentence_analyzer.dart`, `ai_settings_tiles.dart`, `sentence_lab_page.dart`.
- **Notes:** A plain `Provider`, **not** a `ChangeNotifierProvider`, and the reason is worth keeping:
  riverpod disposes the notifier a `ChangeNotifierProvider` holds when its scope goes away, which for
  an app-wide singleton means the next `ProviderScope` — the next test, or a rebuilt root — gets a
  disposed service. Consumers add their own listener instead, the way the speech services are
  listened to.

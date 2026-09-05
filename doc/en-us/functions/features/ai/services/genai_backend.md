# lib/features/ai/services/genai_backend.dart

The seam between the app and the platform's generative models, and the real implementation over the
`com.yuanzhe.my_nihongo/genai` method channel.

It exists for the same reason the speech and text-to-speech seams do: a `flutter_test` run has no
AICore, and everything worth testing — the enabled gate, the status handling, the prompt, the
parsing — is on the service's side of it.

Consumers: `ai_assist_service.dart`, `sentence_lab_page.dart` and `ai_settings_tiles.dart` (for the
enums), and the tests.

M3.0 split what used to be one answer in two. `statusReport` returns the status **plus** the raw
platform value or the exception behind it, and `GenAiStatus.unreachable` says the call could not be
made at all — a different fact from AICore refusing, with a different fix. `coreInfo` reads the
installed AICore build. Both were added with bodies rather than left abstract so a backend with
nothing to add keeps working unchanged.

M4.0 widened the report again, because the split was still not fine enough to diagnose a Z Fold 8.
The Prompt API serves four model variants and the platform side probes all of them, so a report now
carries the `variant` that answered, the ones that `refused`, and the `baseModelName` and
`tokenLimit` of whatever is actually serving. `GenAiStatus.unknown` is a status value this build has
no name for — reported as itself, never folded into a refusal, because that enumeration has grown
before. `GenAiCoreInfo.compatible` answers whether AICore considers the device serviceable at all.
Every one of these fields decodes as absent rather than wrong, so an older platform side, and the
proofreading feature that has only one model, keep working unchanged.

M4.0a added `served` and the two arguments that go the other way. The probe no longer stops at the
first variant that answers, because whether the learner has a *choice* of model size cannot be known
from a loop that returns early; `statusReport` takes `force` (re-probe rather than trust the variant
already serving) and `preferFast` (try the smaller model first), and `hasSizeChoice` answers the one
question the Settings control needs. It lives here rather than in the widget because it is a fact
about the platform's reply.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GenAiFeature` | enum | B | Which of the two on-device models a call is about. |
| `GenAiStatus` | enum | B | What a feature can do on this device right now, including `unknown` for an answer newer than this build. |
| `GenAiFailure` | enum | B | Why an attempt produced no answer. |
| `GenAiException` | class | B | Thrown when a call cannot produce a result. |
| `GenAiStatusReport` | class | B | One feature's status, the variant serving it, and the ones refused. |
| `GenAiCoreInfo` | class | B | The AICore build installed, and whether it can serve models here. |
| `GenAiCoreInfo.fromJson` | static method | B | Read the map the channel sends. |
| `GenAiBackend` | abstract class | B | The seam itself. |
| `GenAiBackend.status` | method | B | Ask what a feature can do. |
| [`GenAiBackend.download`](#download) | method | A | Ask the system to fetch a feature's model. |
| `GenAiBackend.explain` | method | B | Generate one answer. |
| `GenAiBackend.proofread` | method | B | Ask for corrected versions of one sentence. |
| `GenAiBackend.cancel` | method | B | Stop whatever is running. |
| `GenAiBackend.statusReport` | method | B | Status plus everything the device said about it. |
| `GenAiBackend.coreInfo` | method | B | Describe the AICore installation. |
| `MethodChannelGenAiBackend` | class | B | The real backend, over the method channel. |
| [`MethodChannelGenAiBackend.status`](#status) | method | A | Ask the platform, or answer without it. |
| `MethodChannelGenAiBackend.download` | method | B | Start a download and forward its progress. |
| `MethodChannelGenAiBackend.explain` | method | B | Send one prompt across the channel. |
| `MethodChannelGenAiBackend.proofread` | method | B | Send one sentence across the channel. |
| `MethodChannelGenAiBackend.cancel` | method | B | Cancel, best-effort. |
| `MethodChannelGenAiBackend.statusReport` | method | B | Decode the platform's status reply, tolerating missing fields. |
| `MethodChannelGenAiBackend.coreInfo` | method | B | Read the AICore installation. |
| `MethodChannelGenAiBackend.hasSizeChoice` | static method | B | Whether the served variants include both a larger and a faster model. |
| `_handlePlatformCall` | method | B | Receive download progress from the platform. |
| `_failureFor` | static method | B | Map a platform error code to a failure. |

## Documentation

### `Future<bool> download(GenAiFeature feature, {void Function(int, int)? onProgress})` <a id="download"></a>

- **Kind:** method
- **Purpose:** Ask the system to fetch a feature's model.
- **Inputs:** The `feature`, and `onProgress` called with bytes downloaded and the total when it is
  known (-1 when it is not).
- **Returns:** `Future<bool>` — true when the model is ready afterwards.
- **Side effects:** The **system** downloads a model over the network.
- **Algorithm:** Registers the progress handler once, calls the channel, clears the handler.
- **Usage:** `AiAssistService.download`, from the button in Settings.
- **Notes:** The app never downloads anything itself; it asks AICore to, and AICore fetches from
  Google. That distinction is exactly what the privacy policy states, and it is why this is the one
  method here that touches the network at all. Progress arrives as calls in the other direction, so
  the handler is registered lazily — nothing else on this channel ever calls back.

### `Future<GenAiStatus> status(GenAiFeature feature)` <a id="status"></a>

- **Kind:** method
- **Purpose:** Report what a feature can do on this device.
- **Inputs:** The `feature`.
- **Returns:** `Future<GenAiStatus>`.
- **Side effects:** One channel call, on Android only.
- **Algorithm:** Delegates to `statusReport` and drops the diagnostics. That short-circuits to
  `unsupported` where no on-device model can exist; otherwise it maps the platform's status strings,
  and any error, onto the enum.
- **Usage:** `AiAssistService.refreshStatus`, and before every generation.
- **Notes:** A platform error answers `unreachable` rather than throwing, and rather than
  `unavailable`: failing to ask is not the same fact as being refused, and a thrown exception here
  would have to be caught by every caller to say either. A status string this build does not know
  answers `unknown` for the same reason. The `unsupported` short-circuit is what keeps the channel
  untouched on Windows, macOS and iOS, where it does not exist and every call would raise
  `MissingPluginException`.

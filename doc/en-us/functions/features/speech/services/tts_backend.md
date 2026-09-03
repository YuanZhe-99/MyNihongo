# lib/features/speech/services/tts_backend.dart

The seam between [`TtsService`](tts_service.md) and the platform speech engine. Only the calls this
app makes are declared, and the plugin's loose `dynamic` returns are normalised here so nothing
above this file ever sees them.

The seam exists because a `flutter_test` run has no speech engine: everything worth testing —
preferring the kana reading, one utterance at a time, filtering voices to Japanese, surviving a
device with no engine — is on the service's side of it.

Consumers: `tts_service.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TtsBackend` | abstract class | B | Declare the engine calls the app makes. |
| `TtsBackend.setLanguage` | method | B | Set the language later utterances are spoken in. |
| `TtsBackend.isLanguageAvailable` | method | B | Report whether the engine can speak a language. |
| `TtsBackend.setSpeechRate` | method | B | Set the engine rate, in engine units. |
| `TtsBackend.voices` | method | B | List the engine's voices as `name`/`locale` maps. |
| `TtsBackend.setVoice` | method | B | Select a voice. |
| `TtsBackend.speak` | method | B | Speak a string, completing when the audio ends. |
| `TtsBackend.stop` | method | B | Stop the current utterance. |
| [`FlutterTtsBackend`](#fluttertsbackend) | class | A | The real backend, wrapping `flutter_tts`. |
| `FlutterTtsBackend._asBool` | static method | B | Read the plugin's loosely typed truthy answers. |

## Documentation

### `class FlutterTtsBackend implements TtsBackend` <a id="fluttertsbackend"></a>

- **Kind:** class
- **Purpose:** Wrap `flutter_tts` behind the seam.
- **Inputs:** An optional `FlutterTts` for tests; a real one otherwise.
- **Returns:** —
- **Side effects:** Turns on `awaitSpeakCompletion` at construction, so `speak` completes when the
  audio ends rather than when the call is queued.
- **Algorithm:** Straight delegation, plus two normalisations: truthy answers arrive as `1`/`0` on
  Android and as a bool on the desktop backends, and voice maps carry non-string values (Android's
  `network_required`, the Windows gender enum) that are stringified.
- **Usage:** The default `TtsService.instance`.
- **Notes:** The constructor's `awaitSpeakCompletion` call is fire-and-forget with its failure
  swallowed on purpose. A `flutter_test` run has no plugin behind the channel and answers
  `MissingPluginException`, which would otherwise surface as an unhandled asynchronous error in
  every test that happens to build the app.

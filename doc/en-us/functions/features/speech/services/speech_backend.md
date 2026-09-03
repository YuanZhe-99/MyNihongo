# lib/features/speech/services/speech_backend.dart

The seam between [`SpeechRecognitionService`](speech_recognition_service.md) and the platform
recognizer, plus the two small types that cross it: one result, and the reason a session ended
badly.

It exists for the same reason the text-to-speech seam does — a `flutter_test` run has no recognizer,
and the state machine and the on-device policy are on the service's side of it.

Consumers: `speech_recognition_service.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SpeechHeard` | class | B | One recognition result: the text, and whether it is final. |
| `SpeechFailure` | enum | B | Why a session ended badly: noMatch, languageUnavailable, permissionDenied, unavailable. |
| `SpeechBackend` | abstract class | B | Declare the recognizer calls the app makes. |
| `SpeechBackend.initialize` | method | B | Start the recognizer and report whether it can be used. |
| `SpeechBackend.hasPermission` | method | B | Report whether the microphone is already granted. |
| `SpeechBackend.localeIds` | method | B | List the locale ids the recognizer supports. |
| `SpeechBackend.listen` | method | B | Listen for one utterance, offline-only when asked. |
| `SpeechBackend.stop` | method | B | Stop listening, keeping the result. |
| `SpeechBackend.cancel` | method | B | Stop listening, discarding the result. |
| `SpeechToTextBackend` | class | B | The real backend, wrapping `speech_to_text`. |
| [`_mapError`](#maperror) | static method | A | Translate a plugin error id into a failure this app handles. |

## Documentation

### `static SpeechFailure _mapError(String errorMsg)` <a id="maperror"></a>

- **Kind:** static method
- **Purpose:** Turn the recognizer's error string into something the UI can act on.
- **Inputs:** `errorMsg` — the plugin's error id, which on Android is `SpeechRecognizer`'s own.
- **Returns:** `SpeechFailure`.
- **Side effects:** None.
- **Algorithm:** Substring tests, in order: permission, then no-match and speech-timeout, then
  language, then everything else as `unavailable`.
- **Usage:** The error callback passed to `initialize`.
- **Notes:** `languageUnavailable` is the one that carries weight. It is what an offline-only
  request answers on a device with no Japanese model downloaded, and the practice sheet turns it
  into a message naming both fixes rather than a generic failure. The mapping lives next to the
  plugin that produces the strings, so a plugin upgrade has one place to check.

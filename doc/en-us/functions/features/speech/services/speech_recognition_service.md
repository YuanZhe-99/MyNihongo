# lib/features/speech/services/speech_recognition_service.dart

The app's speech-recognition policy: Japanese only, on the device unless the learner opted out, one
session at a time, and the microphone asked for at first use. A `ChangeNotifier`, so the practice
sheet renders the session as it moves.

Built over a [`SpeechBackend`](speech_backend.md), so the state machine and the on-device rule are
testable without a recognizer — `test/speech_recognition_service_test.dart` drives every transition.

Consumers: `pronunciation_practice_sheet.dart`, `speech_settings_tiles.dart` (the status line and
the network-fallback switch), `app_settings.dart` (applies the persisted switch at startup).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SpeechPhase` | enum | B | Where a listening session is: idle, listening, processing, failed, done. |
| `SpeechRecognitionService` | class | B | Listen for one spoken Japanese utterance, on the device. |
| `setInstanceForTesting` | static method | B | Replace the app-wide instance in a test. |
| [`ensureAvailable`](#ensureavailable) | method | A | Start the recognizer once and find the Japanese locale. |
| `hasPermission` | method | B | Report whether the microphone is already granted. |
| [`listen`](#listen) | method | A | Listen for one utterance. |
| `stop` | method | B | End the session, keeping what was recognized. |
| `cancel` | method | B | Abandon the session and close the microphone. |
| `reset` | method | B | Return to idle, ready for another attempt. |
| `_onHeard` | method | B | Record a partial or final result; an empty final result is a no-match. |
| `_onFailure` | method | B | Record an asynchronous recognizer error, ignoring one that arrives after a final result. |
| `_fail` | method | B | Move to the failed state. |

## Documentation

### `Future<bool> ensureAvailable()` <a id="ensureavailable"></a>

- **Kind:** method
- **Purpose:** Decide, once, whether Japanese recognition can be attempted at all.
- **Inputs:** None.
- **Returns:** `Future<bool>`.
- **Side effects:** On the first call, initializes the platform recognizer — which is where the
  microphone permission is requested.
- **Algorithm:** `platformMayRecognizeSpeech` first, so a platform with nothing behind the plugin
  never prompts for a microphone it will not use. Then initialize, then look for a locale id whose
  language subtag is `ja`; without one the service reports unavailable.
- **Usage:** `listen` (which calls it itself), and the Settings status line.
- **Notes:** The locale id is matched on the `ja` prefix rather than compared to a constant, because
  Android spells it `ja_JP` and Apple spells it `ja-JP`. The answer is remembered: a device that has
  no recognizer is not asked again on every tap.

### `Future<void> listen()` <a id="listen"></a>

- **Kind:** method
- **Purpose:** Record one utterance and publish what the recognizer makes of it.
- **Inputs:** None; reads `networkFallbackAllowed`.
- **Returns:** None; results arrive through `notifyListeners`.
- **Side effects:** Opens the microphone.
- **Algorithm:** Ensure availability, clear the previous result, move to `listening`, and ask the
  backend to listen with `onDevice: !networkFallbackAllowed`.
- **Usage:** The practice sheet's record button.
- **Notes:** **This is where the privacy promise is kept.** `onDevice` true means offline-only: on
  Android it maps to `EXTRA_PREFER_OFFLINE`, which fails rather than falling back when no Japanese
  model is installed. That failure is the honest answer and the UI explains it; only a learner who
  explicitly turned the fallback on in Settings ever produces a request that could reach a server.

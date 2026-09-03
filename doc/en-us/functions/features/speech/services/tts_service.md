# lib/features/speech/services/tts_service.dart

The app's text-to-speech policy: one instance, one language, one utterance at a time. It owns the
engine's language, rate and voice, and publishes what is speaking so the whole UI agrees. The
platform engine renders the audio locally; nothing leaves the device.

Constructed over a [`TtsBackend`](tts_backend.md), so the interesting behaviour is testable without
a speech engine — `test/tts_service_test.dart` drives every branch through a recording fake.

Consumers: `speak_button.dart`, `speech_settings_tiles.dart`, `kana_page.dart` (long-press),
`app_settings.dart` (applies the persisted rate and voice at startup).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TtsService` | class | B | Speak Japanese through the device's own engine. |
| `setInstanceForTesting` | static method | B | Replace the app-wide instance in a test. |
| [`engineRate`](#enginerate) | static method | A | Convert a user-facing rate multiple to the engine's units. |
| [`init`](#init) | method | A | Prepare the engine and learn whether it has a Japanese voice. |
| `setRate` | method | B | Apply a speaking rate, clamped to the offered range. |
| `setVoiceByName` | method | B | Select a Japanese voice by engine name; an unknown name resets to the default. |
| [`speak`](#speak) | method | A | Speak one piece of Japanese, interrupting whatever is playing. |
| `stop` | method | B | Stop the current utterance and clear the shared speaking state. |
| `_isJapanese` | static method | B | Decide whether a voice map describes a Japanese voice. |

## Documentation

### `static double engineRate(double userRate)` <a id="enginerate"></a>

- **Kind:** static method
- **Purpose:** Convert the user-facing speed multiple into what the engine wants.
- **Inputs:** `userRate`, where 1.0 means normal speed.
- **Returns:** `userRate * 0.5`.
- **Side effects:** None.
- **Algorithm:** One multiplication.
- **Usage:** `setRate`.
- **Notes:** `flutter_tts` treats **0.5 as normal on every platform it supports** — Android doubles
  the value before handing it to `TextToSpeech`, Apple's `AVSpeechSynthesizer` default is 0.5, and
  the Windows backend adds 0.5 to reach a WinRT `SpeakingRate` of 1.0. A platform branch here would
  be wrong, not merely unnecessary.

### `Future<void> init({double? rate, String? voiceName})` <a id="init"></a>

- **Kind:** method
- **Purpose:** Configure the engine and discover what it can do.
- **Inputs:** The persisted preferences, if any.
- **Returns:** None.
- **Side effects:** Sets the engine language, rate and voice; queries the voice list.
- **Algorithm:** Discovery runs once; every call after that only re-applies the preferences. The
  Japanese voice list is the engine's voices filtered on the `ja` language subtag, which arrives as
  `ja`, `ja-JP` or `ja_JP` depending on the platform.
- **Usage:** `AppSettingsNotifier._loadPersisted`, once the preferences are known.
- **Notes:** Every engine call is guarded. A device with no speech engine throws from the platform
  channel rather than answering false, and a `flutter_test` run answers `MissingPluginException`;
  neither may stop the app from starting, so a failure means "no Japanese voice" and nothing more.
  The caller does not await it — a missing engine must not delay the first frame.

### `Future<void> speak(String text)` <a id="speak"></a>

- **Kind:** method
- **Purpose:** Speak one piece of Japanese.
- **Inputs:** `text` — the kana reading wherever the caller has one.
- **Returns:** None.
- **Side effects:** Stops any current utterance, produces audio, and holds `speaking` at this text
  while the audio plays.
- **Algorithm:** Trim; ignore blank text; stop whatever is playing; if that was this same text,
  return — the tap was a stop. Otherwise publish the text, speak it, and clear the state when the
  utterance ends or the engine throws.
- **Usage:** `SpeakButton`, `kana_page.dart`, the rate preview.
- **Notes:** Tapping the same button twice stops rather than repeats, and tapping a second button
  interrupts the first: there is one voice on the device. The `finally` clears `speaking` only when
  it still holds this text, so a later utterance that started meanwhile is not cleared by an older
  one finishing.

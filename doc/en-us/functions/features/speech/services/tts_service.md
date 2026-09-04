# lib/features/speech/services/tts_service.dart

The app's text-to-speech policy: one instance, one language, one utterance at a time. It owns the
engine choice, language, rate and voice, and publishes what is speaking so the whole UI agrees. The
platform engine renders the audio locally; nothing leaves the device.

**The engine does not keep the language it was given.** `flutter_tts`'s Android plugin overwrites it
with the system default twice — after its own initialization, and again whenever it silently rebuilds
the `TextToSpeech` instance because the service connection dropped. Both are invisible from Dart, and
both made the app read Japanese aloud in the device's own language. The probe in `init`, the re-apply
in `speak`, and `_recoverEngine` all exist for that; see
[`../../../../features/pronunciation.md`](../../../../features/pronunciation.md).

Constructed over a [`TtsBackend`](tts_backend.md), so the interesting behaviour is testable without
a speech engine — `test/tts_service_test.dart` drives every branch through a recording fake.

Consumers: `speak_button.dart`, `speech_settings_tiles.dart`, `voice_picker_sheet.dart`,
`kana_page.dart` (long-press), `app_settings.dart` (applies the persisted engine, rate and voice at
startup).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TtsService` | class | B | Speak Japanese through the device's own engine. |
| `setInstanceForTesting` | static method | B | Replace the app-wide instance in a test. |
| [`engineRate`](#enginerate) | static method | A | Convert a user-facing rate multiple to the engine's units. |
| [`init`](#init) | method | A | Prepare the engine and learn whether it has a Japanese voice. |
| `setRate` | method | B | Apply a speaking rate, clamped to the offered range. |
| `setVoiceByName` | method | B | Select a Japanese voice by engine name; an unknown name falls back to the best one. |
| `setEngine` | method | B | Switch speech engines, re-read the voices, and drop the chosen voice. |
| [`speak`](#speak) | method | A | Speak one piece of Japanese, interrupting whatever is playing. |
| `preview` | method | B | Speak a sample with one voice, then restore the learner's own. |
| `stop` | method | B | Stop the current utterance and clear the shared speaking state. |
| `_loadVoices` | method | B | Read the engine's voices, keep the Japanese ones, pick the best. |
| [`_applyEngineState`](#applyenginestate) | method | A | Push language, voice and rate onto the engine and report whether Japanese stuck. |
| `_recoverEngine` | method | B | Rebuild an engine that has stopped accepting Japanese. |
| `_chosenVoice` | method | B | Find the voice map behind the chosen voice name. |
| `_resolveVoiceName` | method | B | Keep a voice name only while this engine still offers it. |
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

### `Future<void> init({double? rate, String? voiceName, String? engineId})` <a id="init"></a>

- **Kind:** method
- **Purpose:** Configure the engine and discover what it can do.
- **Inputs:** The persisted preferences, if any.
- **Returns:** None.
- **Side effects:** May switch engines; queries the voice list; sets language, voice and rate.
- **Algorithm:**
  1. Discovery runs once. List the engines; switch to the persisted one when it is still installed.
  2. **Await `isLanguageAvailable` as a probe.** Its value is discarded; awaiting it is the point.
  3. Read the voices, keep the Japanese ones, sort them best-first, and take the best installed one
     as the default.
  4. Resolve the persisted voice name against that list, then `_applyEngineState`.
- **Usage:** `AppSettingsNotifier._loadPersisted`, once the preferences are known.
- **Notes:** **Step 2 is load-bearing, and the order is the whole fix.** While the platform engine is
  still starting, the plugin queues method calls and replays them from its init callback — and then
  overwrites the language with the system default. A `setLanguage` sent before that point is applied
  and immediately discarded, which is what left the engine reading Japanese in the device's own
  language, intermittently, depending on which finished first. Awaiting any queued call means the
  overwrite has already happened. Every engine call is guarded: a device with no speech engine throws
  from the platform channel rather than answering false, and a `flutter_test` run answers
  `MissingPluginException`; neither may stop the app from starting. The caller does not await it — a
  missing engine must not delay the first frame.

### `Future<void> speak(String text)` <a id="speak"></a>

- **Kind:** method
- **Purpose:** Speak one piece of Japanese.
- **Inputs:** `text` — the kana reading wherever the caller has one.
- **Returns:** None.
- **Side effects:** Stops any current utterance, produces audio, and holds `speaking` at this text
  while the audio plays.
- **Algorithm:** Trim; ignore blank text; stop whatever is playing; if that was this same text,
  return — the tap was a stop. Then `_applyEngineState`; if Japanese is refused and it worked earlier
  in this run, `_recoverEngine` once. Publish the text, speak it, and clear the state when the
  utterance ends or the engine throws.
- **Usage:** `SpeakButton`, `kana_page.dart`, the rate preview.
- **Notes:** Tapping the same button twice stops rather than repeats, and tapping a second button
  interrupts the first: there is one voice on the device. The `finally` clears `speaking` only when
  it still holds this text, so a later utterance that started meanwhile is not cleared by an older
  one finishing. **The state is re-applied before every utterance** because the plugin rebuilds its
  `TextToSpeech` behind the app's back when the service connection drops — common after the app has
  been in the background — and the rebuilt engine is back on the system default language with no
  symptom the app can see. Three engine calls cost milliseconds; a wrong voice costs the feature.

### `Future<bool> _applyEngineState()` <a id="applyenginestate"></a>

- **Kind:** method
- **Purpose:** Push the language, voice and rate the app wants onto the engine.
- **Inputs:** None.
- **Returns:** `bool` — whether Japanese was actually accepted.
- **Side effects:** Changes engine state; updates `hasJapaneseVoice`.
- **Algorithm:** `setLanguage('ja-JP')`, then select the chosen voice or the best default one, then
  the rate. Japanese counts as reachable when **either** the language or the voice was accepted.
- **Usage:** `init`, `setVoiceByName`, `setEngine`, `speak`, and the `finally` in `preview`.
- **Notes:** Selecting the voice explicitly, not only the language, is what stops the engine falling
  back to whatever voice it was last left on. Either-or rather than both: an engine can refuse
  `ja-JP` as a locale and still hold a Japanese voice, and a desktop engine can accept the locale and
  enumerate no voices at all. The return value is what `speak` uses to decide whether the engine
  needs rebuilding.

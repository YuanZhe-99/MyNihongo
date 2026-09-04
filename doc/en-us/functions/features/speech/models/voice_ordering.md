# lib/features/speech/models/voice_ordering.dart

Pure predicates and one comparator that decide which Japanese voice is best and how the picker lists
them. It has no Flutter dependency and no localization, so both the service and the widget can use
it without either owning it.

The order is not cosmetic. `TtsService` takes the first installed voice as the one it selects when
the learner has not chosen, and the picker names voices by their position — "Japanese voice 1, 2,
3". An unstable order would rename voices between runs and silently change which one speaks.

Consumers: `tts_service.dart` (`_loadVoices`), `voice_labels.dart` (numbering and qualifiers).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Order and describe the Japanese voices an engine offers. |
| `_qualityOrder` | top-level constant | B | Voice quality names, worst first, as `flutter_tts` spells them. |
| `voiceIsNotInstalled` | top-level function | B | Report whether the engine says the voice data is not on the device. |
| `voiceNeedsNetwork` | top-level function | B | Report whether speaking with this voice needs the network. |
| `voiceQualityRank` | top-level function | B | Rank a voice's quality; -1 when the engine did not say. |
| [`compareJapaneseVoices`](#comparejapanesevoices) | top-level function | A | Order Japanese voices best-first. |
| `sortJapaneseVoices` | top-level function | B | Return a sorted copy of a voice list. |

## Documentation

### `int compareJapaneseVoices(Map<String, String> a, Map<String, String> b)` <a id="comparejapanesevoices"></a>

- **Kind:** top-level function
- **Purpose:** Order Japanese voices best-first.
- **Inputs:** Two voice maps as `TtsBackend.voices()` returns them.
- **Returns:** `int` for `List.sort`.
- **Side effects:** None.
- **Algorithm:** Four keys in order: installed before missing, offline before network, higher quality
  first, then the engine's own name.
- **Usage:** `sortJapaneseVoices`, and through it `TtsService._loadVoices` and the picker.
- **Notes:** Each key earns its place. A voice flagged `notInstalled` can be selected and then
  produces silence, so it must never be the default. A network voice works but is slower and sends
  the text off the device, which the app avoids wherever it has a choice. Quality is the engine's own
  word for it. The name is last so the order is **total**: without it two voices the engine described
  identically could swap places between runs, and the numbers in the picker would move with them.
  Fields are all optional — a voice from a desktop engine may carry none of them, and then only the
  name decides.

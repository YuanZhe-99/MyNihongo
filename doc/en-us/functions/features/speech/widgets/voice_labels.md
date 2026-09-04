# lib/features/speech/widgets/voice_labels.dart

Turns an engine voice map into something a learner can read. Engine voice names are identifiers —
`ja-jp-x-jab#male_1-local` — and they differ between engines, so the app numbers the ordered list
instead and describes what is different about each entry.

Consumers: `voice_picker_sheet.dart`, `speech_settings_tiles.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`voiceDisplayName`](#voicedisplayname) | top-level function | A | Name a voice by its position in the ordered list. |
| `voiceQualifiers` | top-level function | B | Say what is different about a voice: availability, then quality. |
| `voiceDefaultLabel` | top-level function | B | Name the automatic choice and which voice it resolved to. |
| `_engineNames` | top-level constant | B | Known Android speech engines, so a brand shows instead of a package name. |
| `engineDisplayName` | top-level function | B | Name a speech engine for a menu. |

## Documentation

### `String voiceDisplayName(AppLocalizations l10n, List<Map<String, String>> voices, int index)` <a id="voicedisplayname"></a>

- **Kind:** top-level function
- **Purpose:** Name a Japanese voice in a way a learner can act on.
- **Inputs:** `l10n`; `voices`, already ordered by `sortJapaneseVoices`; the `index` being named.
- **Returns:** "Japanese voice 1", "Japanese voice 2", and so on.
- **Side effects:** None.
- **Algorithm:** One-based position in the ordered list.
- **Usage:** The voice row in Settings, and every row of the picker sheet.
- **Notes:** The engine's own name is an identifier, not a name: it says nothing about how the voice
  sounds, and the same voice is called something different on another engine. The number is stable
  only because the order is total — see
  [`../models/voice_ordering.md`](../models/voice_ordering.md). The raw name is still shown, in a
  smaller line in the picker, because it is what a bug report and the system speech settings need.

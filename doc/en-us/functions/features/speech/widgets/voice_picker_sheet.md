# lib/features/speech/widgets/voice_picker_sheet.dart

The bottom sheet that lists every Japanese voice with a readable name, what is different about it,
its raw engine name, and a button that speaks a sample with it.

It replaced a dropdown of engine identifiers, which could not be used for the one thing a voice
choice is about: hearing the difference. Listening and choosing are separate acts here —
`TtsService.preview` restores the learner's own voice afterwards, so auditioning never silently
changes what the app speaks with.

Opened from the Japanese voice row in Settings → Speech, which appears only when the engine offers
more than one Japanese voice.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`showVoicePickerSheet`](#showvoicepickersheet) | top-level function | A | Show the picker and report each choice. |
| `_VoicePickerSheet` | class | B | The sheet's own widget, so a choice redraws without rebuilding Settings. |
| `_choose` | method | B | Apply a choice and keep the sheet open. |
| `build` | method | B | Build the automatic row and one row per voice. |
| `_voiceRow` | method | B | Build one voice row with its sample button. |

## Documentation

### `Future<void> showVoicePickerSheet(BuildContext context, {required String previewText, required String? selected, required ValueChanged<String?> onChanged})` <a id="showvoicepickersheet"></a>

- **Kind:** top-level function
- **Purpose:** Let the learner hear each Japanese voice and choose one.
- **Inputs:** `previewText` — the sample every voice speaks; `selected` — the chosen voice name, or
  null for automatic; `onChanged` — called on every choice.
- **Returns:** A future completing when the sheet closes.
- **Side effects:** Shows a modal bottom sheet; speaks while it is open.
- **Algorithm:** A `RadioGroup` over an automatic row plus one row per voice from
  `TtsService.japaneseVoices`, which is already ordered. Each row shows the numbered name, the
  qualifiers, the raw engine name, and a play button calling `TtsService.preview`.
- **Usage:** `speech_settings_tiles.dart`.
- **Notes:** The sheet stays open after a choice on purpose: a learner comparing two voices should
  not have to reopen it between them. It is capped at 70% of the screen so it never covers the whole
  app on a phone. `onChanged` fires per choice rather than once at close, so the setting is applied
  the moment it is made and nothing is lost if the sheet is dismissed by a swipe.

# lib/features/speech/widgets/speech_settings_tiles.dart

The Settings rows that configure spoken Japanese: the speaking-rate slider with its preview button,
the Japanese voice dropdown, and — when the device has no Japanese voice — the notice and the button
that opens the system speech settings.

Kept out of `settings_page.dart` because the section is self-contained and that file is already
long. Preferences are read from `appSettingsProvider`, the same place every other preference lives.

Consumers: `settings_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SpeechSettingsTiles` | class | B | The Settings → Speech section. |
| `previewText` | static const | B | The greeting the preview button speaks. |
| [`SpeechSettingsTiles.build`](#build) | method | A | Build the speech settings rows. |
| `_openSettings` | method | B | Send the user to the platform's speech settings, reporting failure in a snack bar. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build either the two configuration rows or the missing-voice notice.
- **Inputs:** The build context and ref; reads `appSettingsProvider` and `TtsService.instance`.
- **Returns:** `Widget`.
- **Side effects:** None until a control is used.
- **Algorithm:** With no Japanese voice there is nothing to configure, so the rate and voice rows
  are replaced by an explanation and, where a deep link exists, a button. Otherwise: a slider from
  `TtsService.minRate` to `maxRate` in six divisions with a preview button, and a voice dropdown
  shown only when the engine offers more than one Japanese voice.
- **Usage:** `settings_page.dart`, as the whole Speech section.
- **Notes:** The dropdown's null entry is the engine default, and it is the value stored when the
  user has expressed no preference. On Apple platforms, where no deep link exists, the notice gains
  a sentence naming the settings pane instead of a button.

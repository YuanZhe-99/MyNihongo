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
| [`initState`](#initstate) | method | A | Ask what the recognizer can do **without** prompting for the microphone. |
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

### `void initState()` <a id="initstate"></a>

- **Kind:** method
- **Purpose:** Find out what the recognizer can do, without asking for the microphone.
- **Inputs:** None.
- **Returns:** None.
- **Side effects:** Checks the microphone permission; initializes the recognizer **only** when it has
  already been granted.
- **Algorithm:** Give up immediately where the platform has no recognizer; otherwise check the
  permission, and only then call `ensureAvailable()`.
- **Usage:** The Settings page.
- **Notes:** The permission check comes first, and that ordering is the whole point. Initializing the
  recognizer is what makes Android raise the microphone prompt, so the earlier version — which called
  `ensureAvailable()` unconditionally — produced a system dialog the moment Settings opened, with no
  explanation in front of it. That is exactly what
  [`../../../../features/pronunciation.md`](../../../../features/pronunciation.md) promises never
  happens; the practice sheet's own rationale dialog is the only place the prompt should come from.
  Found on a real phone, which is the only way it could be found — the test host has no permission
  model. The status line consequently has **three** states: available, missing, and not yet checked.
  Reporting "missing" for the third would tell a perfectly capable phone that it cannot listen.
  `test/speech_settings_tiles_test.dart` asserts that the backend is never initialized while the
  permission is absent.

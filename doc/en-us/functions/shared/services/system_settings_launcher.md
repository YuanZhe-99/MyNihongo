# lib/shared/services/system_settings_launcher.dart

Opens the platform's own speech settings, so "no Japanese voice installed" can be an action rather
than only a statement.

Consumers: `speech_settings_tiles.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `SystemSettingsLauncher` | class | B | Deep links into platform settings screens. |
| [`openSpeechSettings`](#openspeechsettings) | static method | A | Open the system speech settings. |

## Documentation

### `static Future<bool> openSpeechSettings()` <a id="openspeechsettings"></a>

- **Kind:** static method
- **Purpose:** Send the user where a Japanese voice can be installed.
- **Inputs:** None.
- **Returns:** `false` when the platform has no deep link, or when opening it failed.
- **Side effects:** Sends the user to another app.
- **Algorithm:** Gated on `canOpenSystemSpeechSettings`. Android goes through the app's one method
  channel, `com.yuanzhe.my_nihongo/system`, whose handler in `MainActivity` fires the
  `com.android.settings.TTS_SETTINGS` intent and answers whether an activity took it. Windows hands
  `ms-settings:speech` to `explorer.exe`, which is how a `ms-settings:` URI is opened without a
  URL-launcher plugin.
- **Usage:** The Settings → Speech missing-voice notice.
- **Notes:** Never throws — a failure is a `false`, so the caller shows a message instead. Whether
  the Windows URI handler actually opened the pane cannot be observed from the exit code, so a
  clean launch of `explorer.exe` is treated as success.

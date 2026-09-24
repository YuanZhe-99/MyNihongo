# lib/shared/utils/platform_capabilities.dart

The one place in `lib/` that branches on the platform. Nine top-level getters answer "can this
platform do X", and every one of them reads `defaultTargetPlatform` rather than `dart:io`'s
`Platform`, so a widget test reaches any branch through `debugDefaultTargetPlatformOverride`. That
matters here: the project's only development host is Windows, and the Android-only behaviours would
otherwise be untestable.

The module imports nothing but `package:flutter/foundation.dart`. Adding a platform branch anywhere
else in `lib/` is a bug: name the capability, put the getter here, and call it by name — the same
rule `adaptive_layout.dart` applies to width comparisons. See
[../../../platform-notes.md](../../../platform-notes.md) for the platform facts behind each answer.

Consumers: `settings_page.dart` (`showsStorageLocation`), the speech service and settings tiles,
the on-device AI service and settings tiles, `sentence_analyzer.dart`, `system_settings_launcher.dart`,
the reminder service and settings tiles (`platformSchedulesReminders`,
`platformRemindsFromInsideTheApp`), and `webdav_config_page.dart` (`platformAsksForLocalNetwork`).
`test/platform_capabilities_test.dart` pins every getter at every `TargetPlatform`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `isMobilePlatform` | top-level getter | B | Report whether the app is running on a phone or tablet (Android or iOS). |
| `isDesktopPlatform` | top-level getter | B | Report whether the app is running on a desktop (the complement of `isMobilePlatform`). |
| [`showsStorageLocation`](#showsstoragelocation) | top-level getter | A | Decide whether Settings shows the storage location row. |
| `canOpenSystemSpeechSettings` | top-level getter | B | Report whether a deep link to the system speech settings exists (Android, Windows). |
| `platformMayRecognizeSpeech` | top-level getter | B | Report whether speech recognition can exist on this platform at all. |
| `platformMayHaveOnDeviceModel` | top-level getter | B | Report whether an on-device generative model can exist here — Android only, because AICore does not exist elsewhere. |
| `platformSchedulesReminders` | top-level getter | B | Report whether the operating system fires reminders itself (Android, iOS), so they arrive while the app is closed. |
| `platformRemindsFromInsideTheApp` | top-level getter | B | Report whether reminders must come from a timer inside the running app (Windows, macOS, Linux). |
| `platformAsksForLocalNetwork` | top-level getter | B | Report whether the system asks the user before the app reaches the local network (iOS, macOS), so a failed WebDAV test can say so. |

## Documentation

### `bool get showsStorageLocation` <a id="showsstoragelocation"></a>

- **Kind:** top-level getter
- **Purpose:** Decide whether Settings → Data builds the storage location row.
- **Inputs:** None; reads `defaultTargetPlatform`.
- **Returns:** `false` on Android and iOS, `true` everywhere else.
- **Side effects:** None.
- **Algorithm:** `!isMobilePlatform`.
- **Usage:** `settings_page.dart` — both the row itself and `_loadStoragePath`, which does not read
  the disk when the row will not be built.
- **Notes:** Only the *display* is platform-dependent. `NihongoStorage.getAppDir()` and the custom
  storage path work identically on every platform; on a phone the resolved path names an app
  sandbox the user can neither browse to nor act on, so showing it is noise. Hiding the row also
  removes the only place a phone would print a filesystem path to the screen.

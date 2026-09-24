# Platform Notes

Android is the only shipped platform in Phase 1. The code is platform-neutral; the other targets are
listed at the end with what adding each involves.

## Android

- Package `com.yuanzhe.my_nihongo`, launcher label `MyNihongo!!!!!`, `MainActivity` is a plain
  `FlutterActivity`.
- **Gradle/AGP state is mirrored from MyAnime!!!!!'s verified configuration** rather than the
  `flutter create` template, so the plugin family the series shares is known to build: Gradle
  wrapper `9.3.1`, AGP `9.1.1`, Kotlin `2.2.20` declared (`apply false`) in `settings.gradle.kts`,
  the app itself no longer applies `kotlin-android`, Java 17 with core-library desugaring, and a
  top-level `kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }` block — deliberately
  **not** `jvmToolchain` (needs a real JDK 17 install) and **not** `kotlinOptions` (removed).
  `android/gradle.properties` keeps the Flutter-migrator compat flags `android.builtInKotlin=false`
  and `android.newDsl=false`, because several plugins still apply the Kotlin Gradle Plugin directly;
  `builtInKotlin=true` breaks every one of them.
- **`file_picker` is pinned to exactly `10.3.7`** (not a caret constraint), because it is
  the last release that both applies KGP itself (required while `builtInKotlin=false`) and compiles
  against `flutter.compileSdkVersion` (required by AGP 9 AAR metadata checks). `10.3.9+` and `11.x`
  rely on AGP's built-in Kotlin and fail in compat mode; `10.3.2` and older pin `compileSdk 34` and
  fail the metadata check.
- Keystore properties use nullable casts (`as String?`); signing is optional locally via
  `android/key.properties` and comes from GitHub Secrets in CI. `key.properties` and `*.jks` are
  git-ignored.
- **Permissions:** `INTERNET` only (WebDAV sync). `RECORD_AUDIO` arrives with Phase 2's speech
  recognition and is requested at first use with a rationale, never at install. On-device AI needs
  **no** permission: the network use behind it is the AICore system service's, not the app's.
- **`minSdk` is 26, not `flutter.minSdkVersion`** (24). The ML Kit GenAI libraries require API 26 and
  nothing else in the app does; the value is set explicitly in `android/app/build.gradle.kts` with
  the reason next to it.
- **Two method channels**, both registered by `MainActivity`:
  `com.yuanzhe.my_nihongo/system` (open the system speech settings) and
  `com.yuanzhe.my_nihongo/genai` (`GenAiChannel`, the bridge to AICore). Both exist instead of a
  plugin because each is a small surface, and every extra Flutter plugin is another one that may
  apply the Kotlin Gradle Plugin — the constraint that already pins `file_picker` and
  `speech_to_text`.
- **On-device AI dependencies:** `com.google.mlkit:genai-prompt:1.0.0-beta4`,
  `com.google.mlkit:genai-proofreading:1.0.0-beta1` and
  `org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2`, all pinned exactly because the ML Kit
  GenAI APIs are beta with no deprecation policy. The `genai-prompt` pin is a floor for what the
  app can *ask* — a named model variant — and says nothing about what any device answers; that is
  probed at run time. See [`android-aicore.md`](android-aicore.md).
- **`android/app/proguard-rules.pro` exists only for ML Kit GenAI.** R8 shrinks it into a runtime
  `NullPointerException` that reads, from the app, as "this device does not support AI" — and only in
  a release build, so the debug build hides it. The rules keep `com.google.mlkit.**` and
  `com.google.android.gms.internal.mlkit_**`; keeping just the `genai` packages is not enough,
  because the failing frame was in ML Kit's shared SDK internals. Found on a Pixel 10; the reasoning
  is written out in `android-aicore.md`.
- **Folding:** the activity's `configChanges` includes
  `screenLayout|screenSize|smallestScreenSize|density`, so unfolding resizes the window without
  recreating the activity. See [`adaptive-layout.md`](adaptive-layout.md).
- **Cleartext traffic** is allowed (`usesCleartextTraffic="true"`) so a WebDAV server on a home
  network over plain HTTP works, as in the sibling apps.

## App icon

- Source artwork: `assets/icon/app_icon.png` (square, transparent background). It is not bundled into the
  app; only launcher assets ship.
- `tool/generate_ios_icons.dart` scales the artwork into the iOS safe area and writes the three
  iOS sources `assets/icon/app_icon_ios.png` (opaque, white background), `app_icon_ios_dark.png`
  (transparent, slightly brightened) and `app_icon_ios_tinted.png` (transparent grayscale), plus
  review previews under `build/icon_preview/`.
- `flutter_launcher_icons.yaml` then generates the Android mipmaps and the iOS `AppIcon.appiconset`
  with default, dark and tinted entries. Regenerate after changing the artwork:

```bash
dart run tool/generate_ios_icons.dart
dart run flutter_launcher_icons
```

- The same source produces the Windows `.ico` and the macOS `AppIcon.appiconset`; the
  `flutter_launcher_icons` config enables all four platforms.
- The `ios/` folder carries the icon set and `CFBundleDisplayName` `MyNihongo!!!!!`; see *iOS*
  below.

## Windows

Windows is built by CI on release tags and manual dispatches — an x64 and an ARM64 installer (see
[`ci-cd.md`](ci-cd.md)) — and is this project's local development and testing target.

- `windows/` was generated with `flutter create --platforms=windows,macos .`; `CMakeLists.txt`
  (`BINARY_NAME my_nihongo`) and `Runner.rc` come out of the template already carrying the org and
  project name. Only `runner/main.cpp` is edited.
- **Single instance:** `main.cpp` takes the named mutex `MyNihongo_SingleInstance_A1B2C3D4`; a
  second launch restores and focuses the existing window instead of opening a duplicate. The lookup
  passes the runner's window class (`FLUTTER_RUNNER_WIN32_WINDOW`) as well as the title, so it
  cannot match an unrelated window.
- **Initial window 1000×720**, not the siblings' phone-shaped 400×860: at that width the reference
  lists and the settings page are already two-column, which is the layout worth looking at on a
  desktop. See [`adaptive-layout.md`](adaptive-layout.md).
- **Icon:** `windows/runner/resources/app_icon.ico`, generated by `flutter_launcher_icons` at
  `icon_size: 256` from the same `assets/icon/app_icon.png` as every other platform.
- **Installer:** `installer.iss` at the repository root, built with Inno Setup. One script produces
  both architectures — `iscc installer.iss` for x64, `iscc /DARM64 installer.iss` for ARM64 — and
  writes to `build/installer/`. It has no `[Registry]` block: the app claims no file type. Its
  three version fields move with `pubspec.yaml`, and `test/release_versions_test.dart` fails when
  they do not.
- **MSIX:** `msix_config` in `pubspec.yaml` exists for parity with the sibling apps' version
  locations. No workflow builds an MSIX; `dart run msix:create` is a manual step.
- **ARM64:** stable 3.44.2 builds `windows-arm64`, so no job uses Flutter master. The target
  architecture follows the Dart SDK's own architecture, not a flag: an ARM64 host builds
  `build/windows/arm64/` and only the ARM64 installer. CI gets an ARM64 Dart SDK by cloning Flutter
  at the stable tag on the ARM64 runner; `ci-cd.md` has the reason.
- **Unsigned.** The installers are not code-signed. Windows SmartScreen shows "Windows protected
  your PC" on first run; *More info → Run anyway* installs it. The same is true of every sibling
  app's installer.

## Speech plugins

- **`flutter_tts: ^4.2.5`** and **`speech_to_text: 7.4.0`**, both resolved and built against this
  project's Gradle state. Both still apply the Kotlin Gradle Plugin themselves, which is what
  `android.builtInKotlin=false` requires — the same constraint that pins `file_picker`. The Android
  build prints Flutter's "plugins that apply KGP" warning for `file_picker`, `flutter_tts`,
  `package_info_plus`, `speech_to_text` and `wakelock_plus`; it is plugin-side and unfixable here.
- **`flutter_tts` overwrites the engine language behind the app's back**, in two places in its
  Android plugin: its init callback replays queued method calls and *then* sets the language to the
  system default voice's locale, and `speak` silently rebuilds the `TextToSpeech` instance when the
  service connection has dropped. Neither is visible from Dart. `TtsService` works around both — a
  probe before the first write, a re-apply before every utterance, and an explicit voice rather than
  only a language. The reasoning is in `features/pronunciation.md`; do not remove any of the three
  without reading it.
- **The manifest declares a `<queries>` entry for `com.google.android.aicore`.** Android 11+ package
  visibility otherwise hides it, and the app cannot read which AICore build is installed — the fact
  that separates an unsupported device from an out-of-date service. See `android-aicore.md`.
- **`speech_to_text` is pinned exactly.** Its main branch has already dropped `kotlin-android` for
  AGP's built-in Kotlin, so a caret constraint would break the Android build the first time a new
  release lands.
- `flutter_tts` declares `compileSdk 36` and `minSdk 24`; both are satisfied by
  `flutter.compileSdkVersion` and `flutter.minSdkVersion` here.
- **Neither plugin injects a permission.** The merged manifest after a debug build carries only
  `INTERNET`, so `RECORD_AUDIO` and the recognizer `<queries>` entry are the app's to declare. The
  Bluetooth permissions `speech_to_text`'s README lists are for headset routing and are deliberately
  not declared.

### Windows prerequisite: `nuget.exe`

`flutter_tts`'s Windows CMake calls `nuget install Microsoft.Windows.CppWinRT` and fails the
configure step with `nuget.exe not found` when it is missing. Install it once per development
machine:

```powershell
winget install --id Microsoft.NuGet --exact
```

It has to be on `PATH` before `flutter build windows`. Nothing else in the project needs it.

With Visual Studio 18 (MSVC 14.51 and later) a build also needs
`CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` in the environment:
`flutter_local_notifications_windows` still includes the deprecated `<experimental/coroutine>`
header, which that compiler turns into an error. CI sets the same variable.

## macOS

- `macos/` is **compiled by CI and has never run**: no Mac available to this project can build it.
  Every statement below about runtime behaviour on a Mac is read from the plugin and Apple sources,
  not observed. The DMG is unsigned and unnotarised: Gatekeeper refuses it on first open, and the
  user allows it in System Settings → Privacy & Security → *Open Anyway*.
- `Runner/Configs/AppInfo.xcconfig`: `PRODUCT_NAME = MyNihongo!!!!!`,
  `PRODUCT_BUNDLE_IDENTIFIER = com.yuanzhe.myNihongo` (the same identifier as iOS).
- `MACOSX_DEPLOYMENT_TARGET = 13.0`, matching the sibling apps.
- Icons come from `flutter_launcher_icons` into `Runner/Assets.xcassets/AppIcon.appiconset`.

Entitlements, with the reason for each. `Release.entitlements` and `DebugProfile.entitlements`
carry the same set, except that the debug file keeps the template's `cs.allow-jit` and
`network.server`, which the debugger's VM service needs.

| Entitlement | Why |
|---|---|
| `app-sandbox` | The template's default; every sibling ships sandboxed |
| `network.client` | WebDAV sync. Without it in `Release`, sync fails only in release builds |
| `device.audio-input` | The microphone, for pronunciation practice |
| `files.user-selected.read-write` | The ZIP export and import pickers. Without it `file_picker` 10.3.7 returns `ENTITLEMENT_NOT_FOUND`, the Dart side receives `null`, and the Settings rows silently do nothing |

**`network.server` is deliberately absent from `Release`.** The siblings need it for their local
API server; this app listens on nothing.

`Info.plist` carries `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` and
`NSLocalNetworkUsageDescription`. The last one is for WebDAV sync to a server on the local network;
see *Apple network access* below.

Reminders on macOS go through `local_notifier`, the same path as Windows: `platformSchedulesReminders`
is mobile-only, so the Darwin branch of `flutter_local_notifications` is never reached on a Mac. See
[`features/reminders.md`](features/reminders.md).

## iOS

- `ios/` is **compiled by CI with `--no-codesign` and has never run**, for the same reason as
  macOS. `IPHONEOS_DEPLOYMENT_TARGET = 13.0`.
- `CFBundleDisplayName` is `MyNihongo!!!!!` in `Info.plist`; icons as in *App icon* above.
- `Info.plist` carries `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` and
  `NSLocalNetworkUsageDescription`, with the same text as macOS.
- `AppDelegate.swift` sets the notification-centre delegate to the app delegate, the line MyDay
  ships. It is not what makes reminders work — scheduling and delivery need no delegate, and neither
  the plugin nor the engine sets one. It only lets a reminder banner appear while the app is in the
  foreground. `FlutterAppDelegate` already conforms to `UNUserNotificationCenterDelegate`.
- **The IPA is a sideload build**: unsigned, so it installs only through a sideloading tool that
  re-signs it with the user's own Apple ID. An App Store build needs signing and provisioning, which
  CI does not do.
- Speech recognition on Apple can refuse an offline-only request when the device has no on-device
  model for Japanese; see [`features/pronunciation.md`](features/pronunciation.md).

### Apple network access

- **App Transport Security does not apply to this app's sync**, so `Info.plist` has no
  `NSAppTransportSecurity` block. ATS governs Apple's URL Loading System. WebDAV traffic here goes
  `package:http` → `IOClient` → `dart:io` sockets, and Dart's own plist-driven network policy was
  reverted in Flutter 2.2; this repository's Dart SDK has no insecure-connection check. The iOS
  engine still parses an `NSAppTransportSecurity` block, but nothing enforces the result, so a key
  would read as a policy while doing nothing. An `http://` WebDAV server is therefore not blocked,
  and if plain HTTP to a public host is ever to be refused, that is validation in the WebDAV page.
- **Local-network privacy does apply.** Per Apple's documentation (TN3179), it covers BSD sockets
  too — iOS 14 and later, macOS 15 and later — and fires for a local address over HTTPS as much as
  over HTTP. The first connection to a LAN server shows a system alert; `dart:io` cannot wait for
  the answer, so that first sync can fail and succeed on retry once access is allowed. This is from
  Apple's documentation and has not been observed on a device here.

## Distribution: nothing outside Android is signed

Every desktop and Apple artefact the release attaches is **unsigned and unnotarised**. What the
user sees: Windows SmartScreen's "Windows protected your PC" (*More info → Run anyway*), macOS
Gatekeeper's refusal (*Open Anyway* in Privacy & Security), and an IPA that only a sideloading tool
installs. Signing needs certificates this project does not hold; the sibling apps ship the same way.

## Platform branches in Dart

`lib/shared/utils/platform_capabilities.dart` is the **only** file in `lib/` that branches on the
platform. It reads `defaultTargetPlatform`, never `dart:io`'s `Platform`, so every branch is
reachable from a widget test through `debugDefaultTargetPlatformOverride` — which matters on a
project whose one development host is Windows.

| Getter | True when | Used for |
|---|---|---|
| `isMobilePlatform` | Android, iOS | the family checks below |
| `isDesktopPlatform` | Windows, macOS, Linux, Fuchsia | — |
| `showsStorageLocation` | not mobile | Settings → Data hides the storage path on a phone, where it names a sandbox the user can neither browse nor act on. The custom storage path itself still works everywhere; only the display is hidden |
| `canOpenSystemSpeechSettings` | Android, Windows | offering "install a Japanese voice" as an action instead of as text |
| `platformMayRecognizeSpeech` | not Linux or Fuchsia | a coarse gate; whether a recognizer is really present is a runtime question |
| `platformMayHaveOnDeviceModel` | Android | AICore exists nowhere else; Settings omits the On-device AI section elsewhere, and the analyser attaches no enhancer. Whether a given Android device can actually serve a model is a runtime question |
| `platformSchedulesReminders` | Android, iOS | reminders go through `flutter_local_notifications`, scheduled by the operating system |
| `platformRemindsFromInsideTheApp` | Windows, macOS, Linux | reminders go through `local_notifier` from a timer while the app runs |

`test/platform_capabilities_test.dart` pins every getter at every `TargetPlatform`, so a change to
one cell of this table is a one-line change there.

## Other platforms

- **Web** is not targeted.

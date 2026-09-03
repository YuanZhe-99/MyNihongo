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
  recognition and is requested at first use with a rationale, never at install.
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

- The `ios/` folder exists so the icon set has a home and `CFBundleDisplayName` is already
  `MyNihongo!!!!!`; iOS is otherwise still a planned platform and CI does not build it.

## Planned platforms

- **Windows:** `flutter create --platforms=windows .`, then the series' `installer.iss` (x64 and
  ARM64 via `#ifdef ARM64`), `msix_config` in `pubspec.yaml`, `windows/runner/resources/app_icon.ico`,
  and the version locations listed in `AGENTS.md`. The ARM64 CI job runs on Flutter master until
  stable ships an ARM64 engine, as MyAnime's does.
- **iOS / macOS:** `ios/` already exists (see *App icon*); add macOS with `--platforms=macos`;
  `AppInfo.xcconfig` name `MyNihongo!!!!!`; `com.apple.security.network.client` in both macOS
  entitlement files for WebDAV; the padded iOS icon sources are already generated.
- **Speech (Phase 2):** `flutter_tts` and `speech_to_text` wrap Android `TextToSpeech` /
  `SpeechRecognizer` and Apple `AVSpeechSynthesizer` / `SFSpeechRecognizer`; Windows has TTS via
  the same plugin but no bundled recogniser, so pronunciation feedback stays a mobile feature until
  one is chosen.
- **Web** is not targeted.

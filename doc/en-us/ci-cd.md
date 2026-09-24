# CI/CD and build commands

## Workflow

`.github/workflows/build.yml` runs on every push to `main`, on `v*` tag pushes, on pull requests targeting `main`, and on `workflow_dispatch`. Only tag pushes create a GitHub Release; branch pushes stop at the uploaded artifacts.

**What runs when.** The `android` job runs on every trigger, because it is where analyze and test
live. The four desktop and Apple jobs carry
`if: startsWith(github.ref, 'refs/tags/') || github.event_name == 'workflow_dispatch'`, so an
ordinary push or pull request spends one runner rather than five; a release tag, or a deliberate
dispatch, builds everything. The siblings build only on tags; this app keeps the per-push Android
job because its content files are data a wrong edit can break silently.

The checkout step passes `submodules: recursive`. Without it `flutter pub get` fails on the missing
`packages/myapps_data` path dependency. The relative submodule URL resolves to the public GitHub copy
in CI, so the default `GITHUB_TOKEN` is sufficient.

## Jobs

| Job | Runner | Runs on | Produces |
|---|---|---|---|
| `android` | `ubuntu-latest` | every trigger | `flutter gen-l10n` and the committed-localizations check, `flutter analyze`, `flutter test`, then the APK (full) and AAB (store) |
| `windows-x64` | `windows-latest` | tag, dispatch | `MyNihongo_X.Y.Z_Setup.exe` (Inno Setup) |
| `windows-arm64` | `windows-11-arm` | tag, dispatch | `MyNihongo_X.Y.Z_arm64_Setup.exe` (Inno Setup) |
| `ios` | `macos-latest` | tag, dispatch | `MyNihongo_sideload.ipa`, built `--no-codesign` |
| `macos` | `macos-latest` | tag, dispatch | `MyNihongo.dmg` |
| `release` | `ubuntu-latest` | tag only | a GitHub Release with the six files above and generated notes |

Android signing is configured only when the `KEYSTORE_BASE64` secret exists. **Every desktop and
Apple artefact is unsigned and unnotarised** — see [`platform-notes.md`](platform-notes.md) for what
a user sees when they open one.

**No MSIX job.** No sibling app has one, and packaging a Store MSIX needs a signing certificate this
repository does not hold (`install_certificate: false` in `msix_config` declines one).
`dart run msix:create` stays a manual command.

**The Windows ARM64 job clones Flutter at the stable tag** instead of using
`subosito/flutter-action`. Flutter publishes no Windows ARM64 SDK archive: the release manifest
`releases_windows.json` has no `dart_sdk_arch: arm64` row (counted 2026-09-06), and the action
defaults its `architecture` input to the runner's, so on `windows-11-arm` it aborts with "Unable to
determine Flutter version … architecture: arm64". Forcing `architecture: x64` is worse than the
abort. The x64 archive ships a populated `bin/cache`, so the Dart SDK is never replaced, and
`flutter build windows` takes its target from the Dart VM's own ABI — the build lands in
`build/windows/x64/`, which `iscc /DARM64` cannot find. A clone has no cache, so its first
`flutter` command runs `bin/internal/update_dart_sdk.ps1`, which on an ARM64 host fetches the ARM64
Dart SDK because, in that script's own words, Flutter Windows builds depend on the Dart
executable's architecture. The same script fetched this project's ARM64 development machine its
ARM64 Dart SDK for the same engine revision, which is the on-host evidence that the archive exists.
`--depth 1` at a tag is safe because `bin/internal/engine.version` is a tracked file there. A tag
clone is a detached HEAD, so `flutter doctor` reports the channel as `[user-branch]`, not `stable`.
A guard step fails the job if the build still lands in `x64/`, which is what an emulated x64 shell
would cause. No `actions/cache`: MyAnime caches its master clone weekly so the engine DLL's hash
stays stable for Defender's reputation, and a tag is already immutable.

**Both Windows jobs make sure `nuget` exists** before building, because `flutter_tts`'s Windows
CMake calls it and no sibling has that plugin. Both set
`CL: /D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`, because `windows/CMakeLists.txt`
builds with `/WX` and `flutter_local_notifications_windows` still reaches the deprecated
`<experimental/coroutine>` header. Both runners have a JDK, so the `jni` package's Windows branch
builds an inert `dartjni.dll` into the installer (pulled in by `path_provider_android`; nothing on
Windows loads it). This project's development machine has no JDK and never builds it.

**The iOS job is the first `pod install` in the series.** `flutter_tts` (iOS and macOS) and
`local_notifier` (macOS) ship only a podspec, so both Apple builds mix Swift Package Manager and
CocoaPods; the tool generates the Podfile. The macOS mix is what every sibling's `macos` job already
runs. No sibling's iOS plugin set needed CocoaPods, so an iOS failure after a Flutter upgrade is
most likely to be there.

**No job repeats `flutter gen-l10n`.** Every `flutter build` regenerates
`lib/l10n/app_localizations*.dart` from the ARB files before compiling
(`GenerateLocalizationsTarget` is a dependency of the kernel snapshot), triggered by `l10n.yaml`
and requiring `generate: true` in `pubspec.yaml`. The `android` job's explicit `gen-l10n` exists
for its check: **the committed generated files must match the ARB files**, tested with
`git status --porcelain -- lib/l10n`. Not `git diff`: the case that matters is a new locale's
generated file that was never added, which `git diff` does not list. It would pass analyze and test
here and break a fresh clone's `flutter test` on a missing import.

**The Apple projects are compiled by CI and never run.** No Mac available to this project can
build it, so CI compilation is the ceiling for iOS and macOS; see
[`platform-notes.md`](platform-notes.md).

**Nothing in CI touches AICore.** The on-device AI runs only on a real, supported phone, so what CI
verifies is the layer below it: the policy, the prompts and the parsing, all against fakes. The
model itself is checked by hand on a device — see [`android-aicore.md`](android-aicore.md).

## Workflow caveats

- Keep the workflow Flutter version (`3.44.2`) aligned with the Dart SDK constraint in
  `pubspec.yaml`. The Windows ARM64 job clones the tag of that same name, so one bump moves all
  five build jobs.
- GitHub `secrets` cannot be used directly in step `if` expressions; they are routed through the
  job-level `HAS_KEYSTORE` env.
- Action versions: `actions/checkout@v7`, `actions/setup-java@v5`, `actions/upload-artifact@v7`,
  `actions/download-artifact@v8`, `softprops/action-gh-release@v3`.
- **Validate workflow changes with a `workflow_dispatch` run before the next tag.** A dispatch
  runs the five build jobs; `release` is skipped until a tag, so its artefact filter is first
  exercised by the tag run itself, and a pushed tag cannot be pushed again.
- The analyze and test steps run in CI on purpose: the sibling apps run them locally only, but this
  app's content files are data that a wrong edit can break silently, and
  `test/content_catalog_test.dart` is the guard.
- `test/release_versions_test.dart` fails when the five version fields disagree. The release flow
  pushes the tag without waiting for CI, so run it locally before tagging; CI is the backstop.

## Commands

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter test test/content_catalog_test.dart
flutter build apk --release --dart-define=FLAVOR=full
flutter build appbundle --release --dart-define=FLAVOR=store
```

Desktop builds also run locally. **A Windows host builds only its own architecture**, for the
reason the ARM64 job above explains: this project's ARM64 development machine produces
`build/windows/arm64/` and the ARM64 installer, and the x64 installer comes from CI.

```powershell
$env:CL = "/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"   # MSVC 14.51+, as in CI
flutter build windows --release --dart-define=FLAVOR=full   # needs nuget.exe on PATH
iscc installer.iss          # x64 installer (x64 host), needs Inno Setup
iscc /DARM64 installer.iss  # ARM64 installer (ARM64 host)
dart run msix:create        # MSIX package, manual only
flutter build macos --release --dart-define=FLAVOR=full   # needs a Mac
```

On a connected Android phone, for anything that has to be seen or heard — the speech path and the
on-device AI. `adb` is not on `PATH` by default; it lives in the Android SDK's `platform-tools`.
`scrcpy` mirrors the screen, and needs `--no-audio` on a host with no audio device:

```powershell
flutter devices
flutter run --release -d <device-id> --dart-define=FLAVOR=full
scrcpy --no-audio
adb logcat | Select-String -Pattern "AICore|my_nihongo"
```

Use the narrowest relevant command set for verification. For model or sync changes, include
`flutter test test/progress_json_test.dart test/data_modules_test.dart`; for content changes,
`flutter test test/content_catalog_test.dart`; for layout changes, the three UI tests.

`flutter analyze` reports zero issues on a clean tree. Keep it that way — a new info-level item is a
regression here, not pre-existing noise.

## Fresh clone

The shared engine package is a git submodule, so a plain `git clone` leaves
`packages/myapps_data` empty and `flutter pub get` fails:

```bash
git clone --recurse-submodules <app-url>
# or, after a plain clone:
git submodule update --init
```

## `tool/` scripts

`tool/generate_ios_icons.dart` scales the app artwork into the iOS icon sources (see
`platform-notes.md`).

`tool/import_vocab.dart` regenerates `assets/content/vocab.json` from JMdict and the JLPT lists. It
is offline and deterministic: a re-run with unchanged inputs leaves an empty `git diff`, which is
the property that makes it worth re-running. It needs the JMdict body unpacked into the git-ignored
`tool/data/`, and prints the download URL and exits 1 when it is missing.

```bash
dart run tool/import_vocab.dart
dart run tool/import_vocab.dart --overlay-only
```

Neither script runs in CI. Both write files that are committed, so CI would only ever confirm what
the committed diff already shows.

## Golden transcripts

`test/golden/webdav_golden_test.dart` drives the real sync, backup and ZIP engines against an
in-memory WebDAV server and compares the recorded request sequence to files under
`test/golden/goldens/mynihongo/`. `flutter test` verifies them like any other test; nothing extra
runs in CI. Re-record deliberately after an intended protocol change, then read the diff:

```bash
flutter test --dart-define=GOLDEN_RECORD=true test/golden/webdav_golden_test.dart
```

The define must be literally `true`; `bool.fromEnvironment` reads `1` as false and the run stays
silently in verify mode. `test/golden/fake_webdav_server.dart` and `request_recorder.dart` are
copies of the shared package's harness — fix them there and copy again, never edit them here. The
transcripts are byte-compared, so the root `.gitattributes` pins them to LF.

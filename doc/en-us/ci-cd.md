# CI/CD and build commands

## Workflow

`.github/workflows/build.yml` runs on every push to `main`, on `v*` tag pushes, on pull requests targeting `main`, and on `workflow_dispatch`. Only tag pushes create a GitHub Release; branch pushes stop at the uploaded artifacts.

The checkout step passes `submodules: recursive`. Without it `flutter pub get` fails on the missing
`packages/myapps_data` path dependency. The relative submodule URL resolves to the public GitHub copy
in CI, so the default `GITHUB_TOKEN` is sufficient.

## Jobs

- `android` — `flutter pub get`, `flutter gen-l10n`, `flutter analyze`, `flutter test`, then the
  APK (full flavor) and the AAB (store flavor). Signing is configured only when the
  `KEYSTORE_BASE64` secret exists.
- `release` — on a tag push, downloads the artifacts and creates a GitHub Release with generated
  notes.

**CI stays Android-only on purpose.** The Windows and macOS projects exist for local development
and testing (see [`platform-notes.md`](platform-notes.md)); adding jobs for them, and the MSIX and
Inno Setup release artefacts, is Phase 5 work copied from MyAnime's workflow.

**Nothing in CI touches AICore.** The on-device AI runs only on a real, supported phone, so what CI
verifies is the layer below it: the policy, the prompts and the parsing, all against fakes. The
model itself is checked by hand on a device — see [`android-aicore.md`](android-aicore.md).

## Workflow caveats

- Keep the workflow Flutter version (`3.44.2`) aligned with the Dart SDK constraint in
  `pubspec.yaml`.
- GitHub `secrets` cannot be used directly in step `if` expressions; they are routed through the
  job-level `HAS_KEYSTORE` env.
- Action versions: `actions/checkout@v7`, `actions/setup-java@v5`, `actions/upload-artifact@v7`,
  `actions/download-artifact@v8`, `softprops/action-gh-release@v3`. Validate workflow changes with a
  `workflow_dispatch` run before the next tag release.
- The analyze and test steps run in CI on purpose: the sibling apps run them locally only, but this
  app's content files are data that a wrong edit can break silently, and
  `test/content_catalog_test.dart` is the guard.

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

Desktop builds are local only; nothing below runs in CI:

```powershell
flutter build windows --release --dart-define=FLAVOR=full   # needs nuget.exe on PATH
iscc installer.iss          # x64 installer, needs Inno Setup on PATH
iscc /DARM64 installer.iss  # ARM64 installer
dart run msix:create        # MSIX package
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

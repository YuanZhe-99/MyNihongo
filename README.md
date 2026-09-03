| Android  | AAB (`app-release.aab`) | store |
| Windows  | Installer (`MyNihongo_<ver>[_arm64]_Setup.exe`) | full |
| macOS    | `.app` bundle | full |

Only the Android artifacts are built by CI. Windows and macOS are local build targets for
development and testing; macOS has not been compiled (the development host is Windows).
| Windows  | Installer (`MyNihongo_<ver>[_arm64]_Setup.exe`) | full |
| macOS    | `.app` bundle | full |

Only the Android artifacts are built by CI. Windows and macOS are local build targets for
development and testing; macOS has not been compiled (the development host is Windows).
# MyNihongo!!!!! — Your Japanese Learning Companion

A clean, privacy-first Japanese learning app. Android first; Windows, iOS and macOS planned.

Part of the MyApps series alongside [MyAnime](https://github.com/YuanZhe-99/MyAnime),
[MyDay](https://github.com/YuanZhe-99/MyDay) and [MyDevice](https://github.com/YuanZhe-99/MyDevice),
sharing their sync, backup and data-management engine
([MyApps-DATA](https://github.com/YuanZhe-99/MyApps-DATA)).

## Features

**Available now (v0.1.0, Phase 1)**

- **Kana** — hiragana/katakana chart with gojūon, dakuten and yōon tables, search, and
  pronunciation rules. Two tables side by side on an unfolded foldable or a tablet in landscape.
  Tap a kana for its stroke count, the kana it is confused with, and words that start with it.
- **Vocabulary** — 7,744 words from N5 to N1, built from JMdict and the openly licensed JLPT
  lists. Search by kanji, reading, romaji or meaning; filter by JLPT level; example sentences with
  readings. Chinese glosses cover N5.
- **Grammar** — 81 N5 points, each with structure, meaning, explanation and examples; JLPT filter.
- **Cross-links** — a word shows the grammar its examples use, a grammar point shows the words in
  its examples, and a kana shows words that start with it.
- **Learning progress** — a synced record per studied item, ready for the review engine.
- **WebDAV sync, backup, ZIP export** — configure a server, sync by hand or automatically, resolve
  conflicts per record, keep local backups with a retention policy, and export a ZIP anywhere.
- **Foldable-aware layout** — one rule set decides when panes and columns appear; navigation moves
  to a side rail on wide windows.
- **Remembered per device** — the tab, the two level filters, the kana script and the column count.
- **Languages** — English and Simplified Chinese.

**Planned** — see [PLAN.md](PLAN.md): on-device pronunciation practice (Android speech recognition
and text-to-speech), a sentence analyser, spaced-repetition quizzes and step-by-step lessons, and
JLPT N5–N1 practice sets.

## Build Flavors

| Flavor | Description |
|--------|-------------|
| `full` | Direct distribution (GitHub Releases, APK) |
| `store` | Google Play compliant build |

The flavor is controlled via `--dart-define=FLAVOR=store|full` (default: `full`). No feature is
gated on it yet.

## Platforms

| Platform | Artifact | Flavor |
|----------|----------|--------|
| Android  | APK (`app-release.apk`) | full |
| Android  | AAB (`app-release.aab`) | store |
| Windows  | Installer (`MyNihongo_<ver>[_arm64]_Setup.exe`) | full |
| macOS    | `.app` bundle | full |

Only the Android artifacts are built by CI. Windows and macOS are local build targets for
development and testing; macOS has not been compiled (the development host is Windows).

## Build

```bash
git clone --recurse-submodules <repo-url>
cd MyNihongo
flutter pub get
flutter gen-l10n

# Android APK (direct distribution)
flutter build apk --release --dart-define=FLAVOR=full

# Android AAB (Google Play)
flutter build appbundle --release --dart-define=FLAVOR=store

# Windows (local only) — needs nuget.exe on PATH (winget install --id Microsoft.NuGet),
# and Inno Setup for the installers
flutter build windows --release --dart-define=FLAVOR=full
iscc installer.iss
iscc /DARM64 installer.iss

# macOS (local only, needs a Mac)
flutter build macos --release --dart-define=FLAVOR=full
```

After a plain clone, fetch the shared engine package with `git submodule update --init`.

## Verify

```bash
flutter analyze
flutter test
```

The vocabulary asset is generated. To rebuild it, download the JMdict body into the git-ignored
`tool/data/` (the tool prints the URL) and run:

```bash
dart run tool/import_vocab.dart
```

It is deterministic: a re-run with unchanged inputs leaves an empty `git diff`.

## Documentation

- [`doc/en-us/`](doc/en-us/) — architecture, data formats, adaptive layout, sync, CI. Start at
  its README. A Simplified Chinese mirror lives in [`doc/zh-cn/`](doc/zh-cn/).
- [`PLAN.md`](PLAN.md) — the phased roadmap and what is done.
- [`AGENTS.md`](AGENTS.md) — rules for contributors and agents.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

The bundled vocabulary is derived from [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html)
(© EDRDG, Monash University, CC BY-SA 4.0) joined to the JLPT lists from
[stephenmk/yomitan-jlpt-vocab](https://github.com/stephenmk/yomitan-jlpt-vocab) (CC BY-SA 4.0;
underlying lists by Jonathan Waller, CC BY). The same attribution appears in the app under
Settings › License.

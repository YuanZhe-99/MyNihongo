# MyNihongo!!!!! — Your Japanese Learning Companion

A clean, privacy-first Japanese learning app. Android first; Windows, iOS and macOS planned.

Part of the MyApps series alongside [MyAnime](https://github.com/YuanZhe-99/MyAnime),
[MyDay](https://github.com/YuanZhe-99/MyDay) and [MyDevice](https://github.com/YuanZhe-99/MyDevice),
sharing their sync, backup and data-management engine
([MyApps-DATA](https://github.com/YuanZhe-99/MyApps-DATA)).

## Features

**Available now (Phase 1 skeleton)**

- **Kana** — hiragana/katakana chart with gojūon, dakuten and yōon tables, search, and
  pronunciation rules. Two tables side by side on an unfolded foldable or a tablet in landscape.
- **Vocabulary** — browse and search by kanji, reading, romaji or meaning; filter by JLPT level;
  example sentences with readings.
- **Grammar** — patterns with structure, meaning, explanation and examples; JLPT filter.
- **Learning progress** — a synced record per studied item, ready for the review engine.
- **WebDAV sync, backup, ZIP export** — the series' shared engines are wired in (settings pages
  land in the next milestone).
- **Foldable-aware layout** — one rule set decides when panes and columns appear; navigation moves
  to a side rail on wide windows.
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
```

After a plain clone, fetch the shared engine package with `git submodule update --init`.

## Verify

```bash
flutter analyze
flutter test
```

## Documentation

- [`doc/en-us/`](doc/en-us/) — architecture, data formats, adaptive layout, sync, CI. Start at
  its README. A Simplified Chinese mirror lives in [`doc/zh-cn/`](doc/zh-cn/).
- [`PLAN.md`](PLAN.md) — the phased roadmap and what is done.
- [`AGENTS.md`](AGENTS.md) — rules for contributors and agents.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

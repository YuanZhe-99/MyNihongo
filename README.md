# MyNihongo!!!!! — Your Japanese Learning Companion

A privacy-first Japanese learning app: a reference you can browse, a study engine that
schedules what you nearly forgot, and speech and analysis that run on the phone. Android
first; Windows and macOS build locally, iOS is planned.

Part of the MyApps series alongside [MyAnime](https://github.com/YuanZhe-99/MyAnime),
[MyDay](https://github.com/YuanZhe-99/MyDay) and [MyDevice](https://github.com/YuanZhe-99/MyDevice),
sharing their sync, backup and data-management engine
([MyApps-DATA](https://github.com/YuanZhe-99/MyApps-DATA)).

**Nothing leaves the device** except WebDAV sync to a server you configure yourself. There is no
account, no telemetry, no cloud model and no ads.

## What it does

### Reference

- **Kana** — the gojūon, dakuten and yōon tables with search and pronunciation rules. Tap a kana
  for its stroke count, the kana it is confused with, and words that start with it.
- **Vocabulary** — 7,744 words from N5 to N1, built from JMdict and the openly licensed JLPT
  lists. Search by kanji, reading, romaji or meaning, and filter by level.
- **Grammar** — 331 points across N5, N4 and N3, each with structure, meaning, explanation and
  examples.
- **Kana over kanji** — readings printed above the characters that need them, everywhere Japanese
  appears. On by default, and it refuses rather than guessing when a reading cannot be aligned.
- **Cross-links** — a word shows the grammar its examples use, a grammar point shows the words in
  its examples, and a kana shows words that start with it.

### Study

- **Spaced repetition** — SM-2 over every item you answer, with two deliberate departures from the
  textbook that are derived in the docs rather than assumed.
- **Sixteen quiz modes** — meaning, written form, reading, listening, typing, kana, particles,
  conjugation, sentence ordering, grammar points, whole sentences either way, and filling a word
  into its own example. Each one is a switch you can turn off.
- **A lesson path** — the target level as units, each a topic with its own sentences and questions.
  A checkpoint opens the next unit, and a locked unit's checkpoint is still open, because that is
  how somebody who already knows the material skips ahead.
- **A study calendar** and a daily reminder, both off the same progress file. The reminder is off
  until you turn it on, and asks for notification permission at that moment and not before.

### Speech and analysis

- **Text to speech** — everything read aloud by the device's own engine, with a voice picker you
  can hear before choosing.
- **Pronunciation practice** — what you said compared with the reading, mora by mora. Recognition
  is offline unless you turn the network fallback on.
- **Sentence lab** — paste a sentence and see the words, what modifies what, the grammar it uses,
  and anything that looks unusual. A dictionary and a cost lattice, not a model.

### On-device AI (Android, off by default)

On a phone with Android AICore, and only with the switch on, the app can explain a finding in more
words, suggest a rewrite, say why a quiz answer was wrong, write extra example sentences, and give
a second opinion on a typed answer the string comparison rejected. Generated text is always
labelled, never becomes catalog content, and the deterministic answer always comes first.

### Everything else

- **WebDAV sync, backup, ZIP export** — sync by hand or automatically, resolve conflicts per
  record, keep local backups with a retention policy, and export a ZIP anywhere.
- **Foldable-aware layout** — one rule set decides when panes and columns appear; navigation moves
  to a side rail on wide windows.
- **English, Simplified Chinese and Traditional Chinese.**

## Content coverage

Grammar and Chinese glosses are filled level by level. The current state, as of `v0.3.0`:

| Level | Grammar points | Chinese glosses | Example sentences |
|---|---|---|---|
| N5 | 81 | 667 / 667 | 517 / 667 |
| N4 | 100 | 630 / 630 | 0 / 630 |
| N3 | 150 | 1,650 / 1,650 | 2 / 1,650 |
| N2 | — | 0 / 1,737 | 0 / 1,737 |
| N1 | — | 0 / 3,060 | 0 / 3,060 |

Every word carries an English meaning at every level; the table above is about the Chinese and the
example sentences, which are being written.

**How that content was made matters, so it is stated plainly.** The N5 grammar was written by hand.
Everything beyond it — the N4 and N3 points, the Chinese glosses, the example sentences and the
lesson units — was written by model agents against an automated gate and **has not been read by a
Japanese or Chinese speaker**. The gate proves a sentence parses against the app's own dictionary,
is read the way its reading says, and names ids that exist. It cannot prove the Japanese is
natural. Every such file records that in its `source` field, and
[`doc/en-us/features/content-authoring.md`](doc/en-us/features/content-authoring.md) says what the
checks cannot promise.

**Planned** — see [PLAN.md](PLAN.md): N2 and N1 grammar, scenario lessons, writing practice, and
JLPT N5–N1 practice sets.

## Build flavors

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
development and testing; macOS has not been compiled, because the development host is Windows.

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

## Content pipeline

The vocabulary asset is generated. To rebuild it from scratch, download the JMdict body into the
git-ignored `tool/data/` (the tool prints the URL) and run:

```bash
dart run tool/import_vocab.dart
```

It is deterministic: a re-run with unchanged inputs leaves an empty `git diff`. The Chinese glosses
and example sentences are overlays folded in by the same tool, and re-applying them needs no
download:

```bash
dart run tool/import_vocab.dart --overlay-only
dart run tool/convert_zh_tw.dart
```

Traditional Chinese in the content is **generated, never hand-edited**; a test fails both when the
tool has not been re-run and when a Traditional string was edited by hand.

New catalog content is written in batches against a gate that reports every problem in a draft at
once:

```bash
dart run tool/draft_inputs.dart gloss --level N2 --batch 300
CONTENT_DRAFT=tool/content/drafts/gloss/n2-01.json flutter test test/content_gate_test.dart
dart run tool/merge_drafts.dart gloss tool/content/drafts/gloss/n2-01.json
```

The whole loop is described in
[`doc/en-us/features/content-authoring.md`](doc/en-us/features/content-authoring.md).

## Documentation

- [`doc/en-us/`](doc/en-us/) — architecture, data formats, adaptive layout, sync, CI, and a page
  per feature and algorithm. Start at its README. A Simplified Chinese mirror lives in
  [`doc/zh-cn/`](doc/zh-cn/), updated in the same commit.
- [`PLAN.md`](PLAN.md) — the phased roadmap, what is done, and a decisions log with the reason for
  each choice.
- [`AGENTS.md`](AGENTS.md) — rules for contributors and agents.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

The bundled vocabulary is derived from [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html)
(© EDRDG, Monash University, CC BY-SA 4.0) joined to the JLPT lists from
[stephenmk/yomitan-jlpt-vocab](https://github.com/stephenmk/yomitan-jlpt-vocab) (CC BY-SA 4.0;
underlying lists by Jonathan Waller, CC BY). Everything written for this app, by hand or by model,
is GPL-3.0 with it. The same attribution appears in the app under Settings › License.

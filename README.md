# MyNihongo!!!!! — Your Japanese Learning Companion

A privacy-first Japanese learning app: a reference you can browse, a study engine that
schedules what you nearly forgot, and speech and analysis that run on the phone. Android
first; Windows, macOS and iOS builds come with every release.

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
- **Grammar** — 659 points across all five levels, each with structure, meaning, explanation and
  examples.
- **Kana over kanji** — readings printed above the characters that need them, everywhere Japanese
  appears. On by default, and it refuses rather than guessing when a reading cannot be aligned.
- **Cross-links** — a word shows the grammar its examples use, a grammar point shows the words in
  its examples, and a kana shows words that start with it.

### Study

- **Spaced repetition** — SM-2 over every item you answer, with two deliberate departures from the
  textbook that are derived in the docs rather than assumed.
- **Seventeen quiz modes** — meaning, written form, reading, listening, typing, kana, particles,
  conjugation, sentence ordering, grammar points, whole sentences either way, filling a word into
  its own example, and writing a whole sentence from its meaning. Each one is a switch you can
  turn off.
- **A lesson path** — every level as units, 65 of them, each a topic with its own sentences and
  questions. A checkpoint opens the next unit, and a locked unit's checkpoint is still open,
  because that is how somebody who already knows the material skips ahead.
- **Scenario lessons** — a scripted conversation at the end of a unit, read aloud, stopping to ask
  what you would say. A wrong reply does not end the conversation: it changes the tally at the end
  and nothing else.
- **Writing practice** — write a few sentences from a unit's prompt and have them parsed: which of
  the unit's words you used, how each sentence was read, and anything unusual.
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
words, suggest a rewrite of what you wrote, say why a quiz answer was wrong, write extra example
sentences, give a second opinion on a typed answer the string comparison rejected, and add up to
three extra questions to a unit session. Generated text is always labelled, never becomes catalog
content, and the deterministic answer always comes first — a generated question is asked for only
after the session is already on screen, and answering one never touches the review schedule.

### Everything else

- **WebDAV sync, backup, ZIP export** — sync by hand or automatically, resolve conflicts per
  record, keep local backups with a retention policy, and export a ZIP anywhere.
- **Foldable-aware layout** — one rule set decides when panes and columns appear; navigation moves
  to a side rail on wide windows.
- **English, Simplified Chinese, Traditional Chinese and Japanese** — in Japanese, words are
  defined in Japanese rather than translated.

## Content coverage

The catalog is complete, as of `v0.3.1`:

| Level | Grammar points | Lesson units | Chinese glosses | Example sentences |
|---|---|---|---|---|
| N5 | 81 | 9 | 667 / 667 | 667 / 667 |
| N4 | 100 | 12 | 630 / 630 | 630 / 630 |
| N3 | 150 | 14 | 1,650 / 1,650 | 1,650 / 1,650 |
| N2 | 170 | 15 | 1,737 / 1,737 | 1,737 / 1,737 |
| N1 | 158 | 15 | 3,060 / 3,060 | 3,059 / 3,060 |

The one gap is real and is left in: ＯＫ is written in fullwidth Latin and read オーケー, and the
analyser can reach it by neither spelling, so no example sentence for it could be checked.

**How that content was made matters, so it is stated plainly.** The N5 grammar was written by hand.
Everything beyond it — the N4 through N1 points, the Chinese glosses, the example sentences, the
lesson units and the scenario dialogues — was written by model agents against an automated gate and
**has not been read by a Japanese or Chinese speaker**. The gate proves a sentence parses against
the app's own dictionary, is read the way its reading says, and names ids that exist. It cannot
prove the Japanese is natural. Every such file records that in its `source` field, and
[`doc/en-us/features/content-authoring.md`](doc/en-us/features/content-authoring.md) says what the
checks cannot promise.

**Not built**, on purpose — see [`doc/en-us/decisions.md`](doc/en-us/decisions.md#not-built):
own-voice playback, and the checks only hardware can make. Problems are reported as bugs.

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
| Windows (x64)   | Inno Setup installer (`MyNihongo_<ver>_Setup.exe`) | full |
| Windows (ARM64) | Inno Setup installer (`MyNihongo_<ver>_arm64_Setup.exe`) | full |
| iOS      | Sideload IPA (`MyNihongo_sideload.ipa`) | full |
| macOS    | DMG (`MyNihongo.dmg`) | full |

CI builds all six on a release tag and attaches them to the GitHub Release; ordinary pushes build
only Android. The Windows, iOS and macOS artefacts are unsigned: Windows SmartScreen and macOS
Gatekeeper ask before the first launch, and the IPA installs only through a sideloading tool. The
iOS and macOS builds are compiled by CI and have not been run on Apple hardware. See
[`doc/en-us/platform-notes.md`](doc/en-us/platform-notes.md).

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

# Windows — needs nuget.exe on PATH (winget install --id Microsoft.NuGet), Inno Setup for the
# installers, and with MSVC 14.51+ the CL define below. A host builds only its own architecture.
# PowerShell: $env:CL = "/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"
flutter build windows --release --dart-define=FLAVOR=full
iscc installer.iss            # on an x64 host
iscc /DARM64 installer.iss    # on an ARM64 host

# macOS and iOS (need a Mac)
flutter build macos --release --dart-define=FLAVOR=full
flutter build ios --release --no-codesign --dart-define=FLAVOR=full
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
- [`doc/en-us/decisions.md`](doc/en-us/decisions.md) — the decisions log with the reason for each
  choice, what was left unbuilt, and the open questions. The phased roadmap it came from is retired.
- [`AGENTS.md`](AGENTS.md) — rules for contributors and agents.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

The bundled vocabulary is derived from [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html)
(© EDRDG, Monash University, CC BY-SA 4.0) joined to the JLPT lists from
[stephenmk/yomitan-jlpt-vocab](https://github.com/stephenmk/yomitan-jlpt-vocab) (CC BY-SA 4.0;
underlying lists by Jonathan Waller, CC BY). Everything written for this app, by hand or by model,
is GPL-3.0 with it. The same attribution appears in the app under Settings › License.

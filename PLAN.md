# PLAN.md — MyNihongo!!!!! roadmap

The phased plan for MyNihongo!!!!!, the Japanese learning app in the MyApps series. `AGENTS.md`
says how to work here; `doc/en-us/` says what the code does; this file says **what is planned, in
what order, why, and what is done**. Update the checklists in the same change that lands a
milestone item.

**Status as of 2026-09-04:** **Phase 3 is complete**, released as `v0.3.1` and polished by `v0.3.2` (M3.8 below — the on-device AI fix a Z Fold 8 found, plus history and a foldable layout for the two writing surfaces). Phase 3's milestones: M3.0 (device fixes), M3.1 (spaced repetition core), M3.2 (quiz modes), M3.3 (kana over kanji), M3.4 (the rest of the catalog), M3.5 (lesson path and reminders), M3.6 (AI-assisted practice) and M3.7 (scenario lessons, generated questions, writing practice routed) have all landed. The catalog is complete: grammar, Chinese glosses, example sentences and lesson units at every level from N5 to N1, with the coverage stated in `version-history.md`. What remains from Phase 3 is deliberately deferred rather than missing — the free-response translation mode and the scenario dialogue partner, both listed under M3.6. Phase 1 complete and released as `v0.1.0`. **Phase 2 complete:** M2.1
(text-to-speech), M2.2 (speech recognition and pronunciation feedback), M2.3 (the sentence lab),
M2.4 (on-device AI assist) and M2.5 (Traditional Chinese) have landed, along with the Windows and
macOS projects the pronunciation work needs a machine for. `v0.2.1` is the current release; M2.5 is
**unreleased and untagged on purpose** — it ships with Phase 3's `0.3.0`. Phase 3 is next.

A **Pixel 10** is now available for testing, which changes what "verified" can mean. M2.4 was checked
on it; **M2.1 and M2.2 still have not been heard on a device** — that is the largest remaining gap in
Phase 2, along with own-voice playback, which stays deferred with the reason in M2.2.

Two known gaps found while testing on the phone, neither in scope for M2.4:

- The token chips in the sentence lab print the recovered forms as their English enum names
  (`polite + negative`) in every language, because `InflectionForm` has no ARB strings. Visible to a
  Chinese reader; a Phase 3 fix, roughly 28 keys.
- Five words the shipped vocabulary lacks (母, 顔, 東京, 鞄 in kanji, 速い), tracked in
  `test/fixtures/sentence/allowed_unknown.json`.

M1.0 (skeleton) landed 2026-09-02; M1.1 (sync and backup UI), M1.2 (content pipeline), M1.3 (reference polish) and M1.4
(release) landed 2026-09-03. Two items carry over for want of hardware: the foldable screenshot
pass, and a sync against a real WebDAV server. `pubspec.yaml` says `0.1.0+1`.

---

## 1. Vision

A privacy-first Japanese learning companion that starts from the kana chart MyAnime!!!!! already
ships and grows into a full study tool: browse kana, vocabulary and grammar; hear and practise
pronunciation with the device's own speech engines; understand what a sentence is made of; learn
through spaced repetition and step-by-step lessons; and drill for JLPT N5 through N1. Progress
follows the user across devices through the same WebDAV sync, backup and ZIP engines the other apps
in the series use.

**What it borrows from the series:** the Flutter shell (`go_router` + `flutter_riverpod` +
`flex_color_scheme`), the `myapps_data` submodule for sync/backup/ZIP, the adaptive-layout rules for
foldables, the Function Explanation Layer, bilingual docs, two remotes, GPL-3.0.

**What is new:** a bundled read-only **content catalog** (kana, words, grammar, later drills)
separate from the user's synced **progress**; on-device speech; a sentence analyser; a lesson and
review engine; and, on devices that have it, on-device AICore assistance for writing practice, free
answers and explanations (Phases 2–4), always optional and never a substitute for the deterministic
baseline.

### Non-goals (for now)

- Kanji as a first-class study track (kanji appear through vocabulary; a dedicated kanji module
  is a candidate for Phase 3+).
- Any cloud AI, accounts, telemetry, or ads. Nothing leaves the device except WebDAV sync to the
  user's own server.
- Reproducing official JLPT past papers. Drill content is original or openly licensed.

---

## 2. Principles

1. **Series conventions first.** If MyAnime/MyDay/MyDevice already answered a question (layout
   rule, sync invariant, doc structure, release flow), reuse the answer. Divergences are written
   down, with the reason.
2. **Content is data.** Catalog files are versioned JSON assets with a schema version, bilingual
   text, JLPT level, and stable ids. Code never hardcodes a word list.
3. **Progress is the only synced user data**, one module (`nihongo_progress.json`), per-record
   three-way merge, conflicts shown to the user. New synced state is a new record kind or a new
   module — never a silent last-writer-wins.
4. **On-device by default.** Speech-to-text, text-to-speech and sentence analysis use Android's own
   engines or bundled algorithms. Anything that would send text or audio off the device is opt-in
   and disclosed in the privacy policy.
5. **Adaptive from day one.** Every page decides its layout through `adaptive_layout.dart`, is
   tested at the named foldable geometries, and has its decision recorded in
   `doc/en-us/adaptive-layout.md`.
6. **Android first, but platform-neutral code.** No `Platform.isAndroid` branches outside
   `platform-notes`-documented spots; desktop and iOS are `flutter create --platforms` away.
7. **Honest UI.** Features that are not built yet are not stubbed with fake data. The Learn tab
   lists what is coming; it does not pretend to review anything.

---

## 3. Architecture snapshot

See `doc/en-us/architecture.md` for the full picture. The parts the roadmap depends on:

```
lib/
  app/            app.dart · router.dart (5 tabs) · theme.dart · flavor.dart · data_modules.dart
  features/
    kana/         models/kana.dart (catalog) · views/kana_page.dart
    content/      models/{jlpt_level,localized_strings,vocab_entry,grammar_point,content_catalog}.dart
                  services/content_repository.dart (loads assets/content/*.json)
    vocab/        views/vocab_page.dart
    grammar/      views/grammar_page.dart
    learn/        views/learn_page.dart (dashboard now; lesson path in Phase 3)
    progress/     models/study_record.dart (synced) · services/nihongo_storage.dart (storage hub)
    settings/     views/{settings,license,privacy_policy}_page.dart
  shared/
    services/     webdav_service · backup_service · import_export_service · auto_sync_service · sync_merge
    utils/        adaptive_layout.dart
    widgets/      shell_scaffold · adaptive_tile_grid · reference_widgets
assets/content/   vocab.json (generated) · grammar/n5.json · kana_notes.json · vocab_zh.json
tool/             import_vocab.dart · src/vocab_import_core.dart · content/jlpt/n{1..5}.csv
packages/myapps_data   git submodule (shared engines)
```

Three kinds of data, three homes:

| Data | Where | Synced | Backed up |
|---|---|---|---|
| Content catalog (kana, words, grammar, drills) | `assets/content/`, compiled in | No — ships with the app | No |
| Learning progress (`StudyRecord` per item) | `nihongo_progress.json` | **Yes**, per record | Yes |
| Device preferences (theme, locale, storage path, backup settings) | `storage_config.json` | No | No |

Progress records are keyed `kana:<hiragana>`, `vocab:<slug>`, `grammar:<slug>`. **Shipped ids never
change** (see `AGENTS.md`, Behavior contract).

---

## 4. Phases

### Phase 1 — Reference app on Android (current)

Goal: a useful, releasable kana/vocabulary/grammar reference with sync and backup, on Android only.

#### M1.0 Project skeleton — **done 2026-09-02**

- [x] `flutter create` (Android), package `my_nihongo`, id `com.yuanzhe.my_nihongo`, name
      `MyNihongo!!!!!`
- [x] `myapps_data` submodule at `packages/myapps_data`, relative URL, now pinned to the `v1.0.2` tag
      (main after `v1.0.1`; docs-only delta)
- [x] Android config mirrored from MyAnime's verified state: Gradle 9.3.1, AGP 9.1.1,
      `builtInKotlin=false`, Java 17 desugaring, `configChanges` for folding
- [x] Shell: 5 tabs (Learn, Kana, Vocabulary, Grammar, Settings), bottom bar ↔ rail by
      `useNavigationRail`
- [x] `adaptive_layout.dart` adopted with MyNihongo's own per-content minimums
      (`kanaTableMinWidth`, `ruleCardMinWidth`, `referenceTileMinWidth`, `pageMaxContentWidth`)
- [x] Kana module ported from MyAnime, data extracted to `features/kana/models/kana.dart`
- [x] Content models + `ContentRepository`; seed content: 24 N5 words, 8 N5 grammar points, en + zh
- [x] Vocabulary and Grammar browsers: search, JLPT filter chips, adaptive columns, detail sheets
- [x] Learn dashboard (catalog counts, progress counts, quick links, roadmap)
- [x] Progress model (`StudyRecord`, `ProgressData`) with `extraJson` preservation, UTC timestamps
- [x] `NihongoStorage` hub, `data_modules.dart` registry (`nihongo_progress.json` / `progress` /
      `/MyNihongo` / `mynihongo_export_`), facades over `myapps_data`
- [x] Settings: theme, language (System / English / 简体中文), storage location, about, two-pane
- [x] l10n: `en` template + `zh`
- [x] Tests: adaptive rules, kana layout at device geometries, shell rail/bar, progress JSON +
      merge, module registry contract, content catalog rules, render smoke in both languages
- [x] Docs: `doc/en-us/` + `doc/zh-cn/` mirror, `AGENTS.md`, this plan, README, privacy policy
- [x] CI: analyze + test + Android APK (full) + AAB (store) on every push to `main`; GitHub Release on tag

#### M1.1 Sync and backup UI — **done 2026-09-03**

Port from MyAnime, renaming types (`Anime` → `StudyRecord`) and dropping image handling:

- [x] `shared/views/webdav_config_page.dart` — server/credentials/remote path, test connection,
      auto-sync switch, sync now, force upload/download with confirmations, progress bar from
      `WebDAVService.progress`, last-success/failure status from `AutoSyncService`
- [x] Conflict dialog: shows each conflicting record's id resolved to its catalog label (kana,
      headword, pattern) plus counters and `modifiedAt` on both sides; keep-local / keep-remote per
      record; dismissing aborts the resolution (never uploads silently)
- [x] `features/settings/views/backup_page.dart` — create, list (newest first, corrupt flagged),
      restore with module selection, delete, auto-backup switch, retention days; after a restore
      that wrote data, offer force upload. **Amended:** the app does not disable auto-sync itself —
      `myapps_data v1.0.1`'s `BackupEngine.restoreBackup` implements I5 internally, and a second
      implementation would fight it over the same config file
- [x] ZIP export/import rows in Settings → Data, using `file_picker` pinned to `10.3.7`
      (see `platform-notes.md` for why that exact version)
- [x] **Amended:** `progressDataProvider` — now a `StateNotifierProvider` — registers
      `AutoSyncService.addOnLocalDataChanged` once and reloads itself, instead of every page
      registering. One subscription, and no loading flash from `ref.refresh` on riverpod 1.x
- [x] Widget tests at phone and Fold 8 geometries; golden request transcripts against
      `myapps_data`'s fake WebDAV server (copy `test/golden/` harness from MyAnime, one module)
- [x] `.gitattributes` for golden `*.txt` files (`eol=lf`)
- [x] Docs: `sync.md`, `backup-restore.md`, `features/sync-and-backup.md`; ARB strings for both
      pages in `en` and `zh`

#### M1.2 Content pipeline — **done 2026-09-03**

Replace the seed with a real catalog while keeping the schema and ids stable.

- [x] **Vocabulary:** `tool/import_vocab.dart` builds `assets/content/vocab.json` from
      JMdict (EDRDG, CC BY-SA 4.0) joined with an openly licensed JLPT level list. 7,744 entries,
      N5 through N1. Ids are `vocab:jm<seq>`; all 24 seed slugs are aliases, and a test asserts each
      still resolves. **Amended:** no CC-licensed Chinese gloss source was used — the N5 glosses are
      machine-authored in `assets/content/vocab_zh.json`, every row flagged `reviewed: false`
- [x] **Grammar:** N5 done — 81 points in `assets/content/grammar/n5.json`, the 8 seed ids kept
      unchanged. N4 and above still to write. Target counts: N5 ≈ 80, N4 ≈ 100, then N3–N1.
      Each point: pattern, structure, en/zh meaning + explanation, 2–3 examples with readings.
      Author in `assets/content/grammar/<level>.json`; the repository merges them at load.
- [x] **Kana extras:** 21 notes in `assets/content/kana_notes.json` — stroke counts, confusions
      (シ/ツ, ソ/ン, ぬ/め, わ/ね/れ), は and へ as particles, を. Also `romaji.dart`, the Hepburn
      romanizer Phase 2 scoring needs. Stroke-order hints (text), common confusions, small kana,
      ー and っ in katakana loanwords; each becomes a `kana:` detail, not a new record kind.
- [x] Catalog size: parsing moved to `compute` and lookups are maps built once, at 7,744 entries
      and 1.5 MB. On-device load timing is still to measure: if it exceeds ~300 ms on a mid-range
      phone, switch the asset to a prebuilt SQLite file (`sqflite`) and keep the JSON as the build
      input only.
- [x] License and attribution recorded in `features/content-catalog.md` and `license_page.dart`
- [x] `test/content_catalog_test.dart` extended: alias resolution, level coverage counts, no
      duplicate headword+reading within a level

#### M1.3 Reference polish — **done 2026-09-03**, screenshots outstanding

- [x] Kana cell tap → detail sheet (both scripts, romaji, stroke count and note, confusable kana,
      example words from the catalog)
- [x] Vocabulary detail: link each example's grammar to its grammar point when the pattern occurs
- [x] Grammar detail: "words that appear" links back to vocabulary
- [x] Remember last tab, last level filter (separately for vocabulary and grammar) and last script
      per device (`storage_config.json`)
- [x] Column-count preference for the reference lists (`listColumnsAuto` default; clamp, never
      reject; hidden when capacity is 1) — same rule as MyAnime's lists
- [ ] Rendered screenshots at the pinned geometries (Fold 8 both ways, Fold 8 Ultra, Pixel 10 Pro
      Fold, tablet both ways, phone both ways) and a look at each. **Blocked on hardware:** this
      host has no emulator and no attached device. The procedure and the review checklist are
      written up in `tool/screenshots.md` and `adaptive-layout.md`; the captures need the phone

#### M1.4 First release `v0.1.0` — **done 2026-09-03**

- [x] App icon (`assets/icon/app_icon.png`, `flutter_launcher_icons.yaml`, iOS default / dark / tinted
      sources generated by `tool/generate_ios_icons.dart`)
- [x] Android signing: **amended.** Local release builds stay debug-signed, which is what the
      Gradle config already falls back to; CI signs from the GitHub Secrets the workflow reads. No
      keystore is handled here, and none is committed
- [x] `flutter build apk --release --dart-define=FLAVOR=full` and
      `flutter build appbundle --release --dart-define=FLAVOR=store` both succeed. **Not verified
      on a device or a foldable:** this host has no emulator and no attached phone.
      `test/app_smoke_test.dart` walks every tab of the real app against the real catalog instead,
      and the golden transcripts cover the sync, backup and ZIP protocols
- [x] Privacy policy reviewed against actual behavior — now states the plaintext WebDAV
      credentials, the sync wake lock, the custom storage path, and that the system picker needs no
      storage permission. Store listing text in `doc/en-us/store-listing.md` and its zh mirror
- [x] `version-history.md` entry; tag `v0.1.0`; push commit then tag to both remotes

### Phase 2 — Pronunciation and sentence analysis

Goal: hear every item, record and compare your own attempt, and see what a typed sentence is made
of — all on-device.

#### M2.1 Text-to-speech — **done 2026-09-03**

- [x] `flutter_tts` with Android `TextToSpeech`, locale `ja-JP`; speak kana, headwords, example
      sentences from every detail sheet and the kana cells (long-press). Also Apple's
      `AVSpeechSynthesizer` and the Windows speech platform, which is what makes the feature
      testable on this host at all
- [x] Speed control (0.6×–1.2×) and a voice picker listing the installed Japanese voices; a clear
      message when no Japanese voice is installed, with a link to the system TTS settings
      (`com.android.settings.TTS_SETTINGS` through the app's one method channel on Android,
      `ms-settings:speech` on Windows; Apple platforms have no deep link, so the message names the
      pane). **Amended:** the voice picker is hidden when the engine offers fewer than two Japanese
      voices — a dropdown with one entry is a label
- [x] Reading text prefers the kana `reading` field over the kanji surface so the engine cannot
      mis-read kanji
- [x] **Amended:** `flutter_tts` treats 0.5 as normal speed on every platform, so the rate mapping
      is one multiplication with no platform branch
- [x] **Not heard on a device:** this host has no Japanese voice installed and no Android device, so
      the audio path itself is unverified. `test/tts_service_test.dart` drives every branch through
      a fake engine, and the missing-voice UI — which is what this host shows — is covered by
      `test/speak_button_test.dart`

#### M2.2 Speech-to-text and pronunciation feedback — **done 2026-09-03**

- [x] `speech_to_text` over Android `SpeechRecognizer`, `ja_JP`, on-device recognition preferred
      (`EXTRA_PREFER_OFFLINE`); `RECORD_AUDIO` permission requested only when the user first taps
      record, with a rationale. Also Apple's `SFSpeechRecognizer` and the Windows speech platform.
      **Amended:** "preferred" is too weak for what the plugin does — `onDevice` is offline-**only**,
      so a device with no Japanese model fails rather than falling back. That failure is reported as
      `languageUnavailable` and the sheet names both fixes; a switch in Settings, off by default,
      is the only way a request that could reach a server is ever made
- [x] Scoring: normalise both target and recognised text to kana (katakana → hiragana, long vowels
      expanded), split into morae, then mora-level edit distance → a 0–100 score and a per-mora
      diff (correct / missing / extra / substituted). The diff is what the user sees, the score is
      secondary. Documented in `doc/en-us/algorithms/pronunciation-scoring.md`. **Amended:** the
      recogniser answers in kanji where the item is written in kanji, so the attempt is first
      rewritten through a catalog index (`Lexicon.toKana`); without that a perfect reading of 東京
      would score zero
- [ ] Optional own-voice playback (`record` + `just_audio`), files kept in the cache directory and
      never synced or backed up. **Deferred:** it needs the microphone at the same time as the
      recogniser, which cannot be verified without a device, and it adds two more native Windows
      code paths to an ARM64 build. Nothing else in M2.2 depends on it
- [x] Honest limits stated in-app: the recogniser judges *recognisability*, not accent or pitch;
      pitch-accent feedback is a possible Phase 3+ item (needs a pitch dictionary and f0 analysis)
- [x] Privacy policy: on-device recognition; the network fallback is a switch that is off by
      default, and the policy says that on most Android devices the system service behind it is
      Google's
- [x] **Not heard on a device:** this host has no Japanese speech data and no Android device, so the
      recogniser itself is unverified. The state machine, the on-device rule and the scoring are
      covered by `test/speech_recognition_service_test.dart`, `test/pronunciation_scorer_test.dart`,
      `test/kana_text_test.dart`, `test/lexicon_test.dart` and
      `test/pronunciation_practice_ui_test.dart`, and the merged Android manifest was checked to
      carry `RECORD_AUDIO` and no Bluetooth permissions

#### M2.3 Sentence lab (grammar tree) — **done 2026-09-03**

Input a sentence; see tokens, their roles, meanings, and which taught grammar points appear.

- [x] **Baseline (classic, bundled):** a Dart morphological analyser over the catalog.
      **Amended in three places, each recorded in the decisions log:**
      1. Segmentation — **no TinySegmenter.** A lattice over the 7,700-entry catalog plus the
         function-word table reaches every shipped example sentence on its own, and the port would
         have added a model to maintain for what the design used only as a tie-break bonus. The
         lattice is a shortest path over per-position candidate edges with an integer cost table.
      2. Conjugation — table-driven de-inflection running **backwards**: each auxiliary declares the
         stem shape it attaches to, and the lexicon rejects every proposal that is not a word. Godan
         rows, ichidan, both irregular verbs, i- and na-adjectives.
      3. Chunking — bunsetsu grouping and the right-headed dependency guess, with the correction
         that a chunk modifying a noun is not a predicate.
      4. Pattern matching — **no new `match` schema.** The existing literal forms are matched against
         the **token sequence** rather than the raw text, so a one-character particle matches only
         where the tokenizer found a particle. The grammar files stay at `schemaVersion` 2 and no
         content was rewritten.
      5. Checks — four of the five run; the fifth (adjective given a verb ending) is unreachable
         because the lattice makes such a sentence fail to parse rather than parse wrongly. Output is
         "possible issue", never "wrong", and every check carries the exemptions that keep it quiet
- [x] **Optional enhancement:** Android AICore / Gemini Nano through ML Kit GenAI — **landed as M2.4
      below**, once a Pixel 10 was available to evaluate it on
- [x] UI: tokens as chips coloured by role with the role also named in words; tap → the catalog
      sheet, or the function word's own gloss; the bunsetsu dependencies as an indented list;
      grammar points matched listed below with links. **Amended:** one column at every size rather
      than a side-by-side tree on a split window — the sections are a chain, and putting a reference
      beside its referent makes the reading order ambiguous. Recorded in `adaptive-layout.md`
- [x] Tests: **every catalog example must parse without an unknown token** — the five words the
      shipped vocabulary genuinely lacks are listed in
      `test/fixtures/sentence/allowed_unknown.json`, capped at 20, each citing the example that
      needs it. Plus the tokenizer, the de-inflector, the function-word table as content, the
      chunker, the matcher, each check firing and staying quiet, and the page at the named
      geometries. **Amended:** no 200-sentence recorded-fixture set — `toFixtureString` exists and is
      tested, but the every-example test proved the more useful gate, because it fails on the app's
      own content rather than on a transcript somebody has to re-record
- [x] Docs: `doc/en-us/algorithms/sentence-analysis.md`, `features/sentence-lab.md`

#### M2.4 On-device AI assist — **done 2026-09-03**

The M2.3 enhancement, built once a **Pixel 10** was attached. The first Phase 2 milestone verified on
real hardware rather than through test seams.

- [x] **Two ML Kit GenAI APIs, not one:** `genai-prompt` for explanations and `genai-proofreading`
      for a rewrite suggestion. Proofreading answers the "what should I have written" question that
      the Prompt API answers badly, supports Japanese, and has its own model and status
- [x] **Native Kotlin on a second method channel** (`GenAiChannel`), no Flutter plugin. **Amended
      from the plan's assumption:** the published plugins are 0.x, wrap the Prompt API only, and each
      would apply the Kotlin Gradle Plugin — the constraint that already pins `file_picker` and
      `speech_to_text`. `minSdk` rises to 26, which is all the libraries need
- [x] Policy in Dart, where it is testable without a device: off by default (`aiAssistEnabled`,
      absent when off); the switch is a **gate, not a filter** — while it is off the channel is never
      called at all; capability re-checked before every use; one request at a time; 45-second
      timeout; nothing generated is stored, synced or written into the catalog
- [x] Prompts are a **content asset** (`assets/content/prompts/sentence_explain.json`, en + zh,
      schemaVersion 1) grounded in the deterministic analysis: the tokens, the issue message **as the
      UI worded it**, and the catalog's own explanation of up to three matched grammar points, with
      "do not contradict the notes above" in the rules
- [x] `ResponseParser` rejects an echo of the prompt, and rejects a "correction" identical to the
      input — a proofreader handed a correct sentence returns it unchanged, and offering that would
      tell the learner their correct sentence was wrong
- [x] UI: **Explain** per issue, **Explain this sentence** and **Suggest a correction** below them,
      all in `AiExplanationCard` with a generated label above the text and always **under** the
      deterministic finding. Settings → On-device AI: the switch, one status row per feature with its
      own Download button and progress, and a line saying the download is AICore's, not the app's
- [x] Tests: the enabled gate, statuses, download progress, busy and timeout
      (`ai_assist_service_test.dart`); the prompt against the **shipped** templates and catalog
      (`ai_prompt_builder_test.dart`); the parser (`ai_response_parser_test.dart`); the Settings
      section and the lab with and without a model, including that nothing appears while the switch
      is off (`ai_ui_test.dart`)
- [x] **Verified on the Pixel 10:** both models downloaded from Settings, all three actions answering
      correctly in English and in Simplified Chinese, the honest "no different sentence" path, and
      the loading state. Roughly 20–30 s per answer
- [x] **Two bugs found that the test host could not show**, both fixed here:
      1. **R8 shrinks ML Kit into a `NullPointerException`** in release builds only, which the app
         reported as "not available on this device". Keeping `com.google.mlkit.genai.**` is not
         enough — R8's `mapping.txt` named `com.google.mlkit.common.sdkinternal.LazyInstanceMap`, so
         `android/app/proguard-rules.pro` keeps `com.google.mlkit.**` and the `mlkit_**` internals
      2. **Settings raised the microphone prompt on open** (a Phase 2 M2.2 defect): the recognition
         row called `ensureAvailable()`, and initializing the recognizer is what asks for the
         microphone — breaking the documented promise that the prompt never arrives unexplained. It
         now checks the permission first, and the status line has a third state
- [x] Docs: `doc/en-us/features/ai-assist.md`, and **`doc/en-us/android-aicore.md`** — a
      project-independent AICore/ML Kit GenAI reference for the other apps in the series, carrying a
      `Last verified` date and instructions for refreshing it

#### M2.5 Traditional Chinese — **done 2026-09-03**

Phase 5 listed `ja` and `zh_TW` together as "the series' four" languages. `zh_TW` is brought
forward here as the Stage 2 wrap-up, **content included**; `ja` stays in Phase 5, where it also
needs Japanese glosses that do not exist yet.

- [x] `lib/l10n/app_zh_TW.arb`, hand-maintained like the other two, and
      `test/l10n_arb_test.dart` to keep the three key-for-key. **Beyond the plan's "ARB files":**
      Taiwan usage differs by vocabulary, not only by characters — 設定 not 設置, 單字 not 單詞,
      文法 not 語法, 網路 not 網絡 — so a character conversion of `app_zh.arb` was a first draft and
      not the deliverable
- [x] The bundled content too, which the Phase 5 line explicitly deferred ("content stays en/zh
      until glosses exist"): `zh_TW` is **generated** from `zh` by `tool/convert_zh_tw.dart` and
      committed, at the same trust level as the machine-authored Simplified N5 glosses. The tool is
      idempotent and `test/content_zh_tw_test.dart` compares every shipped string against a fresh
      conversion, so a `zh` edit without a re-run fails, and so does a hand-edited `zh_TW`
- [x] `lib/app/locale_resolution.dart`: a device asking for `zh-Hant-HK` gets Traditional Chinese.
      Flutter's own resolution matches language and country, so every Traditional request except
      `zh-Hant-TW` would have landed on Simplified. Only the input is corrected; the algorithm is
      Flutter's
- [x] Settings offers 繁體中文; the privacy policy has its own Traditional text, hand-checked rather
      than generated, because it is the one document a reader is entitled to rely on; the prompt
      asset gains a `zh_TW` block asking for Traditional answers, and the grammar notes handed to
      the model are the Traditional ones
- [x] **Not verified on a device:** the Traditional prompt block. If the model ignores it the answer
      comes back in Simplified Chinese, which is what happened before it existed. Nothing else in
      M2.5 needs hardware, and this round deliberately did not touch the phone
- [x] **Nobody has reviewed the generated Traditional content**, exactly as nobody has reviewed the
      Simplified N5 glosses. A native reader's pass over both is a Phase 3 item

### Phase 3 — Learning engine

Goal: study, not just browse. Flashcards like MojiTest, grammar drills, a Duolingo-like lesson path
with review folded in.

#### M3.0 Device fixes — **done 2026-09-03**

Three defects a real phone found, fixed ahead of the learning engine because the quizzes and lessons
below all depend on speech.

- [x] **Text-to-speech read Japanese in the device's own language**, intermittently, and only for
      words — example sentences were usually fine, and visiting Settings once cured it. Two causes,
      both in `flutter_tts`'s Android plugin and both invisible from Dart: its init callback replays
      queued method calls and **then** overwrites the language with the system default, so the app's
      `setLanguage` was applied and immediately discarded; and `speak` silently rebuilds the
      `TextToSpeech` instance after the service connection drops, landing on the system default
      again. `TtsService` now awaits a queued call as a **probe** before its first write, re-applies
      language, voice and rate **before every utterance**, and selects an explicit Japanese voice
      rather than only a language. If Japanese is refused after having worked, it rebuilds the engine
      once. Written up in `features/pronunciation.md`
- [x] **The voice picker was a dropdown of engine identifiers** with no way to hear anything. It is
      now a sheet: voices numbered over a total order (installed, offline, quality, name), each with
      what is different about it, its raw name for a bug report, and a play button.
      **Listening is not choosing** — the sample restores the learner's own voice afterwards. A
      **speech engine** row appears when the device has more than one engine, which is common on
      Android and is why two devices offer different voices; `ttsEngine` joins `ttsVoice` as a
      device-local preference
- [x] **On-device AI reported "not available on this device" on a Z Fold 8 that has AICore.** Not
      reproducible here, so this is instrumentation rather than a claimed fix: every failure path had
      collapsed into one sentence. `status` now separates **unreachable** (the call threw, with the
      exception class) from **unavailable** (AICore was asked and refused, with the raw
      `FeatureStatus`), each row shows that line, a **Check again** button re-asks without toggling
      the switch, and the manifest's new `<queries>` entry lets the app report the installed AICore
      build and the device. `android-aicore.md` gains a diagnosis procedure and a Samsung field note.
      **Amended by M3.8: the guess recorded here was wrong.** The instrumentation did its job — it
      produced `FEATURE_NOT_FOUND` rather than a bare "unavailable" — but the conclusion drawn from
      it, that the Z Fold 8 is off the Prompt API's device list, was not. The device is on the
      published nano-v4 list; the *client library* was too old to talk to a nano-v4 device, which
      `genai-prompt` 1.0.0-beta4 fixes. One line of Gradle, found by reading the release notes this
      very field note told the next agent to read.
      **Amended again by M4.0: that conclusion was wrong too.** beta4 was necessary and not
      sufficient — the client asks for one model variant of four, and the Fold 8 refuses that one.
      See M4.0
- [x] Tests: `voice_ordering_test.dart`, `genai_backend_test.dart`, and new cases in
      `tts_service_test.dart` (probe ordering, re-apply per utterance, rebuild once, best-voice
      choice, preview restores), `speech_settings_tiles_test.dart`, `ai_assist_service_test.dart`,
      `ai_ui_test.dart`, `preferences_test.dart`

#### M3.1 Spaced repetition core — **done 2026-09-03**

- [x] SM-2 over `StudyRecord` (`ease`, `intervalDays`, `dueAt`, `streak`) in
      `services/sm2_scheduler.dart`; pure, with unit tests; FSRS still deferred until there is real
      review data. **Two departures from the textbook, both deliberate and both tested:** the 0–5
      self-assessment is derived from a right-or-wrong answer (4, or 5 on a run of three), and a
      wrong answer costs **0.20** of ease rather than 0.54 — under binary grading the textbook
      penalty pins an item to the 1.3 floor after three mistakes, where it returns daily forever
      however well the learner then does. Derived in `algorithms/spaced-repetition.md`
- [x] Review queue (`services/review_queue.dart`): due items most-overdue-first, plus new items —
      kana before words before grammar, common words first — both capped by the daily limits.
      **Due is judged by local calendar day** while `dueAt` stays a UTC instant, so an item due at
      23:00 is due from midnight on whichever device the learner picks up. **Today's counts are
      derived from the records**, never stored: nothing to reset at midnight, no extra synced field,
      and work done on another device counts against the same goal
- [x] Synced learner profile — **the record, as planned**, id `profile:me`, payload under the
      `profile` key of its `extraJson`. That needed no new `StudyRecord` field, no change to the five
      places a field has to be added, and **no re-recorded goldens**; a top-level object would have
      merged local-wins with no conflict detection at all. The conflict dialog gets its own block for
      it, because "correct 0 · wrong 0, stage fresh" does not describe a target level
- [x] `recordAnswer(id, correct)` and `recordAnswers(map)` in `NihongoStorage`: one load, one save,
      one auto-sync notification per batch. **A record is created by its first answer**, which is what
      makes "new items started today" countable without a counter. The streak is written once a day
      rather than once an answer, and a settings write carries the earned streak through rather than
      taking it from its caller — a foot-gun a test caught
- [x] `learnerProfileProvider` and `reviewQueueProvider`, both plain `Provider`s derived from the
      progress file and the catalog; Learn tab today card (streak, due, new, backlog) and level
      progress card; Settings gains a **Learning** section, the first synced section in Settings
- [x] Tests: `sm2_scheduler_test`, `review_queue_test`, `learner_profile_test`, `record_answer_test`
      (through real files), `learn_today_ui_test` at all eight named geometries

#### M3.2 Quiz modes (MojiTest-style) — **done 2026-09-04**

- [x] All thirteen modes, with per-mode switches in Settings › Learning › Quiz modes. **The last
      mode on cannot be switched off** — a quiz with no modes opens empty and looks broken rather
      than configured. `quizModes` is device-local: which ways of asking suit somebody depends on the
      keyboard and the speaker in front of them
- [x] Vocabulary: JA → meaning, meaning → JA, reading → written form, written form → reading,
      listening, typing the reading. Kana: kana → romaji, romaji → kana, listening; the whole chart
      in the script currently shown. Grammar: fill the particle, choose the form, order the pieces,
      pick the grammar point
- [x] **Amended: a question is generated or it is not.** Returning null is the normal case — most
      words have no kanji, most have no example sentence, a thin level may have no three plausible
      distractors. The generator is asked for each enabled mode in a shuffled order and the first
      that works wins. Listening modes are dropped where the device has no Japanese voice, and the
      grammar modes are dropped without the analyser, which is only awaited when one is enabled
- [x] Distractors that are wrong for the right reason: same level and part of speech for meanings,
      shared characters for written forms, the catalog's own `confusableWith` list for kana
      (deduplicated **by romaji**, or じ and ぢ would both be "ji"), the fifteen N5 particles rather
      than the whole function-word table, and same-level grammar points **whose own forms do not
      appear in the sentence**
- [x] **A forward conjugator**, which the analyser never had: `Deinflector` runs backwards because
      parsing does. Four forms only — polite, negative, past, te — sharing the row tables with the
      de-inflector so a quiz can never grade against a table the parser disagrees with. **An
      inflected form turned out to be several tokens** (食べ + ます), so a conjugation question spans
      the auxiliary chain and is skipped when the conjugator cannot reproduce what the sentence says
- [x] Session: wrong answers re-queued at most twice, the right answer always shown after a wrong
      one, first-try accuracy as the score, and the wrong list named through the catalog. **Only the
      first answer to an item is recorded** — an item answered right on the third attempt within one
      minute was not recalled, and telling the scheduler otherwise would be a lie about the learner
- [x] Adaptive: question pane fixed at `quizQuestionPaneWidth`, answers in the rest, gated on
      `canSplitLayout`; stacked otherwise. Recorded in `adaptive-layout.md`
- [x] **The `InflectionForm` ARB gap from Phase 2 is closed** — 22 keys, so the sentence lab's token
      chips stop printing English enum names in every language. The prompt handed to the on-device
      model still uses the enum names, because that text is read by a model rather than a person
- [x] Tests: `question_generator_test` against the **shipped** catalog (every N5 grammar point can
      be asked at least one way; every generated question is answerable), `distractors_test`,
      `conjugator_test`, `answer`/`quiz_session_test`, `quiz_page_ui_test` at all eight geometries

#### M3.3 Kana over kanji — **done 2026-09-04**

Asked for during Phase 3 and taken first, because every screen the milestones below add draws
Japanese and would otherwise have to be revisited.

- [x] A **furigana aligner**, because the catalog has no per-character mapping and never will: one
      reading per word, one per sentence. Kana in the surface are anchors that must appear in the
      reading in order; kanji runs take what is between them, shortest first, backtracking until
      the reading is consumed **completely**. That last word is the whole difficulty — 母は/ははは
      is 母 = はは while 花は/はなは is 花 = はな, and no local rule separates them. Derived in
      `algorithms/furigana-alignment.md`
- [x] **Failing is a result.** No reading, a reading belonging to another form, a sentence the
      normalizer changed — all return null, and every caller falls back to the separate reading
      line it drew before. A wrong alignment is not an uglier layout; it prints kana over the wrong
      character and teaches a reading that does not exist
- [x] Memoized on (run, position): without it the search is exponential in the number of kanji runs
      and a sentence with a dozen of them hangs the frame drawing it. Found by a test, not by
      reasoning — the widget test hung
- [x] `FuriganaText` everywhere Japanese is drawn with a reading available: the vocabulary list and
      sheet, word chips under a grammar point and under a kana, every example sentence, the quiz
      prompt, and the sentence lab's chips. **The reading appears once** — over the kanji, or on
      its own line, never both
- [x] The sentence lab needed its own answer: `Token.reading` is the **dictionary form's** reading,
      so 食べ carries たべる and printing it would show a る the sentence does not contain. The
      kanji reading comes from the lemma's alignment and the kana tail from the surface. 来る is
      decided by the recovered forms, and left unread when they do not decide it
- [x] A blanked question blanks its reading at the same span, or the kana above the sentence would
      answer it; a span that cuts a kanji run in half has no answer and the question loses its ruby
- [x] Settings › General › **Kana over kanji**, on by default. **The one inverted preference in the
      app**: `false` is what gets stored, because a learner who has never opened Settings is the one
      who most needs the readings
- [x] Tests: `furigana_aligner_test` (25, including the two performance guards), `furigana_text_test`
      at all eight geometries, four in `preferences_test`. `app_smoke_test` learnt to find Japanese
      by widget rather than by string, since a word with ruby is no longer one `Text`

#### M3.4 The rest of the catalog — **done 2026-09-04**

Asked for during Phase 3: fill the knowledge base, in all three languages,
using model agents in batches. What made it possible was building the loop
first and being honest about what it can and cannot prove.

- [x] **A pipeline, not a heroic session.** `draft_inputs.dart` writes a batch
      that **is** the list of what is still missing, so two agents cannot
      collide and a re-run after a merge simply produces fewer batches. An
      agent writes a draft and never runs a build. `content_gate_test` judges
      it and prints **every** problem at once — the alternative, merging and
      running the suite, turns a fifty-word batch into fifty round trips.
      `merge_drafts.dart` then folds it in and makes no judgements of its own
- [x] Every gate rule is one a shipped test already enforces, moved earlier:
      the sentence tokenizes against the app's own dictionary with no unknown
      word, its reading aligns character by character, `en` and `zh` are both
      there and `zh_TW` is not, ids are new and unique, a grammar point appears
      in its own examples, four options are four distinct options
- [x] **What the gate cannot check is whether the Japanese is natural.** No
      test can. So every model-authored file says
      `"source": "model-authored (Claude), unreviewed"`, every gloss keeps
      `reviewed: false`, and `content-catalog.md`'s rule about Japanese being
      checked by a person is rewritten from a claim into the aspiration it is.
      The alternative was shipping N5 and nothing else
- [x] **The gate's level rule was removed** after three rounds of narrowing it
      took away every true positive it had. 使い方 segments into the rare noun
      使い; これ is filed at N1 because that is the only JLPT list it appears
      on. The invariant is still enforced on the merged file by
      `content_links_test`. A gate that cries wolf is worse than no gate
- [x] **The analyser had to learn N4 and N3 first.** The first grammar batch
      came back with ら and れ unknown all through it: the voice system had
      never parsed. Worse, some of it appeared to — 行かせます came out as
      行 + か + せ + 増す, four real words and complete nonsense, with no
      unknown token, so the gate passed it. **A wrong parse made of known words
      is the failure mode no automated check here can see**, which is why the
      N4 content was probed by hand before any of it was merged. About 130
      function words later — the passive, potential, causative and
      causative-passive as enumerated surfaces, the plain volitional with a new
      o-stem, 〜んです, 〜べき, the keigo verbs, the spoken contractions — 20 of
      21 N4 probe sentences parse
- [x] A rare word now costs more in the lattice than a common one. 殊に, 生かす,
      がる and よって are all real words, and all of them are what ことに, かしら,
      たがる and によって look like to a search that weighs every entry the same
- [x] Content landed: **N4 grammar, 100 points. N3 grammar, 150 points.** The
      chips for both levels had been empty since Phase 1. Chinese glosses and
      example sentences continue to fill in; the coverage as released is in
      `version-history.md`, honestly, because it is not complete

#### M3.5 Lesson path (Duolingo-style) — **done 2026-09-04**

- [x] Content: `assets/content/lessons/n5.json` — nine units, each a topic with
      the grammar and words it teaches, eight sentences and eight hand-written
      questions. **Every one of the level's 81 grammar points is in exactly one
      unit**, asserted against the shipped file: a point in no unit is a hole a
      learner falls into
- [x] `QuestionBank` builds a unit's whole pool and draws from it, which is what
      makes a rare mode as likely as a common one rather than as likely as its
      items are. Weighted by what the learner has not got right, **at most one
      question per item** — twelve questions should be twelve different things
- [x] A checkpoint is a gate rather than an item, so it writes a plain counter
      rather than going through the scheduler. Seven in ten on first-try
      accuracy, the same number the summary shows. **A locked unit's checkpoint
      is still open**, because hiding the way to skip ahead behind the units it
      would skip is circular
- [x] Learn tab shows the path for the target level; a level with no unit file
      says so in a line rather than showing an empty box
- [ ] Scenario lessons — a dialogue with a speaker per line and a branch to pick
      — designed, not written. Units 1 to 4 would gain them first
- [x] Notifications: one local reminder a day, off by default, saying what is
      actually due. **Permission is requested by the switch and nowhere else**,
      asserted by a test, because M2.4 shipped a build that asked for the
      microphone when Settings opened. `SCHEDULE_EXACT_ALARM` is deliberately
      not requested. Written up in `features/reminders.md`

#### M3.6 AICore-assisted practice — **done 2026-09-04**

Same policy as the Phase 2 enhancement: Android AICore / Gemini Nano through ML Kit GenAI, on-device
only, off by default behind one switch shared with Phase 2, a capability check on every use, and a
working baseline on devices without it. Generated text is always labelled as generated, never becomes
catalog content, and never writes a progress record by itself — the learner's answer does.

- [x] **"Why was this wrong"**: the catalog's own explanation is shown first and
      always, because it is the app's answer and it is right. What it cannot say
      is why *this* choice was wrong — it does not know what was picked — so the
      question is handed over exactly as worded, with the catalog's note and an
      instruction not to contradict it
- [x] **Extra example sentences on demand**, drawn below the catalog's own,
      labelled, never saved. Most of the catalog has no example
- [x] **One model, one turn at a time.** `AiPracticeService` queues, and the
      learner's request wins: interactive requests queue behind each other
      rather than failing with "busy", while a background job waits, retries,
      then gives up **silently** because nobody is waiting for it. It imports no
      storage and no progress provider, and a test asserts that from the file's
      own imports
- [x] **Every parser refuses rather than guessing.** No `Rewrite:` line, no
      feedback; a verdict that hedges into a paragraph is dropped and the
      learner marks it themselves; an example line without exactly three fields
      is dropped, because a generated sentence sits beside the catalog's own and
      would otherwise look exactly as authoritative
- [x] Guardrails: `assets/content/prompts/practice.json`, hand-written in all
      three languages like the sentence lab's, output length limits, fixture
      tests for the builders and parsers, and the fallback column in
      `features/ai-assist.md`
- [x] **A second opinion on a typed answer.** The deterministic check runs
      first and owns "correct"; only when it says no is the model asked whether
      the two mean the same, and only a yes counts. A model can never take a
      right answer away
- [ ] Free-response grading as its own quiz mode (a typed translation of a whole
      sentence) — the grading half exists and is what the second opinion uses;
      the mode does not
- [ ] Scenario dialogue partner: a free reply answered in character at the end
      of a scenario. The scripted half now exists (M3.7), which is what this
      would attach to

#### M3.7 Scenario lessons, writing practice, generated questions — **done 2026-09-04**

The three things Phase 3 had designed and not written, plus the rest of the
catalog. Taken together because they are the same shape: a unit is the thing
they all hang off.

- [x] **Scenario lessons.** A unit may end with a scripted conversation: six to
      eight lines with a speaker each, and one or two points where the script
      stops and asks what to say. Written for N5 units 1–4 and N4 units 1–2
- [x] **A wrong reply does not end the conversation, and the script does not
      fork.** What the learner said changes the tally at the end and nothing
      else. A conversation that stops when you say the wrong thing teaches
      nothing about what to say instead; and a per-choice fork is a content cost
      paid on every unit, for a lesson whose point is reading a real exchange.
      Nothing here reaches the scheduler — picking one of three is not recall
- [x] **Writing practice is routed.** The page existed since M3.6 and nothing
      opened it; a unit's `writingPrompt` now does. The deterministic half — the
      unit's words counted from the **parse**, so 食べました counts as 食べる —
      is the whole exercise without a model
- [x] **AI-generated questions.** With the switch on, a unit session asks for up
      to three extra questions **after** it is already on screen, so waiting on
      a model never delays the first question. They are `generated`, so they
      never reach SM-2 — a question that may be wrong must not move a real
      review interval — and they are labelled above the prompt, before reading,
      rather than after answering
- [x] **The generator refuses six ways**: no `Q:` line, no blank in the
      sentence, not four options, a blank option, two identical options, an
      `Answer:` naming none of them. A guessed question is worse than no
      question, because on screen it looks exactly as authoritative as an
      authored one
- [x] **N2 grammar, 170 points. N1 grammar, 158 points.** Every level's chips
      are now full. Twenty-six N1 points were **dropped rather than renamed**
      when their slug collided with an N2 point: renaming would have kept the
      count at the price of teaching the same pattern twice under two ids, which
      is what a learner would actually notice
- [x] **The analyser had to learn the classical layer.** ぬ, ざる, べからざる,
      べからず, んとする, んばかり, や否や, すべ, こととて, 〜つ〜つ, 極まりない,
      極み, の至り, 同然, 関の山, ぐるみ, 三昧, やら〜やら — every one of them
      **is** an N1 grammar point, so the sentence cannot avoid it and the table
      had to grow. Ordinary words the dictionary happens to lack (東京, 顔, 皆)
      were handled the other way round, by rewriting the sentence
- [x] `needs` on a function word means "attach me to a **stem**", so it is wrong
      for a form that follows a finished dictionary form. すべ, べからざる and
      んとする all silently lost their edge to it, and `particle-conj` — not a
      category name the loader knows — dropped や否や entirely. Both were
      invisible: the sentence simply failed to parse, with no error
- [x] Chinese glosses reach **100% of all 7,744 words**, at every level

#### M3.8 Device fixes and the two writing surfaces — **done 2026-09-04**, released as `v0.3.2`

Four things a Galaxy Z Fold 8 asked for, taken before Phase 4 because two of them are defects and
the other two are the pages Phase 4's 作文 section will be built on.

- [x] **The Prompt API works on a Z Fold 8, and M3.0's diagnosis was wrong.** `genai-prompt` goes
      from `1.0.0-beta2` to `1.0.0-beta4`, whose release note is "fixed compatibility with Gemini
      Nano v4 … a `GenAiException` when `checkStatus()` is used". The Z Fold8 family **is** on the
      published Prompt API device list, under nano-v4; the client was too old to ask. `javap` over
      both AARs first confirmed that every member `GenAiChannel.kt` uses is unchanged, so the Kotlin
      did not move. Debug **and release** builds verified — the release one because M2.4's R8 failure
      was release-only. **Not confirmed on the device:** there is no Samsung hardware here.
      **Amended by M4.0: on the device, beta4 turned the exception into `FeatureStatus=0`.** The
      bump was necessary and not the fix; the app was asking for one model variant of four
- [x] **A rewrite is offered whenever proofreading works, even when explanations do not.** The
      sentence lab's correction button sat inside a block that returned early on `!canExplain`, and
      writing practice's rewrite was Prompt-only — so the Fold 8, whose Settings correctly said
      proofreading was ready, was shown no AI at all. Each button is now gated on the feature it
      actually uses. Writing practice gains a proofreader path that corrects each sentence **in
      turn**, because AICore serves one inference at a time
- [x] **History for both pages**, as `lab:<hash>` and `writing:<hash>` records in the progress file —
      the `profile:me` pattern, so they sync, back up and reach the conflict dialog with no new
      module. **The id is a hash of the content**, which is what makes re-analysing update one entry
      rather than add a second, and what makes two devices that analysed the same sentence merge
      instead of conflict. **Only the input is stored:** the analysis is recomputed, and generated
      text is never written. A hundred per kind, pruned per kind, deleted for real
- [x] **Writing practice shows the sentence lab's four sections**, through one shared
      `AnalysisResultView`, rather than the unlabelled chips and bare issue list it drew before. It
      was always the same pipeline; only the presentation was thinner, and a learner who had met the
      lab met a worse version of an answer they already knew how to read
- [x] **Both pages split on a foldable**: input, buttons and history in a pane at
      `labInputPaneWidth`, the analysis in the rest, gated on `canSplitLayout`; the history behind an
      app-bar sheet below the threshold. **The analysis chain stays one column at every size** — the
      M2.3 exception was drawn too widely, and what it protects is the chain, not the text field
- [x] Tests: `history_entry_test` (18, through real files for the cap and the prune),
      `writing_rewrite_test` (7, including that the proofreader is driven sequentially),
      `writing_practice_ui_test` (18 at the eight geometries — **the page had no test at all**), new
      history and split cases in `sentence_lab_ui_test`, a per-feature fake backend in `ai_ui_test`
      covering the proofreading-only device, `labInputPaneWidth` in `adaptive_layout_test`, and a
      history record in `progress_json_test` and `study_conflict_dialog_test`. 726 tests pass
- [x] Docs: `features/writing-practice.md` is new (the page was undocumented), `android-aicore.md`'s
      Fold 8 field note is rewritten from a wrong conclusion into a measured one, and
      `adaptive-layout.md`, `data-formats.md`, `features/sentence-lab.md`, `features/ai-assist.md`
      and eleven `functions/` pages follow; both language trees

### Phase 4 — JLPT N5–N1 practice

#### M4.0 The Prompt API asks for every model, not one — **done 2026-09-04**, released as `v0.4.0`

Taken first and shipped alone, because Phase 4's AICore extras are worthless on a device that
serves no model, and because the same phone had now been misdiagnosed twice.

- [x] **`GenAiChannel` probes model variants instead of assuming one.** `Generation.getClient()` with
      no configuration requests the stable release stage at the full size preference; ML Kit serves
      four combinations, no API says which a device offers, and its own guidance is to implement a
      fallback. The channel now builds a client per variant in preference order — `stable/full`,
      `stable/fast`, `preview/full`, `preview/fast` — keeps the first whose `checkStatus()` is not
      `UNAVAILABLE`, and reuses it for the download and the generation until it stops serving.
      Adding a stage or a preference is one line; no device, client version or model name appears
      anywhere in the decision
- [x] **The refusal says what was refused.** The status reply carries the `variant` that answered,
      the ones that `refused`, and the serving model's `baseModelName` and `tokenLimit`; the row
      reads `FeatureStatus=0 · refused: stable/full, stable/fast, preview/full, preview/fast`, and a
      working row names what is serving it. An unrecognised `FeatureStatus` is `unknown` rather than
      a refusal. `aiCoreInfo` adds whether ML Kit considers AICore able to serve this device at all,
      which separates "AICore is absent or too old" from "AICore is fine, this model is not offered"
- [x] **Errors are read from `GenAiException.getErrorCode()`**, not by matching English substrings of
      a message a reworded release could change silently. The API shapes used here were confirmed
      with `javap -public` over the beta4 AARs before anything was written
- [x] **`maxOutputTokens` travels from `practice.json` to the platform call.** It had been in the
      asset and read by nothing since the practice prompts landed
- [x] Docs: `android-aicore.md` gains a **Choosing a model** section (the four variants, the
      developer-preview stage an app cannot enrol a device in, the per-capability probes, the
      error-code table), a rewritten diagnosis procedure and a third Z Fold 8 field note; five wrong
      or stale statements corrected, including `platform-notes.md` still naming `beta2`; both
      language trees, `version-history.md` with an erratum for `0.3.2`
- [x] Tests: fourteen new cases across `genai_backend_test`, `ai_ui_test`, `ai_assist_service_test` and
      `ai_practice_test` — the new fields decode, an absent field is absent rather than wrong,
      `unknown` is not `unavailable`, the refusal line reaches the UI, and the answer budget reaches
      the platform. 740 pass

#### M4.0a Which models, which one, and whose file — **done 2026-09-04**, released as `v0.4.1`

`v0.4.0` worked on the Z Fold 8: the model downloaded, `stable/fast` serves, `nano-v4-fast`. Three
follow-ups came straight out of that answer, plus one CI annoyance.

- [x] **The probe enumerates instead of stopping early.** Whether the learner has a *choice* of model
      size is itself a fact to report, and a loop that returns at the first success cannot know it.
      All four variants are tried, the first that serves is kept, the rest are closed at once, and
      the reply carries `served`. `status` gained `preferFast` (fast-first ordering) and `force`
      (re-probe rather than trust the variant already serving); the channel remembers the preference
      so `explain` and `download` follow it. A generation still pays one round trip, not four
- [x] **A model-size switch, only where the device serves both sizes.** New preference
      `preferFastModel` through the documented touch points; `AiAssistService.setPreferFast`
      re-probes at once so the row names the model serving now rather than promising one at the next
      launch. The Z Fold 8 serves one size and is shown no control — a switch that cannot change what
      is serving teaches the learner to distrust the page
- [x] **No Remove button for the model, and a line saying why.** `javap` over both AARs: the clients
      expose `download`, `close` and `clearImplicitCaches` and nothing that deletes. The file is
      AICore's and is shared with every app that uses the same model, so a Remove button could only
      do nothing or take away a model another app is using. Settings says where the model lives and
      points at Android's own AICore settings
- [x] **A release stopped building itself twice.** Pushing the commit and then the tag ran the same
      analyze/test/APK/AAB twice on the same tree; `concurrency` keyed on the commit makes the tag
      run supersede the branch run, and an ordinary push is unaffected
- [x] **Two more things only the Pixel 10 could find.** A release build threw `NoSuchMethodError`
      for `kotlinx.coroutines.Job.cancel$default` from inside ML Kit when the model was
      downloaded — R8 had removed a synthetic default-argument bridge the library calls and this
      app does not. Second R8 failure in this one feature; `proguard-rules.pro` keeps
      `kotlinx.coroutines.**` and says why. And `refused: …` was printing under "Not downloaded
      yet", which reads as a fault beside a normal state; the diagnostic line is now shown only on
      a row that cannot serve
- [x] **Measured on the Pixel 10:** it serves `stable/full` and refuses the other three — the exact
      mirror of the Z Fold 8. No fixed variant could have served both phones. Neither device is
      offered the size switch, because neither serves two sizes. Uninstalling the app left the
      model `AVAILABLE`, which is the evidence behind refusing to offer a Remove button
- [x] Three ARB keys ×3; eleven new tests across `genai_backend_test`, `ai_ui_test`,
      `ai_assist_service_test` and `preferences_test`. 751 pass

#### M4.0b Furigana that does not collide with its own kanji — **done 2026-09-04**, released as `v0.4.2`

Reported from the Pixel 10's vocabulary list: the reading painted over the word.

- [x] **The ruby slot is reserved from a forced strut, not from arithmetic on `fontSize`.** It was
      `rubyScale × 1.15` — a guess that a font's ascent plus descent fits in 1.15 em — with
      `TextHeightBehavior` having switched off the ascent clamp that would have held it there. The
      app ships no font, so Japanese uses the system CJK face, which needs about 1.4; a `SizedBox`
      constrains without clipping and a paragraph paints from the top, so the surplus landed on the
      word. The base slot never had the bug because it has forced its own strut since it was
      written. Both do now, and `rubyLineHeight` / `baseLineHeight` are named constants that say
      what they are
- [x] **Sizes go through `MediaQuery.textScalerOf`.** `fontSize` is the request; the engine paints
      the scaled value. Reserving from the nominal number meant a raised system font size grew the
      text and not the box
- [x] Tests: the reading's box must end at or above the word's, at text scale 1.0, 1.3 and 2.0, and
      the boxes must grow with the scale. **The test file says plainly what it cannot hold**: the
      widget-test font has 1.0 em metrics, so it never overflows the old reservation and every
      existing test passed while the bug shipped
- [x] **Verified by screenshot on the Pixel 10**, before and after, in a release build — which is
      the only place the font that causes it exists
- [x] Docs: the `functions/` page for this widget described the `Text.rich`/`WidgetSpan`
      implementation replaced two releases ago; both trees now describe the `Wrap` of `_RubyBox`
      that is actually there, and why both slots force a strut. 753 tests

#### M4.0c Generated questions that earn their place — **done 2026-09-04**, released as `v0.4.3`

Three complaints from the device, one theme: model-written material was being shown as if something
had checked it.

- [x] **A generated question is asked twice.** `AiQuestionGenerator.generate` now hands each parsed
      question back **without** its proposed answer through a new `quizCheck` task, and keeps it only
      when the model re-derives the same option *and* calls the question sound
      (`AiQuestionGenerator.accepts`, kept out of the plumbing so the rule can be stated and tested
      on its own). Showing a model an answer and asking it to approve it produces agreement; two
      derivations that must match is a check. Silence drops the question. One extra background call
      per candidate, none of it on the path the learner waits on
- [x] **A generated question can be skipped.** `QuizSession.skip()` pops it, records nothing,
      re-queues nothing and decrements `total`; `QuizRunner` shows the button only when
      `question.generated` and only before it is answered. One ARB key ×3
- [x] **The word examples work.** Three faults: the widget read `canExplain` through a plain
      `Provider` that never rebuilds, inside a `showModalBottomSheet` builder that never rebuilds
      either — so a sheet opened during the probe stayed empty until reopened; `forExamples` asked
      for the labels `sentence` and `expected`, which exist, so the prompt called a word "Sentence:"
      and its gloss "The model answer:" and nothing failed loudly; and the parser refused any line
      that was not exactly three bar-separated fields, discarding a Markdown table row, a numbered
      line and a fenced block. Packaging is now stripped, field contents never rewritten
- [x] **The gap that let it ship:** nothing tested `practice.json` for completeness. A test now
      asserts every task exists in `en`, `zh` and `zh_TW` and that every label a builder indexes is
      defined in each
- [x] **Verified on the Pixel 10** in a release build: the examples arrive; a practice session grew
      from 13 to 15 as generated questions passed the second opinion, one of three refused. The skip
      button is held by widget tests — driving a 15-question session blind through typed answers was
      not a verification, it was a coin toss
- [x] Docs: `features/ai-assist.md` grows from four bounds on a generated question to six; the two
      `functions/` pages this feature never had (`practice_prompt_builder.md`,
      `generated_examples.md`) are written, in both trees. 773 tests


#### M4.1 Drill content, the pipeline that writes it, and practice mode — **done 2026-09-05**, released as `v0.4.4`

The paper the Learn tab has been promising since the first release, at N5, one section at a time.

- [x] **The paper is content, not code.** `assets/content/drills/structure.json` holds every
      level's timed blocks, scoring groups, overall pass mark and per-大問 counts, with the jlpt.jp
      pages it was read from in its own `source` field. JEES says the composition varies session to
      session, so it is a target rather than a promise, and a revision by them is a content change
- [x] `DrillSection` and `DrillType` (twenty-one 大問, each carrying its section), `DrillFile` /
      `DrillPassage` / `DrillQuestion` with `toQuizQuestion`, `JlptStructure` with `composition` and
      `minutes` per `ExamScale`, `DrillRepository`, `DrillSampler`. The type keys and section names
      are a compatibility contract and say so
- [x] **`DrillRepository` asks the asset manifest instead of trying and catching.** A missing file
      is the normal state for most of the twenty level-section pairs while the levels are still
      being written, and `loadString` reports a Flutter error before it throws — which a widget test
      fails on even where the throw itself is handled
- [x] **A drill question is scored under its own id.** `QuizSession.scoreKey` is
      `questionId ?? itemId`; the schedule still hears about each item once, through a separate
      `_recordedItems` set. Also `requeue: false`, `outcomes`, `forfeit()` and `restore()`, all of
      which M4.2 and M4.3 need and none of which changes a default
- [x] **Two latent bugs the change surfaced**, both invisible until a session asked two questions
      about one item in a row: the answer pane was keyed by item and mode, so the first question's
      selection carried into the second, and the re-speak check compared the same pair, so the
      second question was silent. Both now compare the question
- [x] `QuizRunner` gains `header`, `leadingBuilder`, `showFeedback` and `questionPaneWidth`, all
      defaulting to what every existing caller already had; `_QuestionPane` gains the two slots and
      prefers the question's own instruction, because a paper writes one per 大問 and two 大問 that
      look identical ask for different things
- [x] `DrillPassageView`, `ListeningScriptPlayer` (line by line from the reading, `stop()` before
      each line because `speak` toggles off a repeat, transcript hidden until answered, play limit
      only in a mock), `drillPassagePaneWidth` — the mirror image of the quiz's split, because here
      the question is the larger half
- [x] **`QuizMode.drill` is deliberately not selectable.** The other sixteen are ways the app
      invents a question about a catalog entry; this one means the question was written for a paper,
      so switching it off would only mean refusing to sit it. `selectableQuizModes` — not
      `QuizMode.values` — is now what "every mode is on" means in the preference
- [x] **Passages are drawn whole.** `DrillSampler.drawByPassage` takes passages until the count is
      met; drawing questions independently would put one question from each of three texts on a
      short paper. Within a 大問 the order is never-asked, then least-recently-asked, then the rest,
      shuffled **inside** each tier so an unseen question is never as likely as yesterday's
- [x] The pipeline's fifth stream: `draft_inputs drills --level N5 --section reading --target 1`
      (deficit per 大問 against `structure.json` × target, never splitting a 大問 across batches, with
      the level's vocabulary and grammar in a **separate resources file** so a thirty-question ask is
      not a megabyte of the same list), `merge_drafts drills` (appends, fatal on a duplicate id,
      strips `zh_TW` at every depth), thirteen new gate rules, `.claude/agents/content-drills.md`,
      `'drills'` added to the two hard-coded directory lists
- [x] **N5 complete at the official composition**: 67 questions and 29 passages across all four
      sections, every batch through the gate first time
- [x] `JlptPracticeCard` replaces the "coming next" card, which promised the three things that have
      now all shipped. A section with no content and listening with no Japanese voice are **disabled
      with the reason beside them**; the two unbuilt buttons are shown disabled and explained
- [x] **Verified on the Pixel 10 in a release build**: the card lists all four sections with their
      counts; a reading question shows its passage with furigana and offers the translation only
      after answering; a listening question plays its script and reveals the transcript only after
      answering; 漢字読み shows 【病院】 with the furigana correctly withheld, because there the
      reading is the answer
- [x] Docs: new `features/jlpt-practice.md`; `content-authoring.md` (fifth kind), `content-catalog.md`
      (two licence rows), `quizzes.md` (a question with an id of its own), `adaptive-layout.md`,
      `data-formats.md` (the drill schema), `translation-guide.md` §5.2 (sixteen terms), seven new
      `functions/` pages and seven corrected ones, in both trees. 856 tests

- [x] Drill content per level and section: 文字・語彙, 文法, 読解, 聴解 (TTS-read passages),
      as `assets/content/drills/<level>-<section>.json` — flat rather than the nested path this
      line originally proposed, so `pubspec.yaml` gains one asset entry and the two hard-coded
      directory lists gain one each; original questions with answers and explanations in en/zh.
      **N5 landed with M4.1**; the other four levels follow, one per milestone

#### M4.2 Exam records and results history — **done 2026-09-05**, released as `v0.4.5`

- [x] **An attempt is an `exam:` record in the progress file**, payload under `extraJson['exam']`, id
      `exam:<startedAt UTC compact>-<4 hex>`. A record rather than a second module: it gets the
      per-record three-way merge, the conflict dialog, sync and backup for free, where a module of
      its own costs a second remote file, a second backup entry and eleven golden re-recordings
- [x] **Only the input is stored** — which questions were asked and what the first answer to each
      was, as `1` / `0` / `-1`. Everything the results screen shows is joined back from the shipped
      files at read time, so a content update that corrects an answer key corrects the history with
      it. A question the files no longer have says so in one line rather than vanishing
- [x] `-1` is its own value. Calling an unanswered question wrong makes every timed score look worse
      than the learner did; dropping it makes every timed score look better. Nothing is timed until
      M4.3, but the record has to be able to say it before the clock exists
- [x] The id is **timestamped and salted, not content-addressed** — the opposite of the sentence
      history's rule, and deliberately: re-analysing one sentence should update one record, while two
      sittings of one paper are genuinely two things
- [x] Section keys are plain strings, so `progress/` imports nothing from `drills/` and a section a
      later release adds still round-trips through this build
- [x] `StudyKind.exam` and the five sites it forces: the review queue (never scheduled), the item
      label (level · mode, date, score — the record is passed in, as a history record's is), the
      conflict dialog (`_examVersion`, describing the paper rather than repeating the counters), the
      study calendar (an attempt **does** count as a study day), and the WebDAV page that passes the
      two localized mode words in
- [x] `NihongoStorage.recordExam` with **per-mode pruning**, 40 mock and 80 practice: a learner who
      practises daily and mocks monthly would otherwise lose every mock to the practice runs
- [x] `examAttemptsProvider`, and `askedQuestionsProvider` — which is what finally gives
      `DrillSampler`'s asked and least-recently-asked tiers something to read. Derived from the
      **synced** attempts, so two devices avoid each other's questions rather than each grinding
      through the same first twenty
- [x] Every finished practice section writes a `mode: practice` attempt. Nothing is written on
      leaving: half a paper is not an attempt, and the leave dialog already says so
- [x] `ExamHistoryPage` at `/exam-history`, newest first, expanding into what was got wrong with the
      right answer and the explanation; delete is a real deletion. It says **in words** at the top
      that a score there is not a JLPT score — "4 of 8" beside those four letters reads as one
      otherwise. The Learn card's Results button is live and its footnote now promises only the mock
- [x] Two test hazards worth recording, both of which hang rather than fail: `dart:io` inside a
      `testWidgets` fake-async zone never completes, so the fixture write goes through `runAsync`;
      and an indeterminate `LinearProgressIndicator` never settles, so the loading state inside an
      `ExpansionTile` — which builds its children before they are ever shown — became a plain empty
      box instead
- [x] **Verified on the Pixel 10** in a release build: a vocabulary paper answered end to end
      appears in the results as `N5 · Practice`, 4 of 8, `Vocabulary: 4/8`, and opens into the four
      questions it got wrong with their answers and explanations read back from the content files
- [x] Docs: `data-formats.md` (the exam record and an inventory row), `features/jlpt-practice.md`
      (the results history and the no-repeat rule it feeds), four new `functions/` pages — including
      `study_calendar.md`, which had never been written — and ten corrected ones, in both trees.
      891 tests

- [ ] Practice mode (untimed, explanation after each) and mock mode (timed per section, results at
      the end); question bank sampling avoids repeats until exhausted
- [x] Results history synced: one record per attempt — `exam:<startedAt>-<4 hex>` rather than the
      `exam:<uuid>` this line proposed, because a timestamped id sorts the way the attempts happened
      and `uuid` is only a transitive dependency here. A new record kind in the same module, not a
      new file: the size argument never bit, and a module of its own costs a second remote file, a
      second backup entry and eleven golden re-recordings. **Landed with M4.2**

#### M4.2a Settings a learner can read — **done 2026-09-05**, released as `v0.4.6`

Reported by the user, and correct: the Settings explanations — the on-device AI ones above all —
were too long and were not written for the person reading them. They had drifted into being written
for whoever had to debug the feature.

- [x] **The AI copy rewritten for a learner.** The switch body now says what the feature does and
      where it runs; the size switch says "Answers come sooner, and are usually shorter" instead of
      explaining what a model variant is; the download and storage notes lost the words "AICore" and
      "system service", which are things the app knows and the learner does not
- [x] **Developer options, unlocked by eight taps on the version row.** Android's own gesture,
      copied exactly: somebody who needs the diagnostics already knows how to do it, and nobody else
      finds it by accident. Preference `debugMode` through the documented touch points, **device
      local and not synced** — what it reveals is the diagnosis of *this* phone
- [x] **The countdown is the version row's own subtitle**, from three taps out. A snack bar was
      tried first and was wrong: the About section is at the bottom of a long list and the snack bar
      covered the row the next tap had to land on — the device found that, not the test suite
- [x] Moved behind the flag, not deleted: the `variant · model · N tok` line, the raw
      `FeatureStatus` and refused-variant line, and the AICore build and compatibility line. They
      are still the first thing a bug report needs, and `android-aicore.md`'s diagnosis procedure
      gains a step 0 telling the reader to turn them on first
- [x] **One thing genuinely changed rather than moved**: an unrecognised `FeatureStatus` now reads
      as "Not available on this device" unless developer options are on. The distinction matters —
      reading a status this build has never seen as a refusal is how a working device gets told it
      is broken — but it is not one a learner can act on, and both lead to the same next step
- [x] Tests: five on the plain view (a working feature says only "Ready"; a refused one shows no raw
      status; an unrecognised status reads as unavailable; unlocked, the whole diagnosis returns; and
      the plain copy contains none of "AICore", "system service" or "variant"), six on the unlock
      itself, and the preference trio. The AI settings harness now writes the real preference through
      `NihongoStorage` rather than injecting it, so what the tests exercise is the path the gesture
      takes
- [x] Two test hazards found and written down: the settings harness may not give every test a path
      provider, because a config that says AI is off switches the service back off underneath the
      lab tests that had just turned it on; and a fire-and-forget write started inside `testWidgets`'
      fake-async zone never completes there, so the "it was written to the file" assertion is a plain
      test rather than a widget one
- [x] **Verified on the Pixel 10** in a release build: the rewritten rows, no developer row, the
      countdown appearing under the version at two taps out, the unlock and its confirmation, the
      full diagnosis with it on (`stable/full · nano-v3 · 8192 tok`, the AICore build, Google Pixel
      10), and the plain view again once switched off
- [x] Docs: `features/ai-assist.md` (the two-row learner table and a Developer options subsection),
      `android-aicore.md` (step 0), `data-formats.md` (inventory row), four `functions/` pages and
      the INDEX totals, in both trees. 905 tests

- [ ] Weakness report: per-section and per-grammar-point accuracy feeding review priorities
- [ ] AICore enhancement (M3.5 policy, same switch): a supplementary 作文 writing section — a short
      composition per prompt with feedback against a rubric (task fulfilment, grammar range,
      vocabulary level), labelled supplementary because the JLPT has no writing section; 読解 help —
      paraphrase a hard sentence or explain why a chosen option contradicts the passage; 聴解
      review — the transcript with what was missed pointed out; and a short narrative for the
      weakness report, marked generated. Mock-mode scores come from the deterministic grader only;
      AICore never changes a score
- [ ] Level readiness estimate with an explicit "this is not an official score" note

### Phase 5 — Platforms and languages

- [x] Windows: `flutter create --platforms=windows`, `installer.iss` (x64 + ARM64), MSIX config and
      the series' version locations — **landed early, with Phase 2**, because pronunciation work
      needs a machine that can run the app and this host has no Android device. Desktop scroll and
      keyboard shortcuts for quizzes stay in Phase 5
- [x] macOS project files (`--platforms=macos`, `AppInfo.xcconfig`, both entitlement files) —
      **landed early, unverified**: there is no Mac here. iOS/macOS speech through
      `AVSpeechSynthesizer` / `SFSpeechRecognizer` and the sideload IPA and DMG jobs stay in Phase 5
- [x] UI language `zh_TW` — **landed early as M2.5**, with the bundled content converted rather
      than deferred
- [ ] UI language `ja`: an `app_ja.arb` and Japanese glosses, which do not exist yet. A Japanese
      UI over English-only glosses would be the worst of both
- [ ] Windows ARM64 job on Flutter master until stable ships ARM64, as MyAnime does

---

## 5. Cross-cutting checklists

**Every new page**

- [ ] Layout decision recorded in `adaptive-layout.md` (shape gate, width-only packing, or double
      gate), including what it costs
- [ ] Widths come from `adaptive_layout.dart`; capacity measured against `shellContentWidth`
- [ ] Widget tests at: Fold 8 933×704 and 704×933, Pixel 10 Pro Fold 791×820, Fold 5 659×791,
      tablet 1024×768 and 768×1024, phone 412×915 and 915×412; `expect(tester.takeException(), isNull)`
- [ ] Layout tests driven in `zh` where text width matters (square CJK glyphs measure the real
      layout; the test font inflates Latin)
- [ ] Strings in all three ARB files; `flutter gen-l10n` output committed
- [ ] Function Explanation Layer on every declaration; `doc/en-us/functions/` page + INDEX row;
      `doc/zh-cn/` mirror

**Every content change**

- [ ] `dart run tool/convert_zh_tw.dart`, then `flutter test test/content_zh_tw_test.dart`
- [ ] `flutter test test/content_catalog_test.dart`
- [ ] Ids stable; new ids prefixed; retired ids aliased
- [ ] Japanese checked by a person; readings match the surface
- [ ] License/attribution current

**Every release**

- [ ] `AGENTS.md` → Release section
- [ ] Compare `genai-prompt` and `genai-proofreading` with the Google Maven group index, and record
      the decision to move or stay. A beta bump here has twice been a device-visible change
- [ ] Submodule pinned to a tag
- [ ] `version-history.md` entry in both languages

---

## 6. Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-09-02 | One synced module, `nihongo_progress.json`, per-record merge by `modifiedAt` | Same shape as MyAnime's single module; the engines and their goldens are proven on it |
| 2026-09-02 | Record kind derived from the id prefix, not stored | Nothing to fall out of step; unknown prefixes from newer builds still load and merge |
| 2026-09-02 | Content bundled as JSON assets, not synced | It is the app's data, not the user's; syncing it would make every device carry the catalog twice |
| 2026-09-02 | Kana data moved out of the page into a model | Quizzes, TTS and the progress catalog need it; MyAnime kept it inline because only the page used it |
| 2026-09-02 | Facades keep MyAnime's public shape; no `sync_progress`/`sync_wake_lock` shims | Shims in the siblings exist for history this app does not have; pages import `myapps_data` types directly |
| 2026-09-02 | ZIP import strict (`rejectUnknownEntries`, `strictUtf8`, `validateBeforeWrite`, `atomicWrites`) | No installed base to stay lenient for |
| 2026-09-02 | Theme seed `FlexScheme.sakura` | Each app in the series has its own colour; sakura is unmistakably this one |
| 2026-09-02 | Android only in Phase 1 | Speech APIs and the foldable work are Android-specific to verify; desktop is a `flutter create` away |
| 2026-09-02 | Sentence analysis baseline is a bundled classic pipeline; AICore is an optional enhancement | Deterministic, testable, works on every device, no privacy question; AICore coverage is thin |
| 2026-09-02 | AICore in Phases 3–4 assists practice (writing feedback, free-response grading, explanations, dialogue) but never sets a score or writes into the catalog | Results stay comparable between devices with and without AICore; generated text stays labelled and out of the shipped data |
| 2026-09-03 | The progress provider, not each page, subscribes to `AutoSyncService.addOnLocalDataChanged` | One subscription for every page, and riverpod 1.x's `ref.refresh` would blank a loaded page on every background sync |
| 2026-09-03 | The backup page does not re-implement invariant I5 | `BackupEngine.restoreBackup` in `myapps_data v1.0.1` already disables auto-sync before its first write; two writers of the same config file would race |
| 2026-09-03 | `WebDavClient.download` decodes UTF-8 bytes instead of `response.body` (package fix) | Every progress id here contains kana; `package:http` falls back to latin1 when a server sends no charset, which corrupted every downloaded record. Found by the golden transcripts |
| 2026-09-03 | Vocabulary ids are `vocab:jm<JMdict sequence number>`, with the seed slugs kept as aliases | The sequence number is the only stable key the sources share; a slug would have to be invented for 7,700 words and would collide |
| 2026-09-03 | Three JLPT list rows are corrected in the tool rather than in the committed CSVs | The lists stay byte-identical to upstream, and the reason for each change stays readable next to it |
| 2026-09-03 | The Chinese overlay is bundled, not kept under `tool/` | The catalog test reads it through `rootBundle` and compares it against what shipped, which catches an overlay edit that never had `--overlay-only` run over it |
| 2026-09-03 | The reference preferences are device-local, never synced | A phone and a tablet want different column counts, and a habit lives on a device |
| 2026-09-03 | The router is built once and kept in the root widget's state | A `GoRouter` owns navigation history; rebuilding one on a theme change would send the user back to the initial tab mid-session |
| 2026-09-03 | AICore is reached through the app's own Kotlin method channel, not a Flutter plugin | The published plugins are 0.x, wrap the Prompt API only, and each applies the Kotlin Gradle Plugin — the constraint that already pins `file_picker` and `speech_to_text`. Two clients and five methods are less risk than a dependency |
| 2026-09-03 | Proofreading is a second GenAI feature beside Prompt, with its own switch-independent status | It answers "what should I have written" directly and supports Japanese; a device can have one model and not the other, so the UI never treats "AI" as one thing |
| 2026-09-03 | `minSdk` rises from Flutter's 24 to 26 | The only requirement of the ML Kit GenAI libraries; nothing else in the app needs it |
| 2026-09-03 | `proguard-rules.pro` keeps all of `com.google.mlkit.**` | R8 otherwise shrinks ML Kit into a runtime NPE that the app reports as an unsupported device, in release builds only. Keeping just the `genai` packages was not enough — the failing frame was in ML Kit's shared SDK internals |
| 2026-09-03 | The prompt is grounded in the catalog's own grammar explanation, and in the issue message **as the UI worded it** | An explanation that drifts from what the Grammar page says, or that answers a differently worded question, is worse than none |
| 2026-09-03 | The AI switch gates the method channel itself, not the result | "Off" has to mean nothing was asked of the device, not that an answer was discarded; it is the first assertion in the service's tests |
| 2026-09-03 | Cross-links are substring matches, not parsing | A real tokenizer is Phase 3's sentence analyser; until then a wrong link is cheaper than no links, and the chips are labelled as what the example uses rather than as analysis |
| 2026-09-03 | Windows and macOS projects land with Phase 2, but CI stays Android-only | Pronunciation and the sentence lab need a machine that can actually run the app, and this host has no Android device or emulator; desktop CI jobs, MSIX and Inno artefacts remain Phase 5 |
| 2026-09-03 | The Windows window opens at 1000×720, not the siblings' 400×860 | At that width the reference lists and settings are already two-column, which is the layout worth looking at on a desktop; the siblings are phone-shaped because they are phone-shaped apps |
| 2026-09-03 | Settings shows the storage location on desktop only | On a phone the path names a sandbox the user can neither browse nor act on; the custom storage path itself keeps working on every platform |
| 2026-09-03 | Every platform branch lives in `shared/utils/platform_capabilities.dart` and reads `defaultTargetPlatform` | One named home, the same rule `adaptive_layout.dart` applies to widths; reading `defaultTargetPlatform` rather than `dart:io`'s `Platform` is what makes an Android-only branch testable on a Windows host |
| 2026-09-03 | `speech_to_text` is pinned to exactly `7.4.0`, and `flutter_tts` to `^4.2.5` | Both apply the Kotlin Gradle Plugin themselves, which is what `android.builtInKotlin=false` needs — the same constraint that pins `file_picker`. The plugin's main branch has already dropped KGP for AGP's built-in Kotlin, so a caret constraint would break the Android build without warning |
| 2026-09-03 | `TtsService` owns one utterance at a time, published as a `ValueNotifier` | There is one voice on the device; a second speak button that looked idle while it was in fact queued would be lying about what the hardware does |
| 2026-09-03 | Speech recognition is offline-only unless the learner turns on one switch, and that switch is the only setting besides WebDAV sync that lets anything leave the device | `EXTRA_PREFER_OFFLINE` fails rather than falling back, and a failure the user can act on is more honest than a silent upload. The switch's subtitle says what turning it on means |
| 2026-09-03 | The attempt is rewritten through a catalog index before it is scored | Android answers 東京 where the item says とうきょう; comparing those character by character would score a perfect reading at zero. An unresolved span is copied through so it still costs edits |
| 2026-09-03 | Scoring compares morae, and the per-mora diff is the primary output | The mora is the unit Japanese rhythm is counted in and the unit a listener judges; a single number cannot say which part to fix |
| 2026-09-03 | Own-voice recording and playback are deferred out of M2.2 | It needs the microphone at the same time as the recogniser, which cannot be verified on a host with no device, and adds two more native Windows code paths |
| 2026-09-03 | Segmentation is a cost lattice with a shortest path, not greedy longest match | Whether ここではなして splits as ここ/で/はなして or ここ/では/なして depends on what follows, and a left-to-right pass cannot know. Costs also make the tie-breaks explicit and testable instead of hiding them in loop order |
| 2026-09-03 | No TinySegmenter port, against the M2.3 design | The design used it only as a −1 tie-break bonus. At 7,700 entries plus the function-word table the lattice reaches every shipped example on its own, and the port would have added a model to maintain for a bonus nothing needed |
| 2026-09-03 | Grammar matching runs over the token sequence, with no new `match` schema | Requiring both ends to fall on a token boundary is what 〜は needed; the token sequence supplies that, the existing literal forms already work, and the alternative was rewriting the `match` field of 81 points |
| 2026-09-03 | De-inflection runs backwards and confirms every proposal against the lexicon | Forwards, each class has a dozen forms; backwards, each stem shape is one row transformation per class, and generous rules are safe because 飲ん proposes three verbs of which the dictionary keeps one |
| 2026-09-03 | The function-word table is content with `fw:` ids, authoritative over the vocabulary | は is the topic marker far more often than it is 歯; a table the analyser can trust is what makes every other stage possible, and ids that never change let a token carry one |
| 2026-09-03 | Traditional Chinese is `Locale('zh', 'TW')` everywhere: `app_zh_TW.arb`, the stored tag `zh_TW`, the content key `zh_TW` | The siblings already file it that way, the existing `language_COUNTRY` tag round-trips it with no change, and one string a reader learns once names it in all three places |
| 2026-09-03 | A `localeListResolutionCallback` normalises Chinese before Flutter's own resolution | `basicLocaleListResolution` matches language and country, so `zh-Hant-HK`, `zh-Hant-MO` and `zh-HK` would all have been given Simplified Chinese. Correcting the input rather than replacing the algorithm leaves every other language exactly as Flutter defines it |
| 2026-09-03 | The Traditional **content** is generated from the Simplified text and committed; the Traditional **UI** is hand-written | The content is 1,132 strings whose Simplified version is itself machine-authored and unreviewed — converting it changes nothing about how much it can be trusted. The UI is 274 strings a reader meets constantly, and Taiwan usage differs by vocabulary, which no conversion table can supply |
| 2026-09-03 | The conversion is OpenCC's `s2tw` chain re-implemented in Dart, not `s2twp`, and not a character table | Phrases are what decide which Traditional character is right (干净 → 乾淨 but 干部 → 幹部), so a character table is wrong by construction; and `s2twp`'s Taiwan vocabulary table is mostly computing terms, which rewrote 连接 to 連線 and 对象 to 物件 inside a grammar note about which noun a particle connects |
| 2026-09-03 | Japanese words quoted in the Chinese prose are listed in `preserve.txt` rather than detected | 来る is Japanese and must stay 来る, while 来 in the surrounding Chinese must become 來 — the same character, decided by which language the word belongs to, which no rule over adjacency can tell. The list is short, explicit, and a test fails when a shipped file contains the broken form |
| 2026-09-04 | A question that cannot be built is skipped, never padded | Two identical options are two correct answers; a distractor that is not a real form of a word teaches the wrong thing. Every rule may return short, and the generator drops the question rather than filling it with something arbitrary |
| 2026-09-04 | Forward conjugation is a separate class sharing the de-inflector's row tables | Parsing needs backwards, a quiz needs forwards, and two copies of the tables would eventually disagree — at which point the quiz would mark correct Japanese wrong |
| 2026-09-04 | Only an item's first answer in a session reaches the scheduler | A wrong item is re-queued, and an item answered right on the third attempt one minute later was not recalled. Recording the retry would tell SM-2 the learner knows a word they had just got wrong |
| 2026-09-04 | Kana distractors are deduplicated by romaji, not by kana | じ and ぢ are both "ji", and a romaji question offering both has two correct answers |
| 2026-09-03 | The learner profile is a `profile:me` **record**, with its payload inside the record's `extraJson` | A top-level object in the same file lands in the container's `extraJson`, where the merge is a key-by-key union with local always winning and no conflict detection. As a record it gets the ordinary three-way merge and the conflict dialog. Putting the payload in `extraJson` rather than in new `StudyRecord` fields meant no model change, no golden re-recording, and an older build carrying a newer one's fields through untouched |
| 2026-09-03 | A wrong answer costs 0.20 of ease, not SM-2's 0.54 | The textbook value assumes a 0–5 self-assessment, so its worst penalty is reserved for genuinely blank answers. With binary grading every mistake takes it, and three mistakes drop an item to the 1.3 floor — daily review forever, regardless of later performance. At 0.20 the same three reach 1.9 and the item recovers |
| 2026-09-03 | `dueAt` is stored as a UTC instant but "due" is judged by local calendar day | The instant compares identically on every device and needs no timezone arithmetic on disk; the learner expects anything due today to be available all day, in their own day. The scheduler stores instants, the queue reads days |
| 2026-09-03 | Today's review and new-item counts are derived from the records, not stored | A stored counter needs resetting at midnight, adds a field two devices can disagree about, and misses work synced in from elsewhere — which a synced daily goal must not |
| 2026-09-03 | The study streak is written once a day, and only by `recordAnswers` | Writing it per answer would make the profile the most-edited record in the file and turn every shared study day into a conflict. A streak is earned, so a settings write carries the stored value through rather than accepting one from its caller |
| 2026-09-03 | `TtsService` awaits a queued plugin call as a probe before its first `setLanguage`, and re-applies language, voice and rate before every utterance | The Android plugin overwrites the language with the system default after its init callback and after every silent engine rebuild, with no event to listen for. The probe is the only ordering guarantee available; re-applying is the only defence against the rebuild. Three engine calls per utterance cost milliseconds, and the symptom they prevent — Japanese read as English — is invisible to the app |
| 2026-09-03 | The app always selects a named Japanese voice, never only a language | An engine left to its own default falls back to whatever voice it was last on, which is how a language that was set correctly still produced English audio |
| 2026-09-03 | Japanese voices are numbered over a total order rather than shown by engine name | `ja-jp-x-jab#male_1-local` says nothing about how a voice sounds and differs per engine. The order is total (installed, offline, quality, name) so the numbers cannot move between runs; the raw name is still shown small, because that is what a bug report needs |
| 2026-09-03 | Auditioning a voice restores the previous one in a `finally` | Hearing a voice and choosing it are different acts, and a sample that silently changed the app's voice would make the picker unusable for comparison |
| 2026-09-03 | `GenAiStatus.unreachable` is separate from `unavailable`, and both carry the device's own answer | A phone with AICore installed reported having no on-device model, and nothing in the app could say whether AICore had refused, the call had thrown, or the package was invisible to the build. One sentence for four causes is not a diagnosis |
| 2026-09-04 | The catalog beyond N5 is written by model agents against a gate, and every file says so | 600 grammar points, 7,000 glosses and 7,700 sentences is not hard work, it is large work. The gate proves a sentence parses against the app's own dictionary, stays readable at its level and is read the way its reading says; it cannot prove the Japanese is natural, and no test can. The alternative was shipping N5 and nothing else, so the honest course is to ship it with `source: model-authored (Claude), unreviewed` on every file |
| 2026-09-04 | The authoring gate reports every problem in a batch at once | Merging a batch and running the suite turns a fifty-word batch into fifty round trips. The gate's whole value is that an author can trust the list it prints and fix the batch in one pass |
| 2026-09-04 | The gate's level rule was deleted rather than narrowed a fourth time | Every finding it produced was about the parse rather than the sentence: 使い方 segments into the rare noun 使い, これ is filed at N1 because that is the only JLPT list it is on. `content_links_test` still enforces the invariant on the merged file. A gate that cries wolf is worse than no gate |
| 2026-09-04 | The voice system is enumerated as combined surfaces rather than chained | The de-inflector recovers one stem behind one auxiliary and 食べられませんでした is four of them. Teaching the lattice to compose morphemes is a different algorithm, and one where a wrong path costs the whole sentence rather than one edge. A script writes the hundred surfaces; the cost is that an un-enumerated form is not recognised at all |
| 2026-09-04 | A rare word costs more in the lattice than a common one | 殊に, 生かす, がる and よって are all real words, and all of them are what ことに, かしら, たがる and によって look like to a search that weighs every entry the same |
| 2026-09-04 | A unit builds its whole question pool, then draws from it | Shuffling items and taking twenty makes a mode as likely as its items happen to be common. A topic is small enough to do it properly, and one question per item is what makes twelve questions twelve different things |
| 2026-09-04 | A locked unit's checkpoint can still be attempted | It is how somebody who already knows the material skips ahead, and the only thing passing can do is unlock what they just demonstrated. Hiding it behind the units it would skip is circular |
| 2026-09-04 | A checkpoint result is a plain counter, not a scheduled item | A unit is a gate, not something to be reviewed on a spacing curve. The items inside it were already recorded one answer at a time while they were answered |
| 2026-09-04 | Reminder permission is requested by the switch and nowhere else, and a test asserts it | M2.4 shipped a build that asked for the microphone the moment Settings opened. The same mistake with a different permission is one line away, so it is written down rather than remembered |
| 2026-09-04 | `SCHEDULE_EXACT_ALARM` is not requested | Android treats it as high-privilege and a study nudge does not deserve one. `inexactAllowWhileIdle` puts it within a few minutes of the hour, which is what a nudge is |
| 2026-09-04 | The learner's AI request outranks a background one, and a background one fails silently | There is one model and one generation at a time. Somebody who taps two buttons quickly should get two answers; nobody is waiting for a question being written in the background, so there is nobody to tell when it does not arrive |
| 2026-09-04 | Every practice parser refuses rather than half-reads | A model that ignored the format is a model whose content cannot be trusted either. A mangled generated sentence sits beside the catalog's own and looks exactly as authoritative |
| 2026-09-04 | Furigana are aligned per kanji **run**, not per character | The catalog has one reading per word and none per character, so per-character ruby has no data behind it; and 東 alone is not とう in every word. A run is the finest granularity the content can actually support |
| 2026-09-04 | An alignment that does not consume the whole reading is refused, not approximated | 母は against ははは has two candidate splits and only the one that uses every kana is right. Refusing costs a line of screen; guessing prints kana over the wrong character and teaches a reading that does not exist |
| 2026-09-04 | Kana over kanji is stored only when **off** | It is the only preference in the app whose default is on, and inverting the storage is what makes an absent key mean on. A learner who has never opened Settings is the learner who most needs the readings |
| 2026-09-04 | A token's ruby comes from its lemma's alignment plus the surface's kana tail | `Token.reading` is the dictionary form's reading because that is what de-inflection matches against, so 食べ carries たべる. Printing it would show a る the sentence does not contain |
| 2026-09-04 | `AppSettingsNotifier` starts on defaults when the config cannot be read | Nothing awaits the load, so a failure surfaced as an unhandled asynchronous error while the app carried on with the defaults regardless — the same outcome, reported as a crash || 2026-09-04 | A scenario is linear: a wrong reply neither ends it nor forks it | A conversation that stops when you say the wrong thing teaches nothing about what to say instead. A per-choice fork would have to be written and gated on every unit, for a lesson whose whole point is reading one real exchange end to end |
| 2026-09-04 | A scenario writes nothing to the scheduler | Picking one of three replies is not recall, and the unit's own practice session already measures recall against the same items |
| 2026-09-04 | Generated quiz questions are asked for **after** the session is on screen | The alternative is a session that waits on a model before its first question. Three extra questions are worth nothing if they cost the learner a visible pause to reach question one |
| 2026-09-04 | A generated question never calls `onFirstAnswer` | It may be wrong. A wrong question moving a real review interval is a corruption of the progress file that no later correction can undo, and the learner cannot tell it happened |
| 2026-09-04 | The question parser refuses six ways rather than repairing anything | On screen a generated question looks exactly as authoritative as an authored one, so a guessed one is worse than none. None of the six — no `Q:`, no blank, not four options, a blank option, a duplicate option, an `Answer:` naming none — can be repaired without inventing content |
| 2026-09-04 | Twenty-six N1 grammar points were dropped, not renamed, when their slug collided with N2 | Renaming keeps the count at the price of teaching the same pattern twice under two ids. The count is a number in a table; the duplicate is what a learner would actually meet |
| 2026-09-04 | The classical layer went into `function_words.json`; missing ordinary words went into rewritten sentences | ぬ, ざる, べからざる, 極まりない and the rest **are** the N1 grammar points, so no example can avoid them. 東京, 顔 and 皆 are only scenery, and widening the dictionary for scenery widens everything downstream that reads it |
| 2026-09-04 | A scenario added to a shipped lessons file is gated by turning that file back into a draft | `merge_drafts units` rewrites a whole level, so re-running it to add one conversation would be a far larger change than the conversation. Stripping the generated `zh_TW` is the only difference between the two shapes |
| 2026-09-04 | A generated question is judged by re-deriving its answer, never by asking the model to approve one | A model shown an answer and asked whether it is right agrees. Two independent derivations that must match can disagree, and only that is a check. A verdict that cannot be read is a no, because dropping a question costs a question nobody asked for |
| 2026-09-04 | A generated question carries a skip; an authored one does not | The learner is told the sentence may be wrong, so the honest counterpart is letting them decline it. Skipping the syllabus is a different thing and is not offered |
| 2026-09-04 | The example parser strips packaging but never rewrites a field | A code fence, a list marker or a table row's outer bars carry no meaning, and refusing them threw away replies that were entirely correct. Changing what a field says would be inventing content |
| 2026-09-04 | The furigana slots are reserved from a forced strut and scaled by `MediaQuery.textScaler` | The ruby slot guessed 1.15 em where the system CJK face needs about 1.4, and nothing clamped it, so a `SizedBox` that constrains without clipping let the reading paint onto the word. The base slot had forced a strut all along and never had the bug |
| 2026-09-04 | A display bug is verified by screenshot on a device, not by widget test alone | The widget-test font has 1.0 em metrics, so the font that causes this one is not present in the suite. Every existing test passed for the whole time it shipped |
| 2026-09-04 | Every model variant is probed, not only those before the first success | Whether the learner has a choice of model size is itself a fact to report, and a loop that returns early cannot know it. The cost is three extra status calls on a deliberate refresh; a generation still trusts the variant already serving and pays one |
| 2026-09-04 | The model-size switch is hidden on a device that serves one size | A control that cannot change what is serving is worse than no control: it teaches the learner that the page is decorative. The Z Fold 8 serves only the faster model |
| 2026-09-05 | Settings explains the choice, not the implementation; the diagnosis moves behind developer options | Reported by the user. Every diagnostic line was added for a real reason — two wrong diagnoses came from a page that could not say why a device refused — but that audience is one person with a cable and the page was being read by everybody else. Hiding is not deleting: the lines are still there, one gesture away |
| 2026-09-05 | Developer options are unlocked by eight taps on the version row, Android's own gesture | Copying it exactly is the point: somebody who needs the diagnostics already knows how, and nobody else finds it by accident. An "off" row in Settings would have been an invitation to the learner it is meant to spare |
| 2026-09-05 | The unlock countdown is the version row's own subtitle, not a snack bar | The About section sits at the bottom of a long list, and a snack bar covered the row the next tap had to land on. The device found that; the widget test had passed |
| 2026-09-05 | `debugMode` is device-local and never synced | What it reveals is the diagnosis of *this* phone — which variant it served, which AICore build it has. Carrying it to another device would turn diagnostics on where nobody asked and every number in them would be about a different device |
| 2026-09-05 | An unrecognised `FeatureStatus` reads as "not available" to a learner and stays distinct behind the flag | The distinction is how a working device avoids being told it is broken, so it must not be lost. But a learner cannot act on it differently, and both cases lead to the same next step |
| 2026-09-05 | An exam attempt is an `exam:` record in the progress file, not a second data module | A record gets the per-record three-way merge, the conflict dialog, sync and backup for free. A module of its own costs a second remote file, a second backup entry and eleven golden transcripts re-recorded, for state that is a few fields and a map of answers |
| 2026-09-05 | An attempt stores only which questions were asked and what was answered — never the question, the options or the explanation | All of that is a pure function of the shipped files, so storing it would freeze an answer key the next release corrects. Reading it back also means a question the files no longer have can say so, rather than silently shrinking the attempt it was part of |
| 2026-09-05 | "Unanswered" is its own value, not a wrong answer | Calling it wrong makes every timed score look worse than the learner did; dropping it makes every timed score look better. The record has to be able to say it before the clock that produces it exists |
| 2026-09-05 | An attempt id is timestamped and salted, not content-addressed | The exact opposite of the sentence history's rule, and for the exact opposite reason: re-analysing one sentence should update one record, while two sittings of one paper are two things. The timestamp also sorts the ids the way the attempts happened, which makes a file diff readable |
| 2026-09-05 | The exam record's section keys are plain strings | So `progress/` imports nothing from `drills/`, and a section a later release adds still round-trips through an older build rather than costing it the rest of the attempt |
| 2026-09-05 | Attempt pruning is per mode — 40 mock, 80 practice — rather than one overall cap | A learner who practises daily and sits a mock once a month would lose every mock to the practice runs, and the mocks are the ones worth looking back at. The same reasoning as pruning the sentence history per kind |
| 2026-09-05 | The no-repeat sets are derived from the **synced** attempts, so the attempt cap is also the point at which a question becomes askable again | Two devices then avoid each other's questions instead of each grinding through the same first twenty, and "the oldest attempt we still keep" is a reasonable definition of having forgotten a question |
| 2026-09-05 | The results page states in words that its score is not a JLPT score | A screen showing "4 of 8" beside the letters JLPT will be read as a JLPT score unless it says otherwise. The same rule the readiness estimate will need |
| 2026-09-05 | A practice attempt is written on finishing, never on leaving | Half a paper is not an attempt, and the leave dialog already says the rest of the session is discarded. Answers already given are kept — they went through the scheduler one at a time as they happened |
| 2026-09-05 | The JLPT paper's composition and timings are one content asset with a `source` field, not constants in Dart | JEES publishes them and says they vary from session to session, so they are somebody else's changing fact rather than this app's rule. A revision is then a content change, and every screen that shows a number can say whose it is |
| 2026-09-05 | Drill files are flat — `drills/n5-reading.json`, not `drills/n5/reading.json` | One `pubspec.yaml` asset line for the whole of Phase 4, and one new entry each in `convert_zh_tw.dart` and `content_zh_tw_test.dart`, both of which hold non-recursive hard-coded directory lists. The nested path in PLAN's own wording would have cost five of each |
| 2026-09-05 | A drill question is scored under its own id; the review schedule still hears about each item once | A paper asks several genuinely different questions about one word. Scored by item — which is right for every question the app invents — the second and third would never have counted. But SM-2 grades one recall, and the second question about a word was primed by the first, so the scheduler must not hear it twice |
| 2026-09-05 | `QuizMode.drill` exists but is not selectable, and `selectableQuizModes` is what "every mode" means | The other sixteen modes are ways the app invents a question about a catalog entry, and the learner turns those on and off. This one means the question was written for a paper, so a switch could only mean refusing to sit it — which not opening it already does. Comparing against `QuizMode.values` would have quietly stopped the preference recognising "all on" |
| 2026-09-05 | Reading and listening are sampled **by passage**, not by question | A 中文 carries three questions. Drawing independently put one question from each of three passages on a short paper — three texts read for three marks, three times the work of the paper it imitates |
| 2026-09-05 | The sampler shuffles **within** each of its three tiers, never across the pool | Never-asked, then least-recently-asked, then the rest. A plain shuffle would offer yesterday's question as readily as one the learner has never seen, which is the whole thing "no repeats" is supposed to prevent |
| 2026-09-05 | How a question marks the span it is about is a property of the 大問, not a field per question | A gap `（　　）` asks what belongs there; a marked span `【…】` asks about something already present. Writing it per question would let one 大問 be rendered as the other, which changes what is being asked. Furigana is withheld for 漢字読み and 表記 for the same reason: there the reading *is* the answer |
| 2026-09-05 | `DrillRepository` asks the asset manifest rather than attempting a load and catching | A missing file is the **normal** state for most level-section pairs while levels are still being written, and `rootBundle.loadString` reports a Flutter error before it throws — which a widget test fails on even though the throw is handled |
| 2026-09-05 | A section that cannot be practised is disabled with its reason beside it, never hidden | No content yet, or no Japanese voice: a learner who cannot find 読解 practice has no way to tell whether it exists or they have missed it. The same rule already governs `SpeakButton` and the listening quiz modes |
| 2026-09-05 | The three deviations from the real paper are stated in the feature doc rather than quietly made | 即時応答 gets four options where the paper gives three, because every answer pane and the gate assume four; 発話表現 describes its scene in words, because there are no pictures in this catalog; a mock plays each item once, because that is the paper's rule. A deviation nobody wrote down is a bug report waiting to be filed |
| 2026-09-05 | A drill batch's resources go in a file of their own that every batch names | A level's common vocabulary is a few thousand rows. Copying it into each batch would turn a thirty-question ask into a megabyte of the same list, and the agent would still be reading one list |
| 2026-09-04 | No Remove button for a downloaded model | AICore owns the file and shares it with every app that uses the same model, and neither ML Kit client exposes a delete — checked with `javap`. The button could only lie or take away something another app is using |
| 2026-09-04 | CI `concurrency` is keyed on the commit, so a tag run supersedes the branch run | A release pushes the commit and then the tag, which ran the same analyze/test/build twice on the same tree. The tag run is the one that also creates the Release |
| 2026-09-04 | The Prompt API client is chosen by probing model variants in preference order, never by device, client version or model name | ML Kit serves four combinations of release stage and size preference, no API says which a device offers, and `getClient()` with no configuration silently asks for one of them. Reporting that one variant's refusal as the device's answer produced two wrong diagnoses in a row on the same phone. A probe also means a model AICore begins serving later is picked up with no code change |
| 2026-09-04 | A `FeatureStatus` value the build does not know is `unknown`, not `unavailable` | The enumeration has grown before. Reading a future value as a refusal is the same class of mistake as reading one variant's refusal as the device's, and it fails in the direction that tells a working device it is broken |
| 2026-09-04 | `genai-prompt` is pinned to `1.0.0-beta4`, and a beta bump is treated as a possible bug fix rather than only a feature release | An older client throws `FEATURE_NOT_FOUND` from `checkStatus()` on every Gemini Nano v4 device, which is what a Z Fold 8 reported and what M3.0 wrote down as "this hardware is off the list". The device was on the list; the client could not ask. The release notes had said so a month before the report |
| 2026-09-04 | Every AI button is gated on the feature it uses, never on "AI" | The Prompt and Proofreading APIs have separate device lists, so a device commonly has one and not the other. Gating both on explanations hid a working proofreader on exactly the hardware Settings was correctly reporting as ready — the app contradicted its own status page |
| 2026-09-04 | The history is `lab:`/`writing:` **records** in the progress file, not a new module and not a local-only file | The same reasoning as `profile:me`: a record gets the per-record three-way merge, the conflict dialog, sync and backup for free, while a second module means a second remote file, a second backup entry and a second set of golden transcripts. Syncing it is what was asked for |
| 2026-09-04 | A history id is a hash of its content, not a random id | Re-analysing the same sentence should update one entry rather than add a second, and two devices that analysed the same sentence should merge rather than conflict. Both fall out of a content key; neither is available with a random one. The unit is part of the key, so the same sentence written for two exercises stays two pieces of work |
| 2026-09-04 | Only the input is stored in the history — never the analysis, never generated text | The analysis is a pure function of the text and the shipped catalog, so storing it would freeze an answer that the next release improves. Generated text is barred by the behavior contract, and a wrong answer kept is a wrong answer re-read |
| 2026-09-04 | The sentence lab's single-column exception now covers the analysis chain, not the whole page | The chain is what must not be split: the structure refers to the words, the grammar to the structure. The text field and the history refer to nothing in it, so giving them their own pane leaves the chain exactly as it was and gives an unfolded phone something better to do with 933 dp than pad the margins |
| 2026-09-04 | Writing practice renders through the sentence lab's own widget rather than its own thinner layout | It was always the same pipeline; only the presentation differed, so the second page was strictly a worse way to read an answer the learner already knew how to read. One widget also means the two cannot drift apart again |
| 2026-09-03 | The sentence lab is a route outside the shell, not a sixth tab | The five tabs are the reference the app is built around; the lab is something done *to* a sentence you already have, and it is always entered with a purpose from somewhere else |

## 7. Open questions

- Five words the sentence lab needs are missing from the vocabulary, because the JLPT lists it is
  generated from do not contain them: 母, 顔, 東京, 鞄 in kanji and 速い. They are listed in
  `test/fixtures/sentence/allowed_unknown.json`. Adding them means changing the source lists and
  regenerating `vocab.json` — is that worth doing for a handful of words, or should the import tool
  gain a small hand-maintained supplement?
- **Who reviews the model-authored content?** This was an open question about
  N5's Chinese glosses. It is now an open question about roughly 250 grammar
  points, several thousand glosses and several hundred example sentences, all of
  which pass the authoring gate and none of which a Japanese or Chinese speaker
  has read. Every file says so. The gate can be tightened; it cannot be made to
  judge whether a sentence is natural.
- 母 and 父 are not in the catalog at all, because the JLPT lists it is generated
  from do not contain them. This was a theoretical gap and is now a practical
  one: two example batches had to be rewritten around it.
- Grammar authoring throughput: ~80 N5 points is a few days of careful writing; who reviews?
- Pitch accent: worth a Phase 3 item if an openly licensed accent dictionary is available.
- Whether Phase 4 attempts belong in the progress module or their own module (decide on file size
  once drills exist).

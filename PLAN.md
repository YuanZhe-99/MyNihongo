# PLAN.md — MyNihongo!!!!! roadmap

The phased plan for MyNihongo!!!!!, the Japanese learning app in the MyApps series. `AGENTS.md`
says how to work here; `doc/en-us/` says what the code does; this file says **what is planned, in
what order, why, and what is done**. Update the checklists in the same change that lands a
milestone item.

**Status as of 2026-09-04:** Phase 3 is in progress; M3.0 (device fixes), M3.1 (spaced repetition core) and M3.2 (quiz modes) have landed. Phase 1 complete and released as `v0.1.0`. **Phase 2 complete:** M2.1
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
      **The most likely cause is not a bug:** the Prompt API's device list named only the Pixel 10
      family at the last verification, while proofreading's is much wider — so one row ready and the
      other not is the expected answer on that hardware
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

#### M3.3 Lesson path (Duolingo-style)

- [ ] Content: `assets/content/lessons/<level>.json` — units → lessons → ordered exercise
      templates referencing catalog ids; a lesson introduces ≤ 8 new items and mixes in due reviews
- [ ] Progression: a lesson unlocks when the previous one is passed; a unit checkpoint quiz;
      review lessons appear when the queue is large
- [ ] Learn tab becomes the path: today's lesson, due reviews, streak, level progress; the current
      dashboard cards move below the fold
- [ ] Scenario lessons ("at the station", "ordering food") built from catalog items plus short
      dialogues with TTS; each dialogue line is a `ContentExample` with a speaker
- [ ] Notifications (optional, local only): daily reminder at a chosen time, like MyAnime's
      reminders; off by default

#### M3.4 AICore-assisted practice (optional enhancement)

Same policy as the Phase 2 enhancement: Android AICore / Gemini Nano through ML Kit GenAI, on-device
only, off by default behind one switch shared with Phase 2, a capability check on every use, and a
working baseline on devices without it. Generated text is always labelled as generated, never becomes
catalog content, and never writes a progress record by itself — the learner's answer does.

- [ ] Writing practice: prompts per level and unit ("write three sentences about your morning"
      using this unit's words); the learner types; the Phase 2 pipeline runs first for token, form
      and grammar checks; AICore adds a natural rewrite, per-sentence feedback (what reads
      unnaturally and why) and one catalog grammar point to review. Without AICore: pipeline
      checks plus a self-assessment rubric
- [ ] Free-response grading in quizzes: a typed translation or open answer is compared with the
      model answer — AICore judges meaning equivalence and explains the gap; fallback is
      normalized exact match with "mark it yourself"
- [ ] Scenario dialogue partner: in M3.3 scenario lessons the learner's free reply is answered in
      character within the lesson's vocabulary set; the scripted branches stay the graded path
      and the fallback
- [ ] "Why was this wrong": a richer explanation on demand for a wrong answer, grounded in the
      catalog's own grammar explanation passed as context, never contradicting it
- [ ] Extra example sentences on demand for a word or grammar point at the learner's level,
      marked "generated", not saved into the catalog
- [ ] Guardrails: prompt templates versioned in `assets/content/prompts/`, output length limits,
      fixture tests for the prompt builders and response parsers (the model itself is not unit
      tested), and a per-feature fallback table in `doc/en-us/features/ai-assist.md`; the privacy
      policy states that AICore runs on the device and sends nothing out

### Phase 4 — JLPT N5–N1 practice

- [ ] Drill content per level and section: 文字・語彙, 文法, 読解, 聴解 (TTS-read passages),
      as `assets/content/drills/<level>/*.json`; original or openly licensed questions with
      answers and explanations in en/zh
- [ ] Practice mode (untimed, explanation after each) and mock mode (timed per section, results at
      the end); question bank sampling avoids repeats until exhausted
- [ ] Results history synced: one record per attempt (`exam:<uuid>`) — a new record kind in the
      same module, or a new module `nihongo_exams.json` if the file grows past a few hundred kB
- [ ] Weakness report: per-section and per-grammar-point accuracy feeding review priorities
- [ ] AICore enhancement (M3.4 policy, same switch): a supplementary 作文 writing section — a short
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
| 2026-09-03 | The sentence lab is a route outside the shell, not a sixth tab | The five tabs are the reference the app is built around; the lab is something done *to* a sentence you already have, and it is always entered with a purpose from somewhere else |

## 7. Open questions

- Five words the sentence lab needs are missing from the vocabulary, because the JLPT lists it is
  generated from do not contain them: 母, 顔, 東京, 鞄 in kanji and 速い. They are listed in
  `test/fixtures/sentence/allowed_unknown.json`. Adding them means changing the source lists and
  regenerating `vocab.json` — is that worth doing for a handful of words, or should the import tool
  gain a small hand-maintained supplement?
- Chinese glosses for JMdict-scale vocabulary: N5 is machine-authored and unreviewed. Who reviews
  it, and is the same approach acceptable for N4 and above?
- Grammar authoring throughput: ~80 N5 points is a few days of careful writing; who reviews?
- Pitch accent: worth a Phase 3 item if an openly licensed accent dictionary is available.
- Whether Phase 4 attempts belong in the progress module or their own module (decide on file size
  once drills exist).

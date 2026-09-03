# PLAN.md — MyNihongo!!!!! roadmap

The phased plan for MyNihongo!!!!!, the Japanese learning app in the MyApps series. `AGENTS.md`
says how to work here; `doc/en-us/` says what the code does; this file says **what is planned, in
what order, why, and what is done**. Update the checklists in the same change that lands a
milestone item.

**Status as of 2026-09-03:** Phase 1 complete and released as `v0.1.0`. M1.0 (skeleton) landed
2026-09-02; M1.1 (sync and backup UI), M1.2 (content pipeline), M1.3 (reference polish) and M1.4
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

#### M2.1 Text-to-speech

- [ ] `flutter_tts` with Android `TextToSpeech`, locale `ja-JP`; speak kana, headwords, example
      sentences from every detail sheet and the kana cells (long-press)
- [ ] Speed control (0.6×–1.2×) and a voice picker listing the installed Japanese voices; a clear
      message when no Japanese voice is installed, with a link to the system TTS settings
- [ ] Reading text prefers the kana `reading` field over the kanji surface so the engine cannot
      mis-read kanji

#### M2.2 Speech-to-text and pronunciation feedback

- [ ] `speech_to_text` over Android `SpeechRecognizer`, `ja_JP`, on-device recognition preferred
      (`EXTRA_PREFER_OFFLINE`); `RECORD_AUDIO` permission requested only when the user first taps
      record, with a rationale
- [ ] Scoring: normalise both target and recognised text to kana (katakana → hiragana, long vowels
      expanded), split into morae, then mora-level edit distance → a 0–100 score and a per-mora
      diff (correct / missing / extra / substituted). The diff is what the user sees, the score is
      secondary. Document the algorithm in `doc/en-us/algorithms/pronunciation-scoring.md`
- [ ] Optional own-voice playback (`record` + `just_audio`), files kept in the cache directory and
      never synced or backed up
- [ ] Honest limits stated in-app: the recogniser judges *recognisability*, not accent or pitch;
      pitch-accent feedback is a possible Phase 3+ item (needs a pitch dictionary and f0 analysis)
- [ ] Privacy policy: on-device recognition; note that some Android builds fall back to Google's
      network recogniser and how the app detects/avoids that

#### M2.3 Sentence lab (grammar tree)

Input a sentence; see tokens, their roles, meanings, and which taught grammar points appear.

- [ ] **Baseline (classic, bundled):** a Dart morphological analyser over the catalog:
      1. Segmentation — port of TinySegmenter (character-class n-gram model, ~25 kB, BSD) for a
         first split, then longest-match against the vocabulary and a bundled function-word table
         (particles, auxiliaries, copula forms, conjugation endings).
      2. Conjugation — table-driven de-inflection for godan/ichidan/irregular verbs, i- and
         na-adjectives; each surface form maps back to the catalog entry plus a form label
         (polite non-past, negative, past, て-form, …).
      3. Chunking — bunsetsu grouping (content word + attached particles/auxiliaries) and a
         dependency guess by the standard right-headed rule: each chunk attaches to the nearest
         later chunk that can govern it (particle → predicate, modifier → noun).
      4. Pattern matching — each grammar point carries a machine-readable `match` rule
         (token/POS/form sequence); matched rules become the "grammar used" list.
      5. Checks — a small set of known error patterns with explanations: wrong particle for the
         verb frame, adjective conjugated as a verb, な/の confusion, tense mismatch with time
         words, missing copula. Output is "possible issue", never "wrong".
- [ ] **Optional enhancement:** Android AICore / Gemini Nano through ML Kit GenAI where present
      (Android 14+, supported devices only): rephrasing, richer explanation of a flagged issue,
      natural translation. On-device, behind a switch off by default, with a capability check
      and a clear fallback to the baseline. Evaluate device coverage and output stability before
      committing; keep the baseline the source of truth for the tree.
- [ ] UI: tokens as chips coloured by role; tap → dictionary sheet; a tree view of bunsetsu
      dependencies (indented list on phones, side-by-side tree on a split window); grammar points
      matched listed below with links
- [ ] Tests: a fixture set of ~200 sentences (from the catalog examples first) with expected
      token/form/chunk output; every catalog example must parse without an unknown token
- [ ] Docs: `doc/en-us/algorithms/sentence-analysis.md`, `features/sentence-lab.md`

### Phase 3 — Learning engine

Goal: study, not just browse. Flashcards like MojiTest, grammar drills, a Duolingo-like lesson path
with review folded in.

#### M3.1 Spaced repetition core

- [ ] SM-2 over `StudyRecord` (`ease`, `intervalDays`, `dueAt`, `streak`); a pure Dart scheduler
      with unit tests; FSRS considered later once there is real review data
- [ ] Review queue: due items across kinds; daily new-item limit and review limit
- [ ] Synced learner profile (target level, daily goals, streak) — design decision needed: a
      `profile` record inside `nihongo_progress.json` with its own `modifiedAt` and the normal
      conflict dialog, **or** a second module `nihongo_profile.json` with whole-file merge. Default
      plan: the record, because it needs no engine change and keeps the conflict rule uniform
- [ ] `recordAnswer(id, correct)` in `NihongoStorage`; every save notifies auto-sync

#### M3.2 Quiz modes (MojiTest-style)

- [ ] Vocabulary: JA → meaning (choice), meaning → JA (choice), reading → kanji, kanji → reading,
      listening (TTS) → meaning, typing the reading; per-mode toggles
- [ ] Kana: kana → romaji, romaji → kana, listening; row/table selection
- [ ] Grammar: fill the particle, choose the conjugation, order the fragments, pick the pattern
      that fits the context
- [ ] Session summary and per-item history; wrong answers re-queued in the same session
- [ ] Adaptive: question card fixed on the left pane, answer area right, on a split window;
      stacked otherwise (same gate as the rest of the app)

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

- [ ] Windows: `flutter create --platforms=windows`, `installer.iss` (x64 + ARM64), MSIX config,
      the series' version locations; desktop scroll and keyboard shortcuts for quizzes
- [ ] iOS and macOS: `--platforms=ios,macos`, `AVSpeechSynthesizer` / `SFSpeechRecognizer` through
      the same plugins; sideload IPA and DMG jobs copied from MyAnime's workflow
- [ ] UI languages: `ja` and `zh_TW` ARB files (the series' four); content stays en/zh until
      glosses exist in the new languages
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
- [ ] Strings in both ARB files; `flutter gen-l10n` output committed
- [ ] Function Explanation Layer on every declaration; `doc/en-us/functions/` page + INDEX row;
      `doc/zh-cn/` mirror

**Every content change**

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
| 2026-09-03 | Cross-links are substring matches, not parsing | A real tokenizer is Phase 3's sentence analyser; until then a wrong link is cheaper than no links, and the chips are labelled as what the example uses rather than as analysis |

## 7. Open questions

- Chinese glosses for JMdict-scale vocabulary: N5 is machine-authored and unreviewed. Who reviews
  it, and is the same approach acceptable for N4 and above?
- Grammar authoring throughput: ~80 N5 points is a few days of careful writing; who reviews?
- Pitch accent: worth a Phase 3 item if an openly licensed accent dictionary is available.
- Whether Phase 4 attempts belong in the progress module or their own module (decide on file size
  once drills exist).

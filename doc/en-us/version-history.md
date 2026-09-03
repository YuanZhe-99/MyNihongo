# Version history

Release-by-release summary of MyNihongo!!!!!. Useful for understanding *why* a behavior exists
before changing it.

## Repository caveat

The repository's branch is `main`. The `origin` remote existed before the first commit; the
`github` remote was added at initialization. The `myapps_data` submodule was first pinned to
`54fa8d7`, two documentation-only commits after the package's `v1.0.1` tag. It is now pinned to
the `v1.0.2` tag, which carries the UTF-8 download fix this app needed.

## Releases

- `0.2.0` — 2026-09-03. Phase 2: the app speaks, listens, and reads a sentence. Also the Windows
  and macOS projects, added early because the pronunciation work needs a machine that can run the
  app and the development host has no Android device.

  Verified on this host by `flutter analyze` (clean), 297 tests, and debug builds of both the
  Android APK and the Windows executable, the latter launched and checked. **Not verified on a
  device:** this host has no Japanese text-to-speech voice, no Japanese speech data and no Android
  phone, so the audio path and the recognizer itself are exercised only through their test seams —
  what the host actually shows is the no-voice and no-recognizer state, and that state is covered.
  macOS has never been compiled: there is no Mac here.

  Windows and macOS (`PLAN.md` Phase 5, landed early): the two projects, an `installer.iss` that
  builds both x64 and ARM64 from one script, an `msix_config`, desktop launcher icons, and a
  single-instance Windows runner opening at 1000×720 — wide enough that the reference lists are
  already two-column, which is the layout worth looking at on a desktop. CI stays Android-only on
  purpose; the desktop targets are for local development. `flutter_tts`'s Windows plugin needs
  `nuget.exe` on `PATH`, which is now a documented prerequisite. Settings shows the storage location
  on desktop only: on a phone the path names a sandbox the user can neither browse to nor act on.
  Every platform branch now lives in one file, `shared/utils/platform_capabilities.dart`, reading
  `defaultTargetPlatform` so an Android-only branch stays testable on a Windows host.

  Text to speech (`PLAN.md` M2.1): kana, headwords and every example sentence read aloud by the
  device's own engine, with a long-press on any kana chart cell. The kana reading is always
  preferred over the kanji surface, so the engine cannot guess a reading. One utterance at a time,
  published so the button that is playing shows a stop icon and the rest stay idle. A speed slider
  and a Japanese voice picker in Settings, both device-local. With no Japanese voice installed the
  buttons are disabled rather than hidden, and Settings offers a button that opens the system
  speech settings.

  Speech recognition and pronunciation feedback (`PLAN.md` M2.2): say a kana, word or sentence and
  see which morae matched. Recognition is **offline-only by default** — on Android that means the
  attempt fails rather than quietly reaching a server when no Japanese model is installed, and the
  sheet turns that failure into a message naming both fixes. A switch in Settings, off by default
  and stored as an absent key, is the only way anything is ever sent to the system speech service;
  it is the only setting besides WebDAV sync that lets anything leave the device. The microphone is
  requested at first use behind the app's own rationale, never at install. Scoring normalises both
  sides to hiragana morae and aligns them with an edit path whose ties prefer a substitution, so one
  wrong mora reads as one wrong mora; the attempt is first rewritten through a new catalog index,
  because the recognizer answers in kanji where the item is written in kanji. The per-mora diff is
  the primary output and the score is a summary of it. Own-voice playback is deferred: it needs the
  microphone at the same time as the recognizer, which cannot be verified without a device.

  Sentence lab (`PLAN.md` M2.3): type a sentence and see the words, what modifies what, the taught
  grammar it uses, and anything that looks unusual. Tokenizing is a cost lattice with a shortest
  path rather than greedy longest match, because whether a kana run splits one way or another
  depends on what follows it. De-inflection runs backwards — each auxiliary declares the stem shape
  it attaches to, and the bundled vocabulary rejects every proposal that is not a word, so a voiced
  te-stem can propose three verb classes and keep the one that exists. Grammar points are matched
  against the token sequence rather than the raw text, which needed no content change and stops a
  one-character particle matching inside a longer word. Four checks report **possible** issues, each
  carrying the exemptions that keep it quiet. New content: a function-word table of about ninety
  particles, copula forms, auxiliaries and formal nouns with `fw:` ids, authoritative over the
  vocabulary for the same surface. The load-bearing test is that every example sentence the app
  ships parses without an unknown token; the five words the vocabulary genuinely lacks are listed in
  a capped fixture, each citing the example that needs it. Three parts of the M2.3 design were
  dropped as unnecessary and one deferred, each recorded in `PLAN.md`'s decisions log: no
  TinySegmenter port, no new token/POS match schema, one column at every window size, and the
  AICore enhancement left as a `SentenceEnhancer` seam with no implementation.

- `0.1.0` — 2026-09-03. First release: the Phase 1 reference app. Built from M1.0 through M1.4 in
  one day; the four milestone paragraphs below are what shipped in it, in the order they landed.

  Verified on this host by `flutter analyze` (clean), 174 tests including a whole-app smoke test
  that walks every tab against the real generated catalog, and release builds of both the APK and
  the app bundle. **Not verified on a device:** the development host has no emulator and no
  attached phone, so the foldable screenshot pass and a sync against a real WebDAV server are
  outstanding. The golden transcripts cover the sync, backup and ZIP protocols against an in-memory
  server instead.

  Project skeleton (`PLAN.md` M1.0) — Android target, five-tab shell with the
  series' adaptive layout and navigation rail, kana chart ported from MyAnime!!!!! with its data
  extracted into a catalog model, bundled vocabulary and grammar seed content (24 N5 words, 8 N5
  grammar points, English and Simplified Chinese) with browser pages, the synced `StudyRecord`
  progress model with unknown-field preservation, the `nihongo_progress.json` data module and the
  four facades over `myapps_data`, settings with theme/language/storage/about in two panes on wide
  windows, English and Simplified Chinese UI, tests for layout rules, pages, JSON compatibility,
  the module contract and the content rules, bilingual documentation, an Android CI workflow that runs on every push to `main`, and the app icon
  with iOS default / dark / tinted variants (the `ios/` folder is scaffolded for the icon set only
  and is not built by CI).

  Sync and backup UI (`PLAN.md` M1.1): the WebDAV configuration page with manual sync, force
  upload and download, and a live status subtitle on its settings row; a conflict dialog that names
  each record through the content catalog and lets the user keep either version; the backup page
  with automatic backups, retention, restore by module and a post-restore force-upload offer; ZIP
  export and import; golden request transcripts covering all three engines. The progress provider
  became a `StateNotifierProvider` that subscribes to `AutoSyncService` once on every page's
  behalf. A shared-package fix landed with it: `WebDavClient.download` now decodes UTF-8 bytes
  instead of `response.body`, which `package:http` decodes as latin1 when the server sends no
  charset — it corrupted every downloaded record id containing kana.

  Content pipeline (`PLAN.md` M1.2): the vocabulary became 7,744 entries across N5 to N1, generated
  offline from JMdict and the JLPT lists by `tool/import_vocab.dart`, with the 24 hand-written seed
  ids kept as aliases so no progress is orphaned; 81 N5 grammar points; 21 kana teaching notes; a
  Hepburn romanizer; and machine-authored, unreviewed Chinese glosses for every N5 word. Parsing
  moved to a background isolate and the catalog lookups became maps.

  Reference polish (`PLAN.md` M1.3): a kana detail sheet with example words, cross-links between
  vocabulary and grammar examples, a remembered tab, level filter, script and column count per
  device, and a column-count control on the reference lists. The screenshot pass is still
  outstanding: no emulator runs on the development host.

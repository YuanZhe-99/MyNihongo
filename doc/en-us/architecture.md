# Architecture

This page describes the app shell, state management approach, navigation, localization, and the
repository layout, plus the cross-cutting architectural rules. See
[`data-formats.md`](data-formats.md) for the data model, [`sync.md`](sync.md) for the sync
subsystem built on top of this shell, and [`adaptive-layout.md`](adaptive-layout.md) for the layout
rules.

## App shell

- `lib/main.dart` — app entry point: starts the daily auto-backup check and the auto-sync lifecycle
  observer, then runs the app inside `DevicePreview` (debug builds only).
- `lib/app/app.dart` — root `MaterialApp.router` wiring: theme, locale, routes.
- `lib/app/router.dart` — navigation, built on `go_router`. The router uses a `ShellRoute` wrapping
  five navigation tabs — rendered as a bottom `NavigationBar` on a narrow window and a side
  `NavigationRail` from 600 logical pixels up, see [`adaptive-layout.md`](adaptive-layout.md):
  - Learn (`/learn`, `learn_page.dart`) — the dashboard, and later the lesson path
  - Kana (`/kana`, `kana_page.dart`)
  - Vocabulary (`/vocab`, `vocab_page.dart`)
  - Grammar (`/grammar`, `grammar_page.dart`)
  - Settings (`/settings`, `settings_page.dart`)

  There are no non-tab routes yet. Second-level settings pages (privacy policy, license) are pushed
  on the root navigator on a narrow window and hosted in a detail pane on a wide one.
- `lib/app/theme.dart` — the visual system, built on Material 3 via `flex_color_scheme`, seeded
  with `FlexScheme.sakura` so the app is told apart from its siblings at a glance.
- `lib/app/flavor.dart` — build flavor logic (see below).
- `lib/app/data_modules.dart` — the seam to the shared engines (see below).

## Build flavors

Flavor logic lives in `lib/app/flavor.dart`:

| Flavor | Dart define | Distribution |
| --- | --- | --- |
| `full` | `--dart-define=FLAVOR=full` | GitHub Releases, direct APK |
| `store` | `--dart-define=FLAVOR=store` | Google Play (later App Store) builds |

No feature is gated on the flavor today. The constant exists so store-facing builds can be told
apart the same way the sibling apps do, and so a future online feature has `AppFlavor.isFull` ready
as its gate.

## State management

State management uses `flutter_riverpod` throughout. Provider and Bloc are not used, and should
not be introduced for normal changes. Three providers exist:

- `appSettingsProvider` (`shared/providers/app_settings.dart`) — theme mode and locale, persisted
  device-locally.
- `contentCatalogProvider` (`features/content/services/content_repository.dart`) — the parsed
  bundled content, a `FutureProvider` loaded once per run. Decoding runs on a background isolate;
  see [`features/content-catalog.md`](features/content-catalog.md).
- `progressDataProvider` (`shared/providers/progress_provider.dart`) — the progress file, a
  `StateNotifierProvider` pages reload after a save. It, not each page, registers
  `AutoSyncService.addOnLocalDataChanged`, so a sync, a backup restore or a ZIP import refreshes
  every open page through one subscription. (`PLAN.md` M1.1 says "pages register"; this is the
  deliberate deviation, and it also avoids the loading flash `ref.refresh` would cause on
  riverpod 1.x.)

## Localization (l10n)

- Supported languages: English (template) and Simplified Chinese.
- The ARB template is `lib/l10n/app_en.arb`; `app_zh.arb` mirrors it key for key.
- Generated localization files live under `lib/l10n/` and are tracked; run `flutter gen-l10n`
  after editing an ARB file and commit the result.
- JLPT level labels (`N5`…`N1`) and Japanese content text are not localized.

## Repository structure

```text
lib/
  main.dart
  app/
    app.dart
    data_modules.dart
    flavor.dart
    router.dart
    theme.dart
  features/
    content/
      models/
        content_catalog.dart
        grammar_point.dart
        jlpt_level.dart
        localized_strings.dart
        parts_of_speech.dart
        vocab_entry.dart
      services/
        content_links.dart
        content_repository.dart
        study_item_labels.dart
    grammar/views/grammar_page.dart
    kana/
      models/
        kana.dart
        kana_note.dart
        kana_text.dart
        romaji.dart
      views/kana_page.dart
    learn/views/learn_page.dart
    progress/
      models/study_record.dart
      services/nihongo_storage.dart
    sentence/
      models/
        function_word.dart
        sentence_analysis.dart
        token.dart
      services/
        chunker.dart
        deinflector.dart
        grammar_matcher.dart
        lexicon.dart
        sentence_analyzer.dart
        sentence_checks.dart
        tokenizer.dart
      views/sentence_lab_page.dart
      widgets/
        bunsetsu_tree.dart
        grammar_used_list.dart
        issue_list.dart
        token_chips.dart
    settings/views/
      backup_page.dart
      license_page.dart
      privacy_policy_page.dart
      settings_page.dart
    speech/
      services/
        pronunciation_scorer.dart
        speech_backend.dart
        speech_recognition_service.dart
        tts_backend.dart
        tts_service.dart
      widgets/
        pronunciation_practice_sheet.dart
        speak_button.dart
        speech_settings_tiles.dart
    vocab/views/vocab_page.dart
  shared/
    providers/
      app_settings.dart
      progress_provider.dart
    services/
      auto_sync_service.dart
      backup_service.dart
      import_export_service.dart
      sync_merge.dart
      system_settings_launcher.dart
      webdav_service.dart
    utils/
      adaptive_layout.dart
      platform_capabilities.dart
    views/webdav_config_page.dart
    widgets/
      adaptive_tile_grid.dart
      content_sheets.dart
      example_actions.dart
      reference_widgets.dart
      shell_scaffold.dart
      study_conflict_dialog.dart
  l10n/
assets/content/
  function_words.json
  grammar/n5.json
  kana_notes.json
  vocab.json               generated by tool/import_vocab.dart
  vocab_zh.json            Chinese gloss overlay (build input)
tool/
  import_vocab.dart
  screenshots.md
  src/vocab_import_core.dart
  content/jlpt/n{1..5}.csv
  content/vocab_seed.json
  generate_ios_icons.dart        iOS default / dark / tinted icon generator
assets/icon/                     app_icon.png + generated iOS sources (not bundled)
```

Primary tests:

- `test/adaptive_layout_test.dart` — every layout threshold and clamp, at named device geometries.
- `test/kana_layout_ui_test.dart` — the kana page rendered at those geometries: two columns where
  the rules allow it, one where they do not.
- `test/shell_nav_ui_test.dart` — bottom bar versus rail, five destinations, navigation.
- `test/progress_json_test.dart` — unknown JSON preservation, derived kind and stage, UTC
  normalization, and the three-way merge including conflicts.
- `test/data_modules_test.dart` — the module registry's names, validation, pretty-printed merge
  output, and app-neutral conflict resolution.
- `test/content_catalog_test.dart` — the generated catalog parses, ids and aliases are unique and
  prefixed, every retired seed id still resolves, and N5 carries Chinese.
- `test/tool/vocab_import_core_test.dart` — the import rules on fixtures: level precedence, form
  choice, sense filtering, alias creation, deterministic order.
- `test/content_repository_test.dart`, `test/romaji_test.dart` — the isolate seam and the
  romanizer.
- `test/widget_test.dart` — a real page renders in both languages without overflow.
- `test/golden/webdav_golden_test.dart` — the real sync, backup and ZIP engines against an
  in-memory WebDAV server, recorded as request transcripts under `test/golden/goldens/mynihongo/`.
- `test/progress_provider_test.dart` — the first read, and a re-read on a local-data-changed
  notification with no loading flash.
- `test/study_item_labels_test.dart`, `test/study_conflict_dialog_test.dart` — naming a record and
  choosing between two versions of it.
- `test/webdav_config_page_ui_test.dart`, `test/backup_page_ui_test.dart`,
  `test/settings_two_pane_ui_test.dart` — the three data pages at the named geometries.
- `test/preferences_test.dart`, `test/router_test.dart` — the five remembered choices, and the
  app opening on the tab it was left on.
- `test/content_links_test.dart`, `test/list_columns_ui_test.dart` — the cross-links, and the
  column-count control.

## Three kinds of data

| Data | Home | Synced |
| --- | --- | --- |
| Content catalog (kana, words, grammar) | Compiled in: `features/kana/models/kana.dart` and `assets/content/*.json` | No — it ships with the app |
| Learning progress (`StudyRecord` per item) | `nihongo_progress.json` under the app directory | **Yes** |
| Device preferences | `storage_config.json` | No |

The catalog is read-only and versioned with the build. Progress references catalog items by id and
is the only user data the sync, backup and ZIP engines ever see. See
[`data-formats.md`](data-formats.md) for the shapes and
[`features/content-catalog.md`](features/content-catalog.md) for the content rules.

## Shared package (`myapps_data`)

The WebDAV sync engine, backup engine, ZIP transfer engine, and auto-sync scheduler are **not in this
repo**. They live in the shared `myapps_data` package, embedded at `packages/myapps_data` as a git
submodule and consumed as a pub path dependency. MyAnime, MyDay, MyDevice and MyNihongo all use it,
which is what keeps their wire format, backup format, and lock semantics interoperable.

- **What stays here:** all models, `NihongoStorage`, the `mergeProgressData` wrapper, the content
  catalog, and every page.
- **The seam:** [`functions/app/data_modules.md`](functions/app/data_modules.md) declares the
  `StorageAdapter` over `NihongoStorage` plus the `DataModule` describing `nihongo_progress.json`.
  It is the single source of truth for the data-file name, the backup module key, the default
  remote path and the ZIP archive prefix.
- **The facades:** `WebDAVService`, `BackupService`, `ImportExportService`, and `AutoSyncService`
  keep the public shape MyAnime's facades have, so its settings pages port with the type names
  unchanged. Their shapes are frozen; behavior changes belong in the package.
- **No re-export shims.** MyAnime keeps `sync_progress.dart` and `sync_wake_lock.dart` as shims
  for its own history. This app has none; pages import `myapps_data` types directly, or through
  the facade that re-exports them.

`.gitmodules` uses the relative URL `../MyApps-DATA.git`, so it resolves against whichever remote a
clone tracks — Gitea clones fetch from Gitea, GitHub clones from GitHub, and no host name is ever
committed. Fresh clones need `git clone --recurse-submodules` or `git submodule update --init`.

## Core architectural rules

These rules apply across the whole codebase and are worth internalizing before reading any single
feature area:

- **State management:** `flutter_riverpod`; no Provider or Bloc for normal changes.
- **Navigation:** `go_router` with a `ShellRoute` and the five tabs listed above.
- **Visual system:** Material 3 via `flex_color_scheme`.
- **Responsive layout:** one shared rule decides when the UI may split into panes or columns, and
  how many columns a list gets; a second, width-only rule decides whether navigation sits at the
  side or along the bottom. Both live in `shared/utils/adaptive_layout.dart` and are derived in
  [`adaptive-layout.md`](adaptive-layout.md). **Do not add an inline width breakpoint.** Measure
  capacity against `shellContentWidth`, never the raw screen width, because the navigation rail is
  not the page's to spend.
- **File I/O:** goes through `NihongoStorage.getAppDir()` so custom storage paths work; data writes
  go through `NihongoStorage.save()` so auto-sync learns about them.
- **JSON formatting:** output is pretty-printed with `JsonEncoder.withIndent('  ')` everywhere data
  is written to disk — this matters for sync, since it lets an unchanged file hit a raw-equality
  fast path (see [`sync.md`](sync.md)).
- **Timestamps:** every timestamp on a progress record is UTC (`DateTime.now().toUtc()`).
  Local-time `modifiedAt` values would break sync conflict detection, since the three-way merge
  compares `modifiedAt` across devices in different timezones.
- **Unknown JSON fields:** preserved via the `extraJson` pattern (see
  [`data-formats.md`](data-formats.md)) so older app versions don't delete newer fields during
  normal saves, imports, or sync merges.
- **Content ids are stable.** A shipped `kana:`, `vocab:` or `grammar:` id is never renamed; progress
  is keyed by it.
- **Nothing leaves the device** except WebDAV sync to the user's own server. Planned speech and
  analysis features run on-device.

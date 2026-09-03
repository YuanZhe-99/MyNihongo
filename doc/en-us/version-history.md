# Version history

Release-by-release summary of MyNihongo!!!!!. Useful for understanding *why* a behavior exists
before changing it.

## Repository caveat

The repository's branch is `main`. The `origin` remote existed before the first commit; the
`github` remote was added at initialization. The `myapps_data` submodule was first pinned to
`54fa8d7`, two documentation-only commits after the package's `v1.0.1` tag. It is now pinned to
the `v1.0.2` tag, which carries the UTF-8 download fix this app needed.

## Releases

- *Unreleased* `0.1.0`: Project skeleton (`PLAN.md` M1.0) — Android target, five-tab shell with the
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

# MyNihongo!!!!! Documentation (Concepts)

**MyNihongo!!!!!** (five exclamation marks in every user-facing name — app title, launcher label,
and later the installer metadata and bundle names) is a privacy-first Japanese learning app. It
combines a kana chart, a vocabulary and grammar catalog with JLPT levels, a synced record of the
user's learning progress, WebDAV sync, local backup and ZIP transfer through the shared
`myapps_data` engines, and the series' adaptive layout for foldables. Pronunciation practice, a
sentence analyser, spaced-repetition lessons and JLPT drills are planned; see `PLAN.md` at the
repository root.

- **Author / package id:** `yuanzhe`, `com.yuanzhe.my_nihongo`
- **License:** GPL-3.0
- **Platforms:** Android (Windows, iOS and macOS are planned; Web is not targeted)
- **Framework:** Flutter, Dart SDK `^3.11.3`; CI uses Flutter `3.44.2`

This tree holds **concept** documentation — architecture, data formats, layout rules and per-feature
behavior — written for humans and agents who need to understand *why* the app behaves the way it
does. Function-by-function API documentation lives separately under [`functions/`](functions/)
and translation notes live in [`translation-guide.md`](translation-guide.md).

**These docs are the authoritative description of the code.** The repository's `AGENTS.md` is
deliberately limited to instructions for agents — workflow, authoring rules, the behavior contract,
and the release process — and points here for everything else. When code changes, these pages are
updated first; when docs and code disagree, verify against the code and then fix the page.

The shared WebDAV sync, backup, and ZIP engines are not in this repository. They live in the
`myapps_data` package embedded at `packages/myapps_data`, documented at
`packages/myapps_data/doc/en-us/`.

## Contents

### Core concepts

- [`architecture.md`](architecture.md) — app shell, state management, navigation, l10n, repository
  layout, and the core architectural rules the whole codebase follows.
- [`data-formats.md`](data-formats.md) — the content catalog schema, the `StudyRecord` progress
  model, on-disk JSON formats, and the full persisted-data inventory (what's synced, what's
  device-local).
- [`adaptive-layout.md`](adaptive-layout.md) — when a layout may split, where navigation lives, how
  many columns fit, and which rule each page uses.
- [`sync.md`](sync.md) — how the shared WebDAV engine is configured here: the one data module, its
  merge, and how conflicts reach the user.
- [`backup-restore.md`](backup-restore.md) — local backups and ZIP export/import as configured
  here.
- [`platform-notes.md`](platform-notes.md) — Android build state and the planned platforms.
- [`ci-cd.md`](ci-cd.md) — CI jobs, the build/verify command set, and fresh-clone (submodule) steps.
- [`version-history.md`](version-history.md) — release-by-release summary.

### Feature areas

- [`features/kana-reference.md`](features/kana-reference.md) — the kana chart page and the kana
  catalog behind it.
- [`features/content-catalog.md`](features/content-catalog.md) — the bundled vocabulary and grammar
  content: schema, ids, languages, licensing, and the browser pages.
- [`features/learning-progress.md`](features/learning-progress.md) — the synced progress record and
  the Learn dashboard.
- [`features/sync-and-backup.md`](features/sync-and-backup.md) — the sync, backup and ZIP screens
  under Settings › Data.

## Not covered here

- `doc/en-us/functions/` — per-source-file function-index pages. Maintained separately; start at
  [`functions/INDEX.md`](functions/INDEX.md).
- `PLAN.md` — the roadmap, at the repository root.

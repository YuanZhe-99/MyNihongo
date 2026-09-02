# Learning Progress

The one piece of synced user data: a `StudyRecord` per item the user has studied, stored in
`nihongo_progress.json` and merged across devices by the shared engine. The model is specified in
[`../data-formats.md`](../data-formats.md) and the merge in [`../sync.md`](../sync.md); this page
covers how the app uses it today and where it goes.

## Today (Phase 1)

- **Storage hub.** `NihongoStorage` (`lib/features/progress/services/nihongo_storage.dart`) owns the
  app directory, `storage_config.json`, and the data file. `load()` returns an empty `ProgressData`
  for a missing or blank file but **throws** on a corrupt one, so a later save cannot silently
  overwrite data that was merely unreadable. `save()` writes atomically (temp file, then rename)
  in the two-space format sync expects, then calls `AutoSyncService.instance.notifySaved()`.
  `upsertRecords()` replaces records by id and carries the container's `extraJson` through.
- **Provider.** `progressDataProvider` reads the file once; pages refresh it after a save or when
  auto-sync reports local data changed.
- **Learn dashboard.** `learn_page.dart` is the home tab: catalog counts (kana, words, grammar
  points), progress counts (items tracked, items mastered — or an honest "nothing tracked yet"),
  quick links to the three reference tabs, and the roadmap. It writes no records; nothing in Phase
  1 does. The model and its sync exist so that the review engine lands on a proven data path rather
  than inventing one.

## Where it goes

- **Phase 3 (`PLAN.md` M3.1):** `recordAnswer(id, correct)` updates counters, streak and the SM-2
  fields (`ease`, `intervalDays`, `dueAt`), bumps `modifiedAt`, and saves. The review queue is
  "records whose `dueAt` has passed" plus new items up to the daily limit.
- **Learner profile** (target level, daily goals, streak): planned as a record inside the same file
  with its own `modifiedAt`, so the ordinary conflict dialog covers it — rather than a second module
  with whole-file merge. Decision recorded in `PLAN.md`.
- **Phase 4:** JLPT attempts as `exam:<uuid>` records, or a second module if the file grows large.

## Invariants worth remembering

- Every timestamp is UTC.
- `copyWith` bumps `modifiedAt` unless told not to; a change that must not count as an edit passes
  the existing value explicitly.
- Unknown fields on records and on the container survive load, save and merge.
- A record's kind is derived from its id; a new kind in a newer build loads as `other` here and is
  merged, not dropped.
- Conflicts are shown, never auto-resolved.

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

## Scheduling (Phase 3 M3.1)

- **Writing an answer.** `NihongoStorage.recordAnswer(id, correct)` — or `recordAnswers` for a batch —
  loads the file, runs `Sm2Scheduler` over each answered item, bumps the streak once per day, and
  saves once. A batch is a single write and therefore a single auto-sync notification. An item with
  no record yet gets one: **a record is created by its first answer**, which is what makes "new items
  started today" countable without storing a counter.
- **The scheduler** is pure and lives in `sm2_scheduler.dart`. Its two departures from textbook SM-2 —
  quality derived from a right-or-wrong answer, and a gentler ease penalty — are derived in
  [`../algorithms/spaced-repetition.md`](../algorithms/spaced-repetition.md).
- **The queue** (`review_queue.dart`) is what to study now: due items ordered most-overdue-first, plus
  unstudied catalog ids, both capped by the daily limits. Due is judged by **local calendar day**
  while `dueAt` is stored as a UTC instant.
- **The learner profile** is a `profile:me` record in the same file, so the ordinary conflict dialog
  covers it. See [`../data-formats.md`](../data-formats.md) for the payload and for why it is not a
  second module and not a top-level object.
- **Providers.** `learnerProfileProvider` and `reviewQueueProvider` derive from `progressDataProvider`
  and the catalog, so an answer, a sync or a restore updates every page showing them with no second
  source of truth.

## Where it goes

- **Phase 3 (M3.2, M3.3):** quiz modes and the lesson path are what actually call `recordAnswer`;
  until they land the scheduler is written and tested but reached only through them.
- **Phase 4:** JLPT attempts as `exam:<uuid>` records, or a second module if the file grows large.

## Invariants worth remembering

- Every timestamp is UTC.
- `copyWith` bumps `modifiedAt` unless told not to; a change that must not count as an edit passes
  the existing value explicitly.
- Unknown fields on records and on the container survive load, save and merge.
- A record's kind is derived from its id; a new kind in a newer build loads as `other` here and is
  merged, not dropped.
- Conflicts are shown, never auto-resolved.
- The learner profile and lesson results share the file but are not studied items:
  `ProgressData.studyRecords` is the subset that is, and both the queue and the item counts use it.
- A streak is earned by answering. Only `recordAnswers` writes it, once a day; a settings write
  carries the stored value through rather than taking it from its caller.

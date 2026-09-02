# Data Formats

This page describes the bundled content schema, the `StudyRecord` progress model
(`lib/features/progress/models/study_record.dart`), the forward-compatibility pattern used
everywhere unknown JSON is encountered, and the full inventory of files the app persists to disk.
For how progress records get merged across devices, see [`sync.md`](sync.md).

## Content catalog (read-only, bundled)

Content ships as JSON assets under `assets/content/` and is parsed once per run by
`ContentRepository` into a `ContentCatalog`. It is neither synced nor backed up — it is the app's
data, not the user's — and it is versioned with the build through `schemaVersion`.

### Vocabulary (`vocab_seed.json`)

```json
{
  "schemaVersion": 1,
  "source": "seed",
  "license": "…",
  "entries": [
    {
      "id": "vocab:watashi",
      "level": "N5",
      "kanji": "私",
      "reading": "わたし",
      "romaji": "watashi",
      "pos": ["pronoun"],
      "meanings": { "en": ["I", "me"], "zh": ["我"] },
      "examples": [
        { "ja": "私は学生です。", "reading": "わたしはがくせいです。", "en": "I am a student.", "zh": "我是学生。" }
      ]
    }
  ]
}
```

- `id` — stable, `vocab:<slug>`; also the progress record id. **Required.**
- `level` — a JLPT label, `N5` through `N1`, parsed case-insensitively. **Required.**
- `kanji` — the written form when the word has one; absent for kana-only words. The model's
  `headword` is `kanji` when present, else `reading`.
- `reading` — kana reading. **Required.**
- `romaji` — optional romanization.
- `pos` — part-of-speech tags as content strings (`noun`, `verb-godan`, `verb-ichidan`,
  `verb-irregular`, `i-adjective`, `na-adjective`, `pronoun`, `adverb`, `expression`,
  `transitive`, `intransitive`).
- `meanings` — language code to a list of glosses.
- `examples` — each `{ja, reading?, <lang>: translation…}`; every key other than `ja` and `reading`
  is a language.

### Grammar (`grammar_seed.json`)

```json
{
  "schemaVersion": 1,
  "points": [
    {
      "id": "grammar:desu",
      "level": "N5",
      "pattern": "〜です",
      "structure": "N + です",
      "meaning": { "en": "is; am; are (polite copula)", "zh": "是（敬体判断句）" },
      "explanation": { "en": "…", "zh": "…" },
      "examples": [ { "ja": "これは本です。", "reading": "これはほんです。", "en": "This is a book.", "zh": "这是一本书。" } ]
    }
  ]
}
```

- `id`, `level`, `pattern` are required; `structure` is optional.
- `meaning` and `explanation` are language-keyed; a bare string is taken as English.

### Kana

The kana catalog is compiled in (`lib/features/kana/models/kana.dart`), not an asset: three `const`
tables (`kanaBasicRows`, `kanaVoicedRows`, `kanaYoonRows`) of `KanaEntry(hiragana, katakana,
romaji)`. Each entry's progress id is `kana:<hiragana>`; hiragana rather than romaji because romaji
is not unique (`ji` and `zu` each appear twice).

### Parsing rules

`LocalizedStrings.fromJson` accepts a map of language code to a string or a list of strings, or a
bare string taken as English. `resolve(locale)` returns the locale's language, then English, then
the first language present. Malformed entries — a missing id, level, headword or pattern — are
skipped rather than failing the whole file; content is bundled, so a bad entry is a content bug
caught by `test/content_catalog_test.dart`, not user data to protect.

### Content ids are a contract

A progress record is keyed by the id of the item it tracks. Renaming or removing a shipped id
orphans every user's progress on it. Ids may be added; a shipped id is never changed, and a retired
one is kept as an alias in the catalog (aliasing arrives with the JMdict import, `PLAN.md` M1.2).

## The `StudyRecord` model

One record per item the user has studied. Records carry no content — only an id, counters and
spaced-repetition state — and the catalog resolves the id to something readable.

### Identity

- `id` — `<kind>:<slug>`, the catalog item's id. The sync merge key.
- `kind` — **derived** from the id prefix by `studyKindOf`: `kana`, `vocab`, `grammar`, or `other`
  for a prefix this build does not know. Not stored, so nothing can fall out of step with the id,
  and a record written by a newer build with a new kind still loads and merges.

### Counters

- `correct`, `wrong` — lifetime answer counts. `reviews` is their sum; `accuracy` is
  `correct / reviews`, 0 before the first review.
- `streak` — consecutive correct answers, reset by a wrong one.

### Spaced repetition (SM-2 fields, scheduled from Phase 3)

- `intervalDays` — current interval, 0 until the first review.
- `ease` — ease factor, default `2.5` (`defaultStudyEase`).
- `dueAt` — next due time, UTC; null until the first review.
- `lastReviewedAt` — UTC; null until the first review.

### Stage derivation

`StudyStage` (`fresh`, `learning`, `mastered`) is **derived**, not stored: `fresh` until
`lastReviewedAt` is set, `mastered` once `intervalDays >= 21` (`masteredIntervalDays`), `learning`
in between. The threshold is a display convention; it changes no scheduling.

### Timestamps

`createdAt` and `modifiedAt` are UTC. `copyWith` sets `modifiedAt` to now unless told otherwise,
which is what makes every edit visible to the sync merge; pass the existing value explicitly for a
change that must not count as an edit. A record parsed without `modifiedAt` gets the Unix epoch so
it loses every merge rather than winning by accident.

### JSON shape

```json
{
  "records": [
    {
      "id": "kana:あ",
      "correct": 12,
      "wrong": 2,
      "streak": 5,
      "intervalDays": 6,
      "ease": 2.6,
      "dueAt": "2026-09-08T00:00:00.000Z",
      "lastReviewedAt": "2026-09-02T09:15:00.000Z",
      "createdAt": "2026-08-20T10:00:00.000Z",
      "modifiedAt": "2026-09-02T09:15:00.000Z"
    }
  ]
}
```

Nullable fields are omitted rather than written as `null`.

### Compatibility: unknown-JSON-field preservation (`extraJson`)

`StudyRecord` and `ProgressData` (the top-level `{records: [...]}` container) each carry an
`extraJson` map holding any JSON keys the current app version doesn't recognize. The pattern:

- `fromJson()` computes `extraJson` as "every key in the raw JSON minus the known keys for this
  type", and also routes a **nullable** field's value that fails to parse (an unparseable `dueAt`
  or `lastReviewedAt`) back into `extraJson` instead of discarding it. A counter or SRS field that
  fails to parse takes its default and is written back as that default — a typed value and a raw
  one cannot share a key.
- `toJson()` starts from a copy of `extraJson` and then overlays the known fields on top, so
  unknown keys ride along unchanged and can never shadow a real one. A nullable field is written
  only when set, so a preserved raw value under its key survives.
- `withPreservedUnknownJson(sources)` merges `extraJson` from multiple candidate sources (the local
  and remote copy of the same record during a sync merge) so a field unknown to *this* version of
  the app, but present on either side, survives the merge. Nested maps merge key by key.

This is what lets an older app version avoid silently deleting a field introduced by a newer
version during ordinary saves, imports, or sync merges.

### JSON pretty-printing

All JSON written to disk — the data file, sync uploads, backups — uses
`JsonEncoder.withIndent('  ')`. This is not cosmetic: the shared sync engine writes merged JSON
with the same formatting as local `NihongoStorage` saves, so an unchanged file hits a raw
string-equality fast path on the next sync instead of triggering a spurious re-upload.

## Persisted Data Inventory

The default app data directory is `<documents>/MyNihongo` — the platform application-documents
directory on Android. Custom storage paths are stored in `storage_config.json`; changing the path
migrates everything in the folder except that config file.

| Data | File | Synced | Notes |
| --- | --- | --- | --- |
| Learning progress | `nihongo_progress.json` | Yes | Per-record by `id` and `modifiedAt`; unknown fields preserved |
| Theme mode | `storage_config.json` | No | Device-specific preference (`themeMode`: `light`/`dark`; absent means system) |
| Locale | `storage_config.json` | No | Device-specific preference (`locale`: `en`/`zh`; absent means system) |
| Storage path override | `storage_config.json` | No | Device-specific path (`storagePath`) |
| Auto-backup enabled | `storage_config.json` | No | Device-specific config (`autoBackupEnabled`) |
| Backup retention days | `storage_config.json` | No | Device-specific config (`backupRetentionDays`) |
| WebDAV configuration | `webdav_config.json` | No | Local secret/config only |
| Sync base snapshot | `.sync_base/nihongo_progress.json` | No | Local merge tracking |
| Upload lock record | `.sync_base/upload_lock.json` | No | Detects an upload interrupted mid-flight |
| Local backups | `backups/backup_*.json` | No | Local recovery; v2 bundles |
| Backup image blobs | `backups/blobs/` | No | Present in the shared format; always empty here — no images |

### `storage_config.json`

Holds every device-local preference from the table above that isn't WebDAV configuration. None of
this file is synced — it is intentionally device-specific. Keys are removed rather than written when
set back to their default, so a fresh install and a reset install produce the same file.

### `webdav_config.json`

WebDAV connection details and sync preferences (server URL, credentials, remote path, auto-sync
toggle). Never synced itself. The default remote path is `/MyNihongo`. See [`sync.md`](sync.md).

### `.sync_base/`

Holds `.sync_base/nihongo_progress.json`, the last-known-merged snapshot used as the three-way merge
base on the next sync, and `.sync_base/upload_lock.json`, which lets the next launch detect an
upload that was interrupted mid-flight.

### `backups/`

`backups/backup_*.json` — backup bundles in the shared v2 format described in
[`backup-restore.md`](backup-restore.md).

# lib/features/content/services/study_item_labels.dart

Turns a progress record id into something a person recognizes. The sync conflict dialog is the only
caller today; it must be able to name every record it is handed, including one whose id this build
no longer ships.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Turn a progress record id into something a person recognizes. |
| `StudyItemLabel` | constructor | B | Create a study item label instance. |
| `resolveStudyItemLabel` | top-level function | A | Look up the display name for a progress record id. |

### `resolveStudyItemLabel`

- **Purpose:** Look up the display name for a progress record id.
- **Inputs:** `id` — a `kana:`, `vocab:` or `grammar:` id; `catalog` — the parsed content, or null
  when it has not loaded; `locale` — the UI locale, which picks the language of the meaning shown.
- **Returns:** `StudyItemLabel`; never null.
- **Side effects:** None.
- **Algorithm:** Switch on `studyKindOf(id)`. `kana:` resolves through `kanaEntryById` to a title of
  `<hiragana> · <katakana>` with the romaji beneath. `vocab:` resolves through
  `ContentCatalog.vocabById` to the headword, with the reading and first meaning beneath, and the
  reading is left out when it equals the headword. `grammar:` resolves to the pattern with its
  meaning beneath. Anything unresolved returns the raw id with `resolved == false`.
- **Usage:** `resolveStudyItemLabel(conflict.id, catalog: catalog, locale: locale)`.
- **Notes:** Vocabulary lookups are alias-aware, so an id retired in favour of a JMdict-keyed one
  still names its entry. An unresolved label is shown with an "unknown item" caption rather than
  hidden — progress ids outlive the catalog, and a record must never be silently unresolvable.

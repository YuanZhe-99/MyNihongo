# lib/shared/widgets/part_of_speech_labels.dart

Names a part-of-speech tag in the learner's language.

The vocabulary detail sheet printed these tags verbatim — `verb-godan`, `suru-verb` — in every
language, which is jargon to an English reader and untranslated to everyone else. The same
token-to-ARB switch as `formLabel` in
[../../features/sentence/widgets/form_labels.md](../../features/sentence/widgets/form_labels.md).

Consumer: `content_sheets.dart` (`showVocabDetailSheet`).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`posLabel`](#poslabel) | top-level function | A | Name a part-of-speech tag in the learner's language. |

## Documentation

### `String posLabel(AppLocalizations l10n, String tag)` <a id="poslabel"></a>

- **Kind:** top-level function
- **Purpose:** Name a part-of-speech tag in the learner's language.
- **Inputs:** `l10n`, and a `tag` from the content's closed set (`vocabPartsOfSpeech` in
  `lib/features/content/models/parts_of_speech.dart`).
- **Returns:** `String` — the localized name, or the tag itself when it is not one the app knows.
- **Side effects:** None.
- **Algorithm:** A switch from each of the 23 tags (`noun`, `pronoun`, `proper-noun`, `verb-godan`,
  `verb-ichidan`, `verb-irregular`, `suru-verb`, `transitive`, `intransitive`, `auxiliary`,
  `i-adjective`, `na-adjective`, `no-adjective`, `adnominal`, `adverb`, `particle`, `conjunction`,
  `interjection`, `expression`, `counter`, `numeric`, `prefix`, `suffix`) to its `pos…` ARB string,
  with the tag itself as the default.
- **Usage:**
  ```dart
  entry.partsOfSpeech.map((tag) => posLabel(l10n, tag)).join(', ')
  ```
  (from the part-of-speech line in `showVocabDetailSheet`)
- **Notes:** Unlike `formLabel`, the switch is over a `String` rather than an enum, so it cannot be
  exhaustive and a new tag without a name is not a compile error. The fallback is defensive only:
  `content_catalog_test` already fails on a tag outside `vocabPartsOfSpeech`, so a new tag has to be
  added to that set — and should be given an ARB name here in the same change.

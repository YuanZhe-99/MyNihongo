# lib/features/sentence/widgets/form_labels.dart

Names an inflected form in the learner's language.

The token chips in the sentence lab printed these as their Dart enum names —
`polite + negative` — in every language, which is English to an English reader and
nothing at all to a Chinese one. Fixed in M3.2, where the conjugation quiz needed
to name a form anyway.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| [`formLabel`](#formlabel) | top-level function | A | Name an inflected form. |
| `formChainLabel` | top-level function | B | Name a whole chain of recovered forms. |

## Documentation

### `String formLabel(AppLocalizations l10n, InflectionForm form)` <a id="formlabel"></a>

- **Kind:** top-level function
- **Purpose:** Name an inflected form in the learner's language.
- **Inputs:** `l10n` and the form.
- **Returns:** `String`.
- **Side effects:** None.
- **Algorithm:** An exhaustive switch over all 22 values.
- **Usage:** The sentence lab's token chips, and the conjugation quiz's prompt.
- **Notes:** Exhaustive on purpose — a new `InflectionForm` without a name is a compile error rather
  than an English word appearing in a Chinese UI. The **prompt handed to the on-device model still
  uses the enum names**: that text is read by a model rather than a person, and the English names are
  what it was trained on.

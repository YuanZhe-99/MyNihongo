# lib/features/sentence/widgets/token_chips.dart

The sentence as a row of tappable word chips: the "Words" section of the sentence lab.

Consumers: `sentence_lab_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `TokenChips` | class | B | The sentence as chips, one per word. |
| `TokenChips.build` | method | B | Build the chip row, skipping punctuation. |
| [`_chip`](#chip) | method | A | Build one word's chip. |
| `_open` | method | B | Open the catalog entry, or the function word's own gloss, resolved through `LocalizedStrings.lookupOrder`. |
| [`_label`](#label) | static method | A | Name a category in the user's language. |
| `_colorsFor` | static method | B | Pick the scheme colours for a category. |

## Documentation

### `Widget _chip(BuildContext context, ThemeData theme, AppLocalizations l10n, Token token)` <a id="chip"></a>

- **Kind:** method
- **Purpose:** Show one word, what was done to it, and what kind of word it is.
- **Inputs:** The context, theme, localizations and the token.
- **Returns:** A tappable chip.
- **Side effects:** None until tapped.
- **Algorithm:** Three lines: the surface as written, the form chain when the word was inflected,
  and the category name.
- **Usage:** `build`, once per non-punctuation token.
- **Notes:** **Colour is never the only carrier of meaning** — the category name is written under
  every chip, so the grouping survives a colour-blind reader and a grayscale screenshot. A word in
  no dictionary is drawn in the error colour *and* labelled as such, because a wrong parse the
  reader cannot see is worse than one they can.

### `static String _label(AppLocalizations l10n, TokenCategory category)` <a id="label"></a>

- **Kind:** static method
- **Purpose:** Name a token's kind for a learner.
- **Inputs:** The localizations and the category.
- **Returns:** One of six names.
- **Side effects:** None.
- **Algorithm:** A switch collapsing twenty-four categories onto six.
- **Usage:** `_chip`.
- **Notes:** Six names for twenty-four categories on purpose. A learner reading their own sentence
  wants to know that a word is a particle; that it is a binding particle rather than a conjunctive
  one is an implementation detail of the chunker, and printing it would spend the reader's attention
  on a distinction the app never explains.

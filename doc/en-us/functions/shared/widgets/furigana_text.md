# lib/shared/widgets/furigana_text.dart

Japanese text with its reading printed over the characters that need it, and plain text everywhere
that cannot be done. Every place that used to draw a `Text` of Japanese draws one of these instead,
so one preference reaches the whole app from one file.

Consumers: `reference_widgets.dart`, `content_sheets.dart`, `vocab_page.dart`, `token_chips.dart`,
`quiz_runner.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `FuriganaText` | class | B | Japanese text with its reading over the kanji. |
| [`FuriganaText.build`](#build) | method | A | Build the ruby text, or plain text. |
| `_Ruby` | class | B | One kanji run with its kana above it. |
| `_Ruby.build` | method | B | Stack one reading over one run of characters. |
| `_tight` | constant | B | Stop the ruby line adding its own leading. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the ruby text, or plain text when it cannot be built.
- **Inputs:** The build context and ref; the widget's `text`, `reading`, `style`, `rubyScale`,
  `forceOff` and `bracketFallback`.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** Falls back to a plain `Text` when `forceOff` is set, when the preference is off,
  or when the aligner returns null or finds nothing to print. Otherwise a `Text.rich` whose kanji
  runs are `WidgetSpan`s holding a two-line column, aligned on the ideographic baseline so the base
  text still sits on the line, and whose kana runs stay ordinary `TextSpan`s so a sentence still
  wraps between them.
- **Usage:** Anywhere Japanese is shown and a reading is available.
- **Notes:** The alignment is recomputed in the build rather than cached: it is a pure function of
  two short strings, memoized inside, and cheaper than the plumbing a cache would need. `forceOff`
  is for the places where the reading is the question, since a quiz asking how a word is read must
  not print the answer above it. `bracketFallback` is for the places whose plain form already
  showed the reading in brackets, so turning furigana off gives back exactly what was there before
  rather than losing the reading. **The whole string is the widget's semantic label**, so a screen
  reader hears the word rather than its pieces; `find.text` in a test does not, and tests match on
  the widget instead.

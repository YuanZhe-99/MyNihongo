# lib/shared/widgets/furigana_text.dart

Japanese text with its reading printed over the characters that need it, and plain text everywhere
that cannot be done. Every place that used to draw a `Text` of Japanese draws one of these instead,
so one preference reaches the whole app from one file.

Consumers: `reference_widgets.dart`, `content_sheets.dart`, `vocab_page.dart`, `token_chips.dart`,
`quiz_runner.dart`, `answer_panes.dart`, `generated_examples.dart`, `scenario_page.dart`.

The layout is a `Wrap` of fixed-height boxes, one per run, **not** a `Text.rich` of `WidgetSpan`s.
A span holding a two-line column reports the *ruby* line's baseline as its own, so the plain kana
between the kanji were laid out level with the furigana and the word rendered as two rows of
unrelated text. Every box reserves the same two slots — a ruby line over a base line — so aligning
their tops puts every base character at the same height whatever its glyphs measure.

Both reservations are exact because **both slots force a strut**. That is the second bug this file
has had, found on a Pixel 10 on 2026-09-04: the ruby slot used to be reserved as `rubyScale × 1.15`,
a guess that a font's ascent plus descent fits in 1.15 em, and it had no strut to hold it there. The
app ships no font, so Japanese comes from the system CJK face, which needs about 1.4 — and a
`SizedBox` constrains without clipping while a paragraph paints from the top, so the surplus landed
on the word. The base slot never had the problem; it has forced its own strut since it was written.

Sizes are read through `MediaQuery.textScalerOf`, because `fontSize` is what the style asks for and
the engine paints the scaled value. Reserving from the nominal number was the other half of the same
bug, and the half a widget test can hold — the test font has 1.0 em metrics, so the font-metric half
is only reachable on a device.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `FuriganaText` | class | B | Japanese text with its reading over the kanji. |
| [`FuriganaText.build`](#build) | method | A | Build the ruby text, or plain text. |
| `_pieces` | function | B | Split the alignment into the boxes a line is laid out from. |
| `_RubyBox` | class | B | One run of base text with its reading reserved above it. |
| `_RubyBox.build` | method | B | Two fixed slots, a reading over a run. |
| `rubyLineHeight` | constant | B | How tall the reading's line box is, as a multiple of its own size. |
| `baseLineHeight` | constant | B | The base line's height when the caller's style names none. |

## Documentation

### `Widget build(BuildContext context, WidgetRef ref)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Build the ruby text, or plain text when it cannot be built.
- **Inputs:** The build context and ref; the widget's `text`, `reading`, `style`, `rubyScale`,
  `forceOff` and `bracketFallback`.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** Falls back to a plain `Text` when `forceOff` is set, when the preference is off, or
  when the aligner returns null or finds nothing to print. Otherwise: scale the base size by the
  viewer's text scaler, derive the ruby style from it, reserve `rubySize × rubyLineHeight` for the
  reading and `size × height` for the word, and lay one `_RubyBox` per run into a top-aligned `Wrap`.
- **Usage:** Anywhere Japanese is shown and a reading is available.
- **Notes:** The alignment is recomputed in the build rather than cached: it is a pure function of
  two short strings, memoized inside, and cheaper than the plumbing a cache would need. `forceOff`
  is for the places where the reading is the question, since a quiz asking how a word is read must
  not print the answer above it. `bracketFallback` is for the places whose plain form already showed
  the reading in brackets, so turning furigana off gives back exactly what was there before rather
  than losing the reading. **The whole string is the widget's semantic label**, so a screen reader
  hears the word rather than its pieces; `find.text` in a test does not, and tests match on the
  widget instead.

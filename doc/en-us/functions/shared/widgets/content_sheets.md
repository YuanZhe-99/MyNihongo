# lib/shared/widgets/content_sheets.dart

The detail sheets for a word, a grammar point and a kana, with chips linking to the entries around
them. Lifted out of the vocabulary and grammar pages in `PLAN.md` M1.3 so all three pages can open
each other's sheets. See
[../../../features/content-catalog.md](../../../features/content-catalog.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Show a word, a grammar point or a kana in a bottom sheet. |
| `_sectionLabel` | top-level function | B | Render a section heading inside a sheet. |
| `_sheetBody` | top-level function | B | Wrap a sheet's contents in the shared padding and scrolling. |
| `_chipSection` | top-level function | B | Render a labelled row of tappable chips. |
| [`showVocabDetailSheet`](#showvocabdetailsheet) | top-level function | A | Show a word, with the grammar its examples use. |
| [`showGrammarDetailSheet`](#showgrammardetailsheet) | top-level function | A | Show a grammar point, with the words its examples use. |
| [`showKanaDetailSheet`](#showkanadetailsheet) | top-level function | A | Show a kana, with its note and example words. |

Sheets rather than routes, because a sheet keeps the list position underneath and works the same in
one column and in several. Opening a linked sheet stacks a second sheet, so dismissing it returns
to the first, which is what "back" should mean here.

### `showVocabDetailSheet` <a id="showvocabdetailsheet"></a>

- **Purpose:** Show a word's full entry, with the grammar its examples use.
- **Inputs:** `context`, `catalog`, `entry`, `locale`.
- **Returns:** `Future<void>` completing when the sheet closes.
- **Side effects:** Pushes a modal bottom sheet.
- **Algorithm:** Headword, level, reading and romaji, parts of speech, every meaning in the UI
  language, the examples, then a chip per grammar point found in those examples, deduplicated.
- **Usage:** A vocabulary tile, and the word chips on the other two sheets.
- **Notes:** The chips are matched by substring, not by parsing, so they are labelled as what the
  example uses rather than presented as analysis; see `content_links.dart`.

### `showGrammarDetailSheet` <a id="showgrammardetailsheet"></a>

- **Purpose:** Show a grammar point's full entry, with the words its examples use.
- **Inputs:** `context`, `catalog`, `point`, `locale`.
- **Returns:** `Future<void>`.
- **Side effects:** Pushes a modal bottom sheet.
- **Algorithm:** Pattern, level, meaning, structure, explanation, examples, then a chip per word
  found in the examples.
- **Usage:** A grammar tile, and the grammar chips on the vocabulary sheet.
- **Notes:** The word chips are limited to the point's own level and below.

### `showKanaDetailSheet` <a id="showkanadetailsheet"></a>

- **Purpose:** Show one kana in both scripts, with its note and example words.
- **Inputs:** `context`, `catalog`, `entry`, `locale`.
- **Returns:** `Future<void>`.
- **Side effects:** Pushes a modal bottom sheet.
- **Algorithm:** Both scripts large with the romaji beside them, the stroke count and hint when the
  notes file has one, chips for the kana it is confused with, then the easiest and most common
  words that start with it.
- **Usage:** A kana table cell, a kana search result, and the confusable chips on another kana
  sheet.
- **Notes:** The example words are the point of the sheet. A kana chart teaches shapes; a beginner
  needs to see the shape inside a word to read it. A kana with neither a note nor any example word
  says so rather than showing an empty sheet.

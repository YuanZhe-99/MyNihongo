# Content Catalog

The bundled, read-only vocabulary and grammar content, the models that parse it, and the two
browser pages that show it. The schema itself is in [`../data-formats.md`](../data-formats.md);
this page is about the rules and the UI.

## Files and models

| Asset | Parsed into | Model |
|---|---|---|
| `assets/content/vocab_seed.json` | `ContentCatalog.vocab` | `VocabEntry` |
| `assets/content/grammar_seed.json` | `ContentCatalog.grammar` | `GrammarPoint` |

`ContentRepository.load()` reads both through `rootBundle` and `contentCatalogProvider` exposes the
result to pages. Shared value types: `JlptLevel` (N5–N1, label and case-insensitive parse),
`LocalizedStrings` (language-keyed lists with English fallback), `ContentExample` (a Japanese
sentence, optional reading, translations).

## Rules every entry follows

Enforced by `test/content_catalog_test.dart`:

1. **Unique, prefixed ids.** `vocab:` and `grammar:` prefixes; the kana catalog's `kana:` ids share
   the same namespace. `studyKindOf(id)` must return the matching kind.
2. **Both shipped languages.** Every meaning, explanation and example translation carries `en` and
   `zh`. One UI language must never show blanks the other does not.
3. **A JLPT level** on every entry.
4. **Examples on every grammar point**, with readings where the sentence contains kanji.
5. **Japanese checked by a person.** A wrong example teaches the wrong thing.

Rules that are policy rather than test:

- **Shipped ids never change.** Progress is keyed by them. A retired id is kept as an alias (the
  alias mechanism arrives with the JMdict import).
- **Content is data.** No word list in Dart code; the kana tables are the one deliberate exception
  because they are fixed and tiny.

## Seed content and its replacement

The seed is hand-written: 24 N5 words and 8 N5 grammar points, enough to make the pages real and
the tests meaningful. `PLAN.md` M1.2 replaces the vocabulary with a JMdict-derived catalog
(EDRDG, CC BY-SA 4.0) joined to an openly licensed JLPT list, built by an offline `tool/` script,
and grows the grammar level by level by hand. When the catalog grows large, parsing moves to
`compute` and lookups get an index; if load time on a mid-range phone passes ~300 ms, the asset
becomes a prebuilt SQLite file with the JSON kept as the build input.

### Licensing and attribution

The seed content is original and ships under the app's GPL-3.0. Third-party content is committed
only with its license and attribution recorded here and on the in-app license page:

| Source | License | Status |
|---|---|---|
| Hand-written seed | GPL-3.0 (with the app) | Shipped |
| JMdict / EDRDG | CC BY-SA 4.0 | Planned (M1.2) |

## The browser pages

`vocab_page.dart` and `grammar_page.dart` have the same shape and share their chips, badges, example
rendering and empty state through `lib/shared/widgets/reference_widgets.dart`.

- **Search** — vocabulary matches headword, reading, romaji or any gloss in any language; grammar
  matches pattern, structure or meaning (the explanation is deliberately not searched — it would
  match nearly everything on common words). Queries are trimmed and lowercased once.
- **Level filter** — a `Wrap` of choice chips: all levels, then N5 to N1. Exactly one is selected.
- **Result count** under the chips.
- **Tiles** — headword (or pattern), a reading/romaji (or structure) line, one meaning line in the
  UI language, and a level badge. A kana-only word drops the reading line so it does not repeat
  itself.
- **Detail sheet** — a modal bottom sheet with the full entry: all meanings, parts of speech,
  structure, explanation, and examples with readings and translations. A sheet rather than a route
  so the list position survives and the same widget works in one column and in several.
- **Layout** — rows, not tiles, are the `ListView.builder` items, so the list stays virtualized at
  two or more columns. Column count is `referenceColumnCount`; see
  [`../adaptive-layout.md`](../adaptive-layout.md).

Content is shown in the UI language (`Localizations.localeOf`), falling back to English, then to
whatever language the entry has.

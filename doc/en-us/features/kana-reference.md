# Kana Reference

The kana chart is two files: the catalog, `lib/features/kana/models/kana.dart`, and the page,
`lib/features/kana/views/kana_page.dart`. The page is **UI-only** — it reads no user data and has no
persisted state beyond ordinary widget state — but unlike MyAnime!!!!!'s version, the data behind
it is a public model so quizzes, pronunciation practice and the progress catalog can share one
source.

It occupies the second of the app's five tabs (see [`../architecture.md`](../architecture.md)).

## The catalog

- `KanaEntry(hiragana, katakana, romaji)`, with `kana(script)` to pick a script and `matches(query)`
  for search (substring on hiragana, katakana, or lowercased romaji; no romanization variants, so
  `si` does not find `shi`).
- `KanaRow(label, entries)` — one consonant row; `null` slots mark combinations that do not exist
  (`yi`, `ye`, `wi`, `wu`, `we`).
- Three `const` tables: `kanaBasicRows` (gojūon plus ん), `kanaVoicedRows` (dakuten and handakuten),
  `kanaYoonRows` (contracted sounds). Column headers `kanaVowelColumns` and `kanaYoonColumns`.
- `allKanaEntries()` flattens the tables once each; `matchingKanaEntries(query)` trims, lowercases
  and searches.
- **Progress id:** `KanaEntry.progressId` is `kana:<hiragana>` — hiragana, not romaji, because
  romaji is not unique (じ/ぢ are both `ji`, ず/づ both `zu`). This id is a compatibility contract;
  see [`../data-formats.md`](../data-formats.md).

## The page

- Hiragana and katakana segmented switching.
- Kana and romaji search; results replace the tables, the rules stay.
- Basic gojūon table, dakuten/handakuten table, yōon table.
- Pronunciation rule cards for mora rhythm, stable vowels, dakuten, yōon, sokuon, long vowels, and
  ん.

## Layout

The page is adaptive. On a window the app-wide split rule allows, and wide enough to hold two kana
tables of at least `kanaTableMinWidth` (330 logical pixels), it lays its sections out in two columns
— the tall gojūon and yōon tables on the left, the short dakuten table and the rule cards on the
right — and puts the script switch beside the search field instead of above it. Otherwise it keeps
the single stacked column. The rule cards flow one or two across on their own, measured against
whatever width the section is actually given.

The practical result: a Z Fold 8 unfolded in landscape, a Fold 8 Ultra either way, a Pixel 10 Pro
Fold, a tablet in landscape and a desktop window get two columns; the Fold 8 in portrait, the
narrower unfolded foldables, tablets in portrait and every phone keep one. Both gates and the
numbers behind them are in [`../adaptive-layout.md`](../adaptive-layout.md), and
`test/kana_layout_ui_test.dart` pins each of those devices.

## The detail sheet

Tapping a cell, or a search result, opens the kana in a bottom sheet: both scripts large with the
romaji beside them, the stroke count and teaching note from `assets/content/kana_notes.json` when
there is one, chips for the kana it is confused with, and the easiest and most common words that
start with it. Those example words are the point of the sheet — a chart teaches shapes, and a
beginner needs to see the shape inside a word to read it. The word chips open the vocabulary sheet,
and the confusable chips open the other kana, so ツ and シ can be compared without leaving the page.
The sheet lives in `lib/shared/widgets/content_sheets.dart`; the ordering rule is
`vocabStartingWithKana` in `content_links.dart`.

## Planned

Phase 2 adds text-to-speech on long-press and a kana listening quiz; Phase 3 adds kana quiz modes
whose results become `kana:` progress records.

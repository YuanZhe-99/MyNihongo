# Content Catalog

The bundled, read-only vocabulary and grammar content, the models that parse it, and the two
browser pages that show it. The schema itself is in [`../data-formats.md`](../data-formats.md);
this page is about the rules, the pipeline that builds the files, and the UI.

## Files and models

| Asset | Parsed into | Model |
|---|---|---|
| `assets/content/vocab.json` | `ContentCatalog.vocab` | `VocabEntry` |
| `assets/content/grammar/n5.json` (one file per level) | `ContentCatalog.grammar` | `GrammarPoint` |
| `assets/content/kana_notes.json` | `ContentCatalog.kanaNotes` | `KanaNote` |
| `assets/content/vocab_zh.json` | nothing at runtime | build input, see below |

`ContentRepository.load()` reads the strings on the calling isolate and hands them to `compute` for
decoding, so the roughly 2 MB vocabulary file does not drop a frame at launch. The vocabulary is
read with `cache: false`, because it is parsed exactly once and the bundle's string cache would
otherwise hold a second copy for the life of the process. Widget tests set
`ContentRepository.parseInIsolate = false`, since `compute` never completes under `FakeAsync`.

`contentCatalogProvider` exposes the result to pages. Lookups are maps built once at construction:
`vocabById`, `grammarById` and `canonicalId` are constant time, and `vocabById` resolves aliases to
the same entry object as the primary id. Shared value types: `JlptLevel` (N5 to N1, label and
case-insensitive parse), `LocalizedStrings` (language-keyed lists with English fallback),
`ContentExample` (a Japanese sentence, optional reading, translations).

## The vocabulary pipeline

`tool/import_vocab.dart` builds `vocab.json` offline; its rules live in
`tool/src/vocab_import_core.dart` so they can be unit-tested without the 117 MB dictionary.

| Input | Where | Committed? |
|---|---|---|
| JLPT lists keyed by JMdict sequence number | `tool/content/jlpt/n{1..5}.csv` | Yes, byte-identical to upstream |
| JMdict body (`jmdict-eng-<version>.json`) | `tool/data/` | **No** — git-ignored, downloaded by hand |
| Hand-written seed words | `tool/content/vocab_seed.json` | Yes |
| Chinese gloss overlay | `assets/content/vocab_zh.json` | Yes |

```bash
dart run tool/import_vocab.dart
dart run tool/import_vocab.dart --overlay-only
```

The tool exits 1 and prints the download URL when the dictionary is missing, and exits 1 rather
than writing a catalog with holes when a list names a sequence number the dictionary does not
carry. It writes no timestamp and sorts by level, then reading, then id, so a rebuild with
unchanged inputs produces an empty `git diff`.

The rules that decide what a learner sees:

- **Level.** Lists are walked N5 first, so a word on two lists is taught at the easier one and its
  id is fixed there.
- **Written form.** The list's form wins, unless JMdict marks it as an uncommon or search-only
  form while another form is common. The N5 list gives 明い for あかるい, and the app shows 明るい.
  A word with no kanji, or whose first sense is tagged "usually kana", is headed by its reading.
- **Meanings.** Up to three senses, each joining up to three English glosses. Archaic, obscure,
  rare and offensive senses are skipped, as are senses restricted to a different written form. A
  word made up entirely of skipped senses falls back to the unfiltered read: shipping a word with
  no meaning is worse than showing its one rare sense.
- **Parts of speech.** JMdict's fine-grained tags are mapped onto the closed set in
  `lib/features/content/models/parts_of_speech.dart`, ordered by that set so the output is stable.
  An unmapped tag is dropped and counted on stderr.
- **Known-bad list rows.** Three rows point at a homograph rather than the word they mean: コップ
  at "police officer", ボタン at 牡丹 "tree peony", and だんだん at a dialect "thank you". The
  corrections are a table in the tool, so the committed CSV files stay identical to upstream and
  the reason for each change stays readable.
- **Seed words.** Each carries a `jmdictSeq`. Its hand-written glosses and examples win over
  JMdict's, its old `vocab:<slug>` id becomes an alias of the new `vocab:jm<seq>` id, and it ships
  whether or not any list names it.

### Chinese glosses

Chinese is authored level by level in `assets/content/vocab_zh.json`, keyed by catalog id, and
folded into the catalog by the tool. Its `reviewed` flag tracks authoring only and never reaches
`vocab.json`: it is false until a native speaker has checked the entry. **The current N5 glosses
are machine-authored and unreviewed.** Entries with no row ship English only and the UI falls back
to it, which is why N4 and above currently show English.

The overlay is bundled rather than kept under `tool/` so the test can read it through `rootBundle`
and compare it against what the catalog actually ships. That catches an overlay edit that never
had `--overlay-only` run over it.

## Rules every entry follows

Enforced by `test/content_catalog_test.dart`:

1. **Unique, prefixed ids**, aliases included. `vocab:` and `grammar:` prefixes; the kana catalog's
   `kana:` ids share the same namespace. `studyKindOf(id)` must return the matching kind. No alias
   may collide with a primary id.
2. **Every retired id still resolves.** All 24 hand-written seed ids must find their entry and be
   listed in its `aliases`.
3. **An English meaning on every entry**, and **Chinese on N5 and on every seed word**.
4. **A JLPT level** on every entry, with plausible counts per level and no repeated headword and
   reading inside one level.
5. **Only known part-of-speech tags.**
6. **Both languages on every grammar point**, with examples, and readings where the sentence
   contains kanji.
7. **Kana notes name kana that exist**, in both languages.
8. **Japanese checked by a person.** A wrong example teaches the wrong thing.

Rules that are policy rather than test:

- **Shipped ids never change.** Progress is keyed by them. A retired id is kept as an alias.
- **Content is data.** No word list in Dart code; the kana tables are the one deliberate exception
  because they are fixed and tiny.

### Licensing and attribution

Original content ships under the app's GPL-3.0. Third-party content is committed only with its
license and attribution recorded here and on the in-app license page:

| Source | License | Status |
|---|---|---|
| Grammar, examples, kana notes, Chinese glosses, seed words | GPL-3.0 (with the app) | Shipped |
| JMdict / EDICT (EDRDG, Monash University) | CC BY-SA 4.0 | Shipped |
| JLPT lists (stephenmk/yomitan-jlpt-vocab; underlying lists by Jonathan Waller, CC BY) | CC BY-SA 4.0 | Shipped |

CC BY-SA is why the app carries the attribution in Settings › License rather than only in a
repository file.

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

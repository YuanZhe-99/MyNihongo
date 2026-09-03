# tool/src/vocab_import_core.dart

The rules that decide what the vocabulary catalog contains. Pure: every file read and write lives
in [`../import_vocab.md`](../import_vocab.md), so these are unit-tested on fixtures by
`test/tool/vocab_import_core_test.dart` rather than against the 117 MB dictionary.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | `library` | B | Build `assets/content/vocab.json` from JMdict and the JLPT lists. |
| `JlptRow` | constructor | B | Create a JLPT row instance. |
| `ImportResult` | constructor | B | Create an import result instance. |
| `jmdictPosMap` | top-level `const` | — | JMdict part-of-speech tags mapped onto the app's closed set. |
| `skippedSenseMisc` | top-level `const` | — | Sense tags whose glosses are not worth teaching. |
| `importLevels` | top-level `const` | — | Levels in import order, easiest first. |
| `jlptSeqCorrections` | top-level `const` | — | List rows that point at the wrong JMdict entry. |
| `parseJlptCsv` | top-level function | B | Parse one JLPT list CSV. |
| `indexJmdict` | top-level function | B | Index a decoded JMdict body by sequence number. |
| `formsOf` | top-level function | B | Read the written or read forms of a JMdict word. |
| [`chooseForms`](#chooseforms) | top-level function | A | Decide how a word should be written and read. |
| `_isUsuallyKana` | top-level function | B | Report whether JMdict says the word is usually written in kana. |
| [`glossesOf`](#glossesof) | top-level function | A | Collect the English glosses worth showing. |
| `_glosses` | top-level function | B | Read a word's glosses, optionally filtering unhelpful senses. |
| `_appliesTo` | top-level function | B | Test a sense's form restriction. |
| `posOf` | top-level function | B | Map a word's part-of-speech tags onto the app's set. |
| [`buildEntries`](#buildentries) | top-level function | A | Build the catalog entries from every input. |
| `_entry` | top-level function | B | Assemble one catalog entry with its keys in a fixed order. |

### `chooseForms` <a id="chooseforms"></a>

- **Purpose:** Decide how a word should be written and read.
- **Inputs:** `word` — the JMdict entry; `row` — the list row naming it.
- **Returns:** The chosen headword, reading, whether the form is common, and a warning when the
  list's own forms do not line up with the dictionary.
- **Side effects:** None.
- **Algorithm:** The list's forms win, because the lists are what learners are tested on — with two
  exceptions. A word with no kanji, or whose first sense is tagged "usually kana", is headed by its
  reading, because writing 有る for ある would teach the wrong thing. And a listed form JMdict marks
  as uncommon loses to a common one: the N5 list gives 明い for あかるい, a search-only form of the
  common 明るい.
- **Usage:** Called once per list row by [`buildEntries`](#buildentries).
- **Notes:** Every departure from the list produces a warning line, so a JMdict update that changes
  which form is common is visible in the run output rather than silent.

### `glossesOf` <a id="glossesof"></a>

- **Purpose:** Collect the English glosses worth showing for a word.
- **Inputs:** `word`, `headword`, `reading`.
- **Returns:** Up to three gloss strings, one per sense, each joining that sense's first three
  glosses with `; `.
- **Side effects:** None.
- **Algorithm:** Skip senses tagged archaic, obsolete, obscure, rare or offensive, and senses
  restricted to a written form or reading other than the chosen ones, so a word imported under one
  form does not display another form's meaning. If that leaves nothing — a handful of entries are
  made up entirely of such senses — fall back to the unfiltered read.
- **Usage:** Called once per entry by [`buildEntries`](#buildentries).
- **Notes:** Shipping a word with no meaning at all is worse than showing its one rare sense, which
  is what the fallback is for; a test pins it.

### `buildEntries` <a id="buildentries"></a>

- **Purpose:** Build the catalog entries from every input.
- **Inputs:** `jmdictIndex`, `listsByLevel`, `seedEntries`, `overlay`.
- **Returns:** `ImportResult` — the entries, a log, and the sequence numbers JMdict does not carry.
- **Side effects:** None.
- **Algorithm:** Walk the levels easiest first, so a word on two lists is taught at the easier one
  and its id is fixed there. Skip a sequence number already taken; drop a second row producing the
  same written form and reading inside one level, with a log line. Then emit any seed word no list
  named, keeping its own level. Sort by level, then reading, then id.
- **Usage:** The one call the command makes.
- **Notes:** Sorting rather than relying on input or map order is what makes the output byte-stable
  across runs. A seed entry's hand-written glosses and examples win over JMdict's, because they
  were written for a learner rather than for a dictionary, and its old id becomes an alias so no
  user's progress is orphaned.

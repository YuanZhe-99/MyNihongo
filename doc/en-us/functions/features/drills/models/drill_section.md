# lib/features/drills/models/drill_section.dart

Names the four sections of a JLPT paper and the question types each one is built from. Two enums
and their parsers, and nothing else.

**These names are a compatibility contract.** A section name is written into every exam record's
payload and a type key is written into every drill file, so renaming one silently orphans the
records and the content that already use it. The *counts* per type are deliberately not here — they
are in `structure.json`, because JEES says they vary from session to session, and a number that
varies is content rather than code.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Name the four sections of a JLPT paper and the question types each is built from. |
| [`DrillSection`](#section) | enum | A | The four sections: 文字・語彙, 文法, 読解, 聴解. |
| `DrillSection.parse` | static method | B | Parse a section from content JSON or a saved record; null for anything unrecognized. |
| [`DrillType`](#type) | enum | A | One 大問 — a numbered question type on the paper. |
| `DrillType` constructor | constructor | B | Bind a type to its content key and its section. |
| `key`, `section` | fields | B | What a drill file writes in `type`, and which section the type is scored under. |
| `DrillType.parse` | static method | B | Parse a type from a drill file; null for anything unrecognized. |

## Documentation

### `enum DrillSection` <a id="section"></a>

- **Kind:** enum
- **Purpose:** Name one section of the paper.
- **Inputs:** None; content files name these and nothing else constructs them.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None.
- **Usage:** `DrillFile`, `DrillRepository.assetFor`, `DrillSampler`, the Learn card, and every exam
  record's payload.
- **Notes:** The JLPT calls these 文字・語彙, 文法, 読解 and 聴解. They are separate here even where a
  level examines two of them in one timed block, because a scoring group is made of sections and a
  weakness report is read per section. `parse` is case-folded, so a file written `Vocab` still loads,
  and returns null rather than a default: a question in no section cannot be scored, and silently
  filing it under vocabulary would put it in the wrong group.

### `enum DrillType` <a id="type"></a>

- **Kind:** enum
- **Purpose:** Name one 大問 and bind it to the section it is scored under.
- **Inputs:** `key` as content writes it; `section` it is scored under.
- **Returns:** None.
- **Side effects:** None.
- **Algorithm:** None.
- **Usage:** `DrillQuestion.type`, `DrillTypeRendering`, `LevelStructure.types`, `DrillSampler.draw`.
- **Notes:** The key is what a drill file writes; the section is what the type is scored under. Two
  levels can share a type and give it different counts, which is why the count lives in
  `structure.json` and only the *shape* is here. The key is kebab-case rather than the Dart name
  because content files are hand-written and hyphens read better there than camel case. `parse`
  returns null rather than a default — the content gate rejects an unknown type before it ships, and
  this is the second line of defence: dropping the question is better than scoring it under a section
  it does not belong to.

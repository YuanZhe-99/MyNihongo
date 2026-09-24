# tool/draft_inputs.dart

Writes the input batches a content-authoring agent works from.

An authoring agent is handed one small JSON file and writes one small JSON file back. It never reads
the 1.5 MB catalog, never runs a build, and never has to be told which words are already done — **the
batch is the list of what is missing**, so two agents working at once cannot collide and a re-run
after a merge simply produces fewer batches.

```
dart run tool/draft_inputs.dart gloss --level N4 --batch 300
dart run tool/draft_inputs.dart examples --level N5 --batch 150
dart run tool/draft_inputs.dart grammar-inventory --level N4
dart run tool/draft_inputs.dart units --level N5
dart run tool/draft_inputs.dart drills --level N5 --section reading
dart run tool/draft_inputs.dart gloss-ja --level N5 --batch 100
dart run tool/draft_inputs.dart ja --kind grammar --level N5 --batch 25
```

Two kinds serve the Japanese content streams. `gloss-ja` lists the words at a level with no Japanese
definition (`meanings.ja`), the twin of `gloss`. `ja` adds a Japanese version of text the catalog
already has in English and Chinese — grammar points, function-word glosses, lesson units or drill
questions, chosen with `--kind` (`grammar`, `function-words`, `units`, `drills`) — and writes its
batches under `<out>/ja/<kind>/`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Write the input batches an authoring agent works from. |
| `draftRoot` | constant | B | Where the batches are written; git-ignored, and emptied before a commit. |
| `main` | function | B | Parse the flags (including `--kind`, the `ja` target), load the catalog, and dispatch on the kind. |
| `_glossRows` | function | B | List the words at a level that have no Chinese gloss yet. |
| `_exampleRows` | function | B | List the words at a level that have no example sentence yet. |
| `_write` | function | B | Split rows into batches and write one input file each. |
| `_inventory` | function | B | Write the grammar inventory for a level. |
| `_units` | function | B | Write the whole level's syllabus, because a level is planned whole. |
| `drillTypeSections` | constant | B | Which section each 大問 belongs to, for the drill batches. |
| `drillPassageShapes` | constant | B | How long a passage each reading and listening 大問 wants. |
| [`_drills`](#drills) | function | A | Write one drill batch and the resources that go with it. |
| `_glossJaRows` | function | B | List the words at a level that have no Japanese definition (`meanings.ja`) yet, with their English and Chinese glosses to pin down the sense. |
| `_enZh` | function | B | Keep only the `en` and `zh` of a localized field, since the `zh_TW` copy would only cost tokens. |
| `_needsJa` | function | B | Say whether a localized field exists and still has no `ja`. |
| [`_ja`](#ja) | function | A | Write the input batches for one `ja` target. |

## Documentation

### `void _drills(String out, String level, String section, String assets, List<Map<String, Object?>> entries, int target, int batch)` <a id="drills"></a>

- **Kind:** function
- **Purpose:** Write one drill batch and the resources that go with it.
- **Inputs:** The output root, the `level` and `section`, the assets path, the catalog `entries`, the
  `target` multiple of the official counts, and the batch size.
- **Returns:** None.
- **Side effects:** Writes an `.input.json` and a `.resources.json` under `draftRoot`.
- **Algorithm:** Read `structure.json` for this level's per-大問 counts, subtract what the shipped
  file already has, and write the per-type deficit. Separately write the resources: the level's
  vocabulary and grammar, the ids already taken, and the passage shapes for the 大問 in this section.
- **Usage:** By hand, before dispatching an authoring agent at a batch.
- **Notes:** **"Missing" is computed, not declared.** The deficit is `structure.json`'s count times
  the target minus what has already shipped, so a batch re-run after a merge asks for exactly what is
  still short, and asking for a level that is complete produces nothing rather than duplicates.

  The resources go in a **separate file** from the input. The input is what the agent is asked to
  produce; the resources are what it may use. Keeping them apart is what lets the input stay small
  enough to read at a glance while the vocabulary list behind it runs to hundreds of entries.

  The ids already taken are handed over so a new batch numbers on from where the last one stopped.
  `merge_drafts.dart` treats a duplicate id as fatal, so this is the cheap half of that rule and the
  merge is the enforcement.

### `void _ja(String out, String target, String level, String assets, int batch)` <a id="ja"></a>

- **Kind:** function
- **Purpose:** Write the input batches for one `ja` target.
- **Inputs:** The output root, the `target` (`grammar`, `function-words`, `units`, `drills`), the
  `level`, the assets path, and the batch size.
- **Returns:** None.
- **Side effects:** Writes `<level>-NN.input.json` files under `<out>/ja/<target>/` and prints them;
  sets exit code 1 for an unknown target.
- **Algorithm:** Collect one row per record with a field still needing `ja` (`_needsJa`):
  - `grammar` — each point of `grammar/<level>.json` whose `meaning` or `explanation` lacks `ja`, with
    its pattern, structure, the `en`/`zh` of both fields, and up to two example sentences;
  - `function-words` — each word in `function_words.json` whose `gloss` lacks `ja` (the file is not
    per level);
  - `units` — each unit of `lessons/<level>.json` whose title, writing prompt, scenario title or any
    question's prompt or explanation lacks `ja`, with only those questions listed;
  - `drills` — each question in the level's drill files whose prompt or explanation lacks `ja`, with
    the joined text of its passage when it has one.

  Then slice the rows into batches, each wrapped in `{kind: 'ja', target, level, count, rows}`, or
  print that nothing is left.
- **Usage:** By hand, before dispatching the Japanese authoring agent at a target.
- **Notes:** Internal helper used within this file only. The `ja` stream adds a Japanese version of
  text the catalog already has in English and Chinese, so every row carries that text (through
  `_enZh`) and nothing else. "Missing" is the same rule everywhere: a field that has no `ja` yet, so a
  re-run after a merge asks only for what is still missing. The envelope names the target because
  the gate and `merge_drafts.dart`'s `_mergeJa` both need to know which file the rows belong to.

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
```

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| library header | library doc | B | Write the input batches an authoring agent works from. |
| `draftRoot` | constant | B | Where the batches are written; git-ignored, and emptied before a commit. |
| `main` | function | B | Parse the flags, load the catalog, and dispatch on the kind. |
| `_glossRows` | function | B | List the words at a level that have no Chinese gloss yet. |
| `_exampleRows` | function | B | List the words at a level that have no example sentence yet. |
| `_write` | function | B | Split rows into batches and write one input file each. |
| `_inventory` | function | B | Write the grammar inventory for a level. |
| `_units` | function | B | Write the whole level's syllabus, because a level is planned whole. |
| `drillTypeSections` | constant | B | Which section each 大問 belongs to, for the drill batches. |
| `drillPassageShapes` | constant | B | How long a passage each reading and listening 大問 wants. |
| [`_drills`](#drills) | function | A | Write one drill batch and the resources that go with it. |

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

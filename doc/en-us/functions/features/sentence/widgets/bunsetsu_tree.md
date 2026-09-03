# lib/features/sentence/widgets/bunsetsu_tree.dart

The sentence's structure as an indented list: the "Structure" section of the sentence lab.

Consumers: `sentence_lab_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `BunsetsuTree` | class | B | The chunks, each naming what it attaches to. |
| [`build`](#build) | method | A | Build the structure list. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Show what modifies what.
- **Inputs:** The build context; the widget's analysis.
- **Returns:** `Widget`.
- **Side effects:** None.
- **Algorithm:** One row per chunk, in sentence order, each naming its target; the root row says so
  instead.
- **Usage:** The lab page.
- **Notes:** An indented list rather than lines and boxes, because it stays readable at any width
  and in either language, and it degrades to a flat list when the guess is poor rather than to a
  tangle. Sentence order rather than tree order: the learner is reading a sentence they just wrote,
  and reordering it would make rows harder to find than the relationship is worth.

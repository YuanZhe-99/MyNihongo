# lib/features/sentence/widgets/grammar_used_list.dart

The taught grammar points a sentence uses: the "Grammar used" section of the sentence lab.

Consumers: `sentence_lab_page.dart`.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GrammarUsedList` | class | B | The matched grammar points, each opening its detail sheet. |
| [`build`](#build) | method | A | Build the list of matched grammar points. |

## Documentation

### `Widget build(BuildContext context)` <a id="build"></a>

- **Kind:** method
- **Purpose:** Link what the sentence used back to what the app teaches.
- **Inputs:** The build context; the widget's analysis and catalog.
- **Returns:** `Widget`.
- **Side effects:** None until a row is tapped.
- **Algorithm:** Resolve each match's id to a point, drop the ones the catalog cannot open, and show
  the pattern, its meaning and the span that matched.
- **Usage:** The lab page.
- **Notes:** Rows open the same detail sheet the Grammar page opens, so a pattern noticed here is
  explained in the same words as everywhere else in the app. An empty list says so rather than
  rendering nothing: a learner who used no taught pattern should get that answer, not an absence
  they have to interpret.
